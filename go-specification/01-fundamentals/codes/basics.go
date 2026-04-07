package main

import (
    "fmt"
    "errors"
)

func main() {
    fmt.Println("=== Go 基础语法示例 ===")
    
    // 变量声明
    var name string = "Go"
    age := 15
    fmt.Printf("Name: %s, Age: %d\n", name, age)
    
    // 切片
    slice := []int{1, 2, 3, 4, 5}
    slice = append(slice, 6)
    fmt.Println("Slice:", slice)
    
    // Map
    m := map[string]int{"a": 1, "b": 2}
    m["c"] = 3
    fmt.Println("Map:", m)
    
    // 结构体
    type Person struct {
        Name string
        Age  int
    }
    
    p := Person{Name: "Alice", Age: 30}
    fmt.Printf("Person: %+v\n", p)
    
    // 函数
    result := add(2, 3)
    fmt.Println("Add(2, 3) =", result)
    
    // 错误处理
    if res, err := divide(10, 2); err != nil {
        fmt.Println("Error:", err)
    } else {
        fmt.Println("Divide(10, 2) =", res)
    }
    
    // 接口
    var s Shape = Circle{Radius: 5}
    fmt.Printf("Circle Area: %.2f\n", s.Area())
}

func add(a, b int) int {
    return a + b
}

func divide(a, b float64) (float64, error) {
    if b == 0 {
        return 0, errors.New("division by zero")
    }
    return a / b, nil
}

type Shape interface {
    Area() float64
}

type Circle struct {
    Radius float64
}

func (c Circle) Area() float64 {
    return 3.14159 * c.Radius * c.Radius
}
