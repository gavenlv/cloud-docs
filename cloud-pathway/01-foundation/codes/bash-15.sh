定义函数：
function greet() {
    echo "Hello, $1!"
}

greet "World"

带返回值的函数：
add() {
    result=$(($1 + $2))
    echo $result
}

sum=$(add 5 3)
echo "Sum: $sum"