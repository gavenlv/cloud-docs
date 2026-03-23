# grep - 搜索
grep pattern file
grep -r pattern dir
grep -i pattern file

# sed - 替换
sed 's/old/new/g' file
sed -i 's/old/new/g' file

# awk - 文本处理
awk '{print $1}' file
awk -F: '{print $1}' /etc/passwd