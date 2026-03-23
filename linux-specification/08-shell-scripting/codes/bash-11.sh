# 定义
function hello() {
    echo "Hello, $1"
}

hello World

# 返回值
function get_sum() {
    local sum=$(( $1 + $2 ))
    echo $sum
}

result=$(get_sum 3 5)
echo $result