#!/bin/bash

# 设定需要搜索的目录，如果没有提供目录，则默认使用当前目录
directory="${1:-.}"

# 文件大小转换函数
convert_filesize() {
    local size="$1"

    if (( size < 1024 )); then
        echo "${size}B"
    elif (( size < 1048576 )); then
        echo "$((size / 1024))KB"
    elif (( size < 1073741824 )); then
        echo "$((size / 1048576))MB"
    else
        echo "$((size / 1073741824))GB"
    fi
}

# 输出的JSON文件名
output_file="files_info.json"

# 临时文件，用于存储文件信息数组
temp_file=$(mktemp)

# 开始文件信息数组
echo "[" > "$temp_file"

# 首次写入标记，用于在多个条目间添加逗号
first=1

# 使用find命令查找.exe, .zip, 和.dmg文件
find "$directory" \( -name "*.exe" -o -name "*.zip" -o -name "*.dmg" \) -print0 | while IFS= read -r -d $'\0' file; do
    echo "$file"
    if [ -n "$file" ]; then
        # 使用stat命令获取文件的大小和创建时间
        # 注意：MacOS和Linux的stat命令参数有所不同
        # 下面的命令适用于Linux，如果你在MacOS上运行，需要相应调整
        filesize=$(stat -c "%s" "$file") # 文件大小 #macos 中使用 stat -f "%z" "$file"
        # createTime=$(stat -f "%w" "$file") # 创建时间（%w在某些系统中可能不可用，可以改用%y获取最后修改时间）
        # Macos中
        # filesize=$(stat -f "%z" "$file")
        # createTime=$(stat -f "%y" "$file")
        readable_filesize=$(convert_filesize "$filesize")
        
        # 替换文件名中的特殊字符以符合JSON字符串要求
        filename=$(basename "$file" | sed 's|"|\\"|g')

        # 获取文件修改时间(格式为 YYYY-MM-DD HH:MM:SS)
        modtime=$(date -r "$file" +"%Y-%m-%d %H:%M:%S")

        # 获取文件相对路径
        filepath="${file#"$directory/"}"

        # 判断是否为首个条目，如果不是，先输出逗号作为分隔
        if [ $first -eq 0 ]; then
            echo "," >> "$temp_file"
        else
            first=0
        fi

        # 将文件信息添加到 JSON 数组中
        echo "{\"filename\":\"$filename\",\"filesize\": \"$readable_filesize\",\"modtime\":\"$modtime\",\"filepath\":\"$filepath\"}"  >> "$temp_file"
    fi
done

# 完成文件信息数组
echo "]" >> "$temp_file"

# 创建包含"code", "message", 和 "data"的最终JSON并输出到文件
echo "{\"code\": 200, \"message\": \"success\", \"data\": $(cat "$temp_file")}" > "$output_file"

# 清理临时文件
rm "$temp_file"

echo "File info saved to $output_file"