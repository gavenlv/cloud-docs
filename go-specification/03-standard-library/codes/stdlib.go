package main

import (
    "encoding/json"
    "fmt"
    "io"
    "net/http"
    "os"
    "time"
)

func main() {
    fmt.Println("=== Go 标准库示例 ===")
    
    // 文件操作
    fmt.Println("\n--- 文件操作 ---")
    filename := "test.txt"
    
    err := os.WriteFile(filename, []byte("Hello, World!"), 0644)
    if err != nil {
        fmt.Println("Error writing file:", err)
    }
    
    data, err := os.ReadFile(filename)
    if err != nil {
        fmt.Println("Error reading file:", err)
    } else {
        fmt.Println("File content:", string(data))
    }
    
    os.Remove(filename)
    
    // JSON 处理
    fmt.Println("\n--- JSON 处理 ---")
    type Person struct {
        Name string `json:"name"`
        Age  int    `json:"age"`
    }
    
    p := Person{Name: "Alice", Age: 30}
    jsonData, _ := json.Marshal(p)
    fmt.Println("JSON:", string(jsonData))
    
    var p2 Person
    json.Unmarshal(jsonData, &p2)
    fmt.Printf("Parsed: %+v\n", p2)
    
    // 时间处理
    fmt.Println("\n--- 时间处理 ---")
    now := time.Now()
    fmt.Println("Now:", now.Format("2006-01-02 15:04:05"))
    
    future := now.Add(24 * time.Hour)
    fmt.Println("Tomorrow:", future.Format("2006-01-02"))
    
    // HTTP 客户端
    fmt.Println("\n--- HTTP 客户端 ---")
    client := &http.Client{Timeout: 5 * time.Second}
    
    resp, err := client.Get("https://httpbin.org/get")
    if err != nil {
        fmt.Println("HTTP error:", err)
    } else {
        defer resp.Body.Close()
        body, _ := io.ReadAll(resp.Body)
        fmt.Println("Response length:", len(body), "bytes")
    }
    
    // HTTP 服务端示例
    fmt.Println("\n--- HTTP 服务端 ---")
    http.HandleFunc("/hello", func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Content-Type", "application/json")
        json.NewEncoder(w).Encode(map[string]string{
            "message": "Hello, World!",
        })
    })
    
    fmt.Println("Server example configured (not starting)")
    // http.ListenAndServe(":8080", nil)
}
