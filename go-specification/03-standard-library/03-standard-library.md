# Go 标准库

> **🎯 核心概念**：Go 标准库是 Go 语言强大之处的重要体现。理解标准库的设计哲学和最佳实践，能让你写出更简洁、高效的代码。

## 1. IO 操作

### 1.1 io 包核心接口

> **🎯 核心概念**：io 包定义了 Go 中所有 I/O 操作的基础接口。理解这些接口是掌握 Go I/O 编程的关键。

```go
package main

import (
    "bytes"
    "fmt"
    "io"
    "strings"
)

func main() {
    // io.Reader 接口
    // type Reader interface {
    //     Read(p []byte) (n int, err error)
    // }
    
    // io.Writer 接口
    // type Writer interface {
    //     Write(p []byte) (n int, err error)
    // }
    
    // 从 Reader 读取
    reader := strings.NewReader("Hello, World!")
    buf := make([]byte, 5)
    for {
        n, err := reader.Read(buf)
        if err == io.EOF {
            break
        }
        fmt.Printf("Read %d bytes: %s\n", n, buf[:n])
    }
    
    // io.Copy: 从 Reader 复制到 Writer
    var writer bytes.Buffer
    reader = strings.NewReader("Copy this")
    io.Copy(&writer, reader)
    fmt.Println("Copied:", writer.String())
    
    // io.TeeReader: 同时读取和写入
    var buf2 bytes.Buffer
    reader = strings.NewReader("TeeReader example")
    teeReader := io.TeeReader(reader, &buf2)
    
    data, _ := io.ReadAll(teeReader)
    fmt.Println("Read:", string(data))
    fmt.Println("Tee:", buf2.String())
    
    // io.Pipe: 内存管道
    r, w := io.Pipe()
    go func() {
        w.Write([]byte("Pipe data"))
        w.Close()
    }()
    
    pipeData, _ := io.ReadAll(r)
    fmt.Println("Pipe:", string(pipeData))
    
    // io.MultiReader / MultiWriter
    multiReader := io.MultiReader(
        strings.NewReader("First "),
        strings.NewReader("Second "),
        strings.NewReader("Third"),
    )
    multiData, _ := io.ReadAll(multiReader)
    fmt.Println("Multi:", string(multiData))
}
```

#### 🔬 深度解析：io 接口的设计哲学

Go 的 io 设计遵循"小接口"原则——每个接口只包含一个方法，这使得组合变得非常灵活。

```
┌─────────────────────────────────────────────────────────────────┐
│  io 包核心接口层次                                                │
└─────────────────────────────────────────────────────────────────┘

基础接口（单一方法）:
├── Reader      { Read(p []byte) (n int, err error) }
├── Writer      { Write(p []byte) (n int, err error) }
├── Closer      { Close() error }
├── Seeker      { Seek(offset int64, whence int) (int64, error) }
└── ReaderAt    { ReadAt(p []byte, off int64) (n int, err error) }

组合接口:
├── ReadWriter      { Reader; Writer }
├── ReadCloser      { Reader; Closer }
├── WriteCloser     { Writer; Closer }
├── ReadWriteCloser { Reader; Writer; Closer }
└── ReadSeeker      { Reader; Seeker }
```

**为什么这样设计？**

| 设计选择 | 优点 | 缺点 |
|---------|------|------|
| 小接口 | 易实现、易组合、易测试 | 需要类型断言获取更多功能 |
| 大接口 | 功能完整 | 实现负担重、灵活性差 |

##### 实现自定义 Reader

```go
package main

import (
    "fmt"
    "io"
)

// 自定义 Reader：限制读取次数
type LimitedReader struct {
    R        io.Reader
    N        int64
    bytesRead int64
}

func (l *LimitedReader) Read(p []byte) (n int, err error) {
    if l.bytesRead >= l.N {
        return 0, io.EOF
    }
    
    remaining := l.N - l.bytesRead
    if int64(len(p)) > remaining {
        p = p[:remaining]
    }
    
    n, err = l.R.Read(p)
    l.bytesRead += int64(n)
    return
}

// 自定义 Reader：进度追踪
type ProgressReader struct {
    R         io.Reader
    Total     int64
    Read      int64
    OnProgress func(read, total int64)
}

func (pr *ProgressReader) Read(p []byte) (n int, err error) {
    n, err = pr.R.Read(p)
    pr.Read += int64(n)
    if pr.OnProgress != nil {
        pr.OnProgress(pr.Read, pr.Total)
    }
    return
}

func main() {
    // 使用自定义 Reader
    src := strings.NewReader("Hello, World! This is a test.")
    limited := &LimitedReader{R: src, N: 5}
    
    data, _ := io.ReadAll(limited)
    fmt.Println("Limited read:", string(data))
    
    // 进度追踪示例
    src = strings.NewReader(strings.Repeat("x", 1000))
    progress := &ProgressReader{
        R:     src,
        Total: 1000,
        OnProgress: func(read, total int64) {
            fmt.Printf("\rProgress: %d/%d bytes (%.1f%%)", read, total, float64(read)/float64(total)*100)
        },
    }
    
    io.ReadAll(progress)
    fmt.Println("\nDone!")
}
```

> **💡 新手提示**：
> - 总是检查 `Read` 返回的 `err`，特别是 `io.EOF`
> - 使用 `io.ReadAll` 读取全部内容，避免手动循环
> - `io.Copy` 比 `ReadAll` + `Write` 更高效，因为它使用固定大小的缓冲区

> **🎓 专家视角**：io 接口的性能考量：
> 1. **缓冲区大小**：`io.Copy` 默认使用 32KB 缓冲区，对于大文件复制效率高
> 2. **避免频繁分配**：重用缓冲区而不是每次 `make`
> 3. **使用 `io.CopyBuffer`**：当你需要控制缓冲区大小时
> 4. **考虑 `io.Pipe`**：当需要连接不兼容的 Reader/Writer 时
```

### 1.2 文件操作

```go
package main

import (
    "bufio"
    "fmt"
    "io"
    "os"
    "path/filepath"
)

func main() {
    // 创建文件
    file, err := os.Create("example.txt")
    if err != nil {
        panic(err)
    }
    defer file.Close()
    
    // 写入文件
    file.WriteString("Hello, World!\n")
    file.Write([]byte("Binary data\n"))
    
    // 打开文件
    file, err = os.Open("example.txt")
    if err != nil {
        panic(err)
    }
    defer file.Close()
    
    // 读取文件
    data := make([]byte, 100)
    n, err := file.Read(data)
    if err != nil && err != io.EOF {
        panic(err)
    }
    fmt.Printf("Read %d bytes: %s", n, data[:n])
    
    // 使用 bufio
    file, _ = os.Open("example.txt")
    scanner := bufio.NewScanner(file)
    for scanner.Scan() {
        fmt.Println("Line:", scanner.Text())
    }
    
    // 读取整个文件
    content, _ := os.ReadFile("example.txt")
    fmt.Println("Content:", string(content))
    
    // 写入整个文件
    os.WriteFile("output.txt", []byte("New content"), 0644)
    
    // 文件信息
    info, _ := os.Stat("example.txt")
    fmt.Printf("Name: %s, Size: %d, Mode: %v\n", info.Name(), info.Size(), info.Mode())
    
    // 目录操作
    os.Mkdir("testdir", 0755)
    os.MkdirAll("testdir/subdir/nested", 0755)
    
    // 遍历目录
    filepath.Walk(".", func(path string, info os.FileInfo, err error) error {
        if err != nil {
            return err
        }
        fmt.Println(path)
        return nil
    })
    
    // 清理
    os.Remove("example.txt")
    os.Remove("output.txt")
    os.RemoveAll("testdir")
}
```

---

## 2. 网络编程

> **🎯 核心概念**：Go 的 net/http 包提供了完整的 HTTP 客户端和服务器实现，是构建 Web 服务的基础。

### 2.1 HTTP 服务端

```go
package main

import (
    "encoding/json"
    "fmt"
    "log"
    "net/http"
)

type User struct {
    ID   int    `json:"id"`
    Name string `json:"name"`
}

func main() {
    // 基本路由
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "Hello, World!")
    })
    
    // 获取请求信息
    http.HandleFunc("/info", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "Method: %s\n", r.Method)
        fmt.Fprintf(w, "URL: %s\n", r.URL.String())
        fmt.Fprintf(w, "Header: %v\n", r.Header)
        fmt.Fprintf(w, "RemoteAddr: %s\n", r.RemoteAddr)
    })
    
    // 查询参数
    http.HandleFunc("/query", func(w http.ResponseWriter, r *http.Request) {
        query := r.URL.Query()
        name := query.Get("name")
        age := query.Get("age")
        fmt.Fprintf(w, "Name: %s, Age: %s", name, age)
    })
    
    // JSON 响应
    http.HandleFunc("/json", func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Content-Type", "application/json")
        user := User{ID: 1, Name: "Alice"}
        json.NewEncoder(w).Encode(user)
    })
    
    // JSON 请求
    http.HandleFunc("/create", func(w http.ResponseWriter, r *http.Request) {
        if r.Method != http.MethodPost {
            http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
            return
        }
        
        var user User
        if err := json.NewDecoder(r.Body).Decode(&user); err != nil {
            http.Error(w, err.Error(), http.StatusBadRequest)
            return
        }
        
        w.Header().Set("Content-Type", "application/json")
        json.NewEncoder(w).Encode(user)
    })
    
    // 静态文件
    http.Handle("/static/", http.StripPrefix("/static/", http.FileServer(http.Dir("./static"))))
    
    // 中间件
    loggingMiddleware := func(next http.HandlerFunc) http.HandlerFunc {
        return func(w http.ResponseWriter, r *http.Request) {
            log.Printf("%s %s", r.Method, r.URL.Path)
            next(w, r)
        }
    }
    
    http.HandleFunc("/middleware", loggingMiddleware(func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "With middleware")
    }))
    
    fmt.Println("Server starting on :8080")
    log.Fatal(http.ListenAndServe(":8080", nil))
}
```

#### 🔬 深度解析：HTTP 服务端架构

```
┌─────────────────────────────────────────────────────────────────┐
│  HTTP 服务端处理流程                                              │
└─────────────────────────────────────────────────────────────────┘

请求 → Listener → ServeMux → Handler → ResponseWriter
         ↓           ↓          ↓
      接收连接    路由匹配   处理请求

关键组件:
├── http.Server: 服务器配置（超时、TLS等）
├── http.ServeMux: 路由器（默认使用 DefaultServeMux）
├── http.Handler: 处理器接口
└── http.ResponseWriter: 响应写入器
```

##### 生产级 HTTP 服务器配置

```go
package main

import (
    "context"
    "log"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"
)

func main() {
    // 创建自定义 Server
    server := &http.Server{
        Addr:         ":8080",
        Handler:      nil, // 使用 DefaultServeMux
        ReadTimeout:  10 * time.Second,
        WriteTimeout: 10 * time.Second,
        IdleTimeout:  120 * time.Second,
    }
    
    // 注册路由
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        w.Write([]byte("Hello, World!"))
    })
    
    // 启动服务器（非阻塞）
    go func() {
        log.Println("Server starting on :8080")
        if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            log.Fatalf("Server error: %v", err)
        }
    }()
    
    // 优雅关闭
    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit
    
    log.Println("Shutting down server...")
    
    ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
    defer cancel()
    
    if err := server.Shutdown(ctx); err != nil {
        log.Fatalf("Server shutdown error: %v", err)
    }
    
    log.Println("Server stopped")
}
```

##### 中间件链模式

```go
package main

import (
    "fmt"
    "log"
    "net/http"
    "time"
)

// 中间件类型
type Middleware func(http.Handler) http.Handler

// 链式中间件
func Chain(h http.Handler, middlewares ...Middleware) http.Handler {
    for i := len(middlewares) - 1; i >= 0; i-- {
        h = middlewares[i](h)
    }
    return h
}

// 日志中间件
func Logging() Middleware {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            start := time.Now()
            
            // 包装 ResponseWriter 以捕获状态码
            wrapped := &responseWriter{ResponseWriter: w, statusCode: http.StatusOK}
            next.ServeHTTP(wrapped, r)
            
            log.Printf("%s %s %d %v", r.Method, r.URL.Path, wrapped.statusCode, time.Since(start))
        })
    }
}

// 恢复中间件
func Recovery() Middleware {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            defer func() {
                if err := recover(); err != nil {
                    log.Printf("Panic recovered: %v", err)
                    http.Error(w, "Internal Server Error", http.StatusInternalServerError)
                }
            }()
            next.ServeHTTP(w, r)
        })
    }
}

// CORS 中间件
func CORS() Middleware {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            w.Header().Set("Access-Control-Allow-Origin", "*")
            w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
            w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
            
            if r.Method == http.MethodOptions {
                w.WriteHeader(http.StatusOK)
                return
            }
            
            next.ServeHTTP(w, r)
        })
    }
}

// 认证中间件
func Auth(token string) Middleware {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            authHeader := r.Header.Get("Authorization")
            if authHeader != "Bearer "+token {
                http.Error(w, "Unauthorized", http.StatusUnauthorized)
                return
            }
            next.ServeHTTP(w, r)
        })
    }
}

type responseWriter struct {
    http.ResponseWriter
    statusCode int
}

func (rw *responseWriter) WriteHeader(code int) {
    rw.statusCode = code
    rw.ResponseWriter.WriteHeader(code)
}

func main() {
    handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "Hello with middleware!")
    })
    
    // 应用中间件链
    http.Handle("/", Chain(handler,
        Recovery(),
        Logging(),
        CORS(),
        Auth("secret-token"),
    ))
    
    log.Println("Server starting on :8080")
    log.Fatal(http.ListenAndServe(":8080", nil))
}
```

> **💡 新手提示**：
> - 总是设置 `ReadTimeout` 和 `WriteTimeout`，防止慢客户端攻击
> - 使用 `http.Error` 返回错误响应
> - 在生产环境中实现优雅关闭

> **🎓 专家视角**：HTTP 服务器性能优化：
> 1. **连接池**：`http.Server` 自动管理连接池
> 2. **超时设置**：`ReadTimeout`、`WriteTimeout`、`IdleTimeout` 都很重要
> 3. **Keep-Alive**：默认启用，`IdleTimeout` 控制空闲连接时间
> 4. **压缩**：使用 `gzip` 中间件减少传输大小
> 5. **限流**：使用 `golang.org/x/time/rate` 实现令牌桶限流
```

### 2.2 HTTP 客户端

```go
package main

import (
    "bytes"
    "encoding/json"
    "fmt"
    "io"
    "net/http"
    "time"
)

func main() {
    client := &http.Client{
        Timeout: 10 * time.Second,
    }
    
    // GET 请求
    resp, err := client.Get("https://httpbin.org/get")
    if err != nil {
        panic(err)
    }
    defer resp.Body.Close()
    
    body, _ := io.ReadAll(resp.Body)
    fmt.Println("GET Response:", string(body))
    
    // POST 请求
    data := map[string]string{"key": "value"}
    jsonData, _ := json.Marshal(data)
    
    resp, err = client.Post(
        "https://httpbin.org/post",
        "application/json",
        bytes.NewBuffer(jsonData),
    )
    if err != nil {
        panic(err)
    }
    defer resp.Body.Close()
    
    body, _ = io.ReadAll(resp.Body)
    fmt.Println("POST Response:", string(body))
    
    // 自定义请求
    req, _ := http.NewRequest("GET", "https://httpbin.org/headers", nil)
    req.Header.Set("X-Custom-Header", "value")
    req.Header.Set("Authorization", "Bearer token")
    
    resp, err = client.Do(req)
    if err != nil {
        panic(err)
    }
    defer resp.Body.Close()
    
    body, _ = io.ReadAll(resp.Body)
    fmt.Println("Custom Request Response:", string(body))
    
    // 处理 Cookie
    req, _ = http.NewRequest("GET", "https://httpbin.org/cookies", nil)
    req.AddCookie(&http.Cookie{Name: "session", Value: "abc123"})
    
    resp, _ = client.Do(req)
    defer resp.Body.Close()
    
    // 传输控制
    transport := &http.Transport{
        MaxIdleConns:        100,
        MaxIdleConnsPerHost: 10,
        IdleConnTimeout:     30 * time.Second,
    }
    
    client2 := &http.Client{
        Transport: transport,
        Timeout:   10 * time.Second,
    }
    _ = client2
}
```

---

## 3. JSON 处理

> **🎯 核心概念**：Go 的 encoding/json 包提供了完整的 JSON 编解码功能。理解其内部机制和最佳实践，能让你高效处理 JSON 数据。

### 3.1 编码与解码

```go
package main

import (
    "encoding/json"
    "fmt"
)

type Person struct {
    Name    string   `json:"name"`
    Age     int      `json:"age"`
    Email   string   `json:"email,omitempty"`
    Roles   []string `json:"roles"`
    Address *Address `json:"address,omitempty"`
}

type Address struct {
    City    string `json:"city"`
    Country string `json:"country"`
}

func main() {
    // 结构体转 JSON
    p := Person{
        Name:  "Alice",
        Age:   30,
        Roles: []string{"admin", "user"},
        Address: &Address{
            City:    "Beijing",
            Country: "China",
        },
    }
    
    // Marshal: 结构体 -> JSON 字节
    jsonData, err := json.Marshal(p)
    if err != nil {
        panic(err)
    }
    fmt.Println("JSON:", string(jsonData))
    
    // MarshalIndent: 带缩进
    prettyJSON, _ := json.MarshalIndent(p, "", "  ")
    fmt.Println("Pretty JSON:\n", string(prettyJSON))
    
    // JSON 转结构体
    jsonStr := `{"name":"Bob","age":25,"roles":["user"]}`
    var p2 Person
    if err := json.Unmarshal([]byte(jsonStr), &p2); err != nil {
        panic(err)
    }
    fmt.Printf("Person: %+v\n", p2)
    
    // 处理未知结构
    var result map[string]interface{}
    json.Unmarshal([]byte(jsonStr), &result)
    fmt.Println("Map:", result)
    
    // 流式编码
    // encoder := json.NewEncoder(writer)
    // encoder.Encode(p)
    
    // 流式解码
    // decoder := json.NewDecoder(reader)
    // decoder.Decode(&p)
}
```

#### 🔬 深度解析：JSON 标签与反射

```
┌─────────────────────────────────────────────────────────────────┐
│  JSON 标签详解                                                    │
└─────────────────────────────────────────────────────────────────┘

常用标签:
├── `json:"name"`         字段名映射
├── `json:"name,omitempty"` 零值时省略
├── `json:"-"`            忽略字段
├── `json:",omitempty"`   使用原字段名，零值省略
└── `json:",string"`      数字转字符串

特殊处理:
├── 私有字段（小写开头）不参与序列化
├── 指针字段 nil 时 omitempty 生效
└── 切片/Map 零值为 nil，omitempty 生效
```

##### JSON 标签最佳实践

```go
package main

import (
    "encoding/json"
    "fmt"
)

type APIResponse struct {
    Status  string      `json:"status"`
    Data    interface{} `json:"data,omitempty"`
    Error   string      `json:"error,omitempty"`
    Code    int         `json:"code"`
    Debug   string      `json:"-"`              // 不序列化
    Version string      `json:",omitempty"`     // 使用原字段名
    Count   int         `json:"count,string"`   // 数字转字符串
}

type User struct {
    ID       int      `json:"id"`
    Username string   `json:"username"`
    Email    string   `json:"email,omitempty"`
    Password string   `json:"-"`              // 安全：不暴露密码
    Roles    []string `json:"roles,omitempty"`
}

func main() {
    // omitempty 示例
    resp1 := APIResponse{
        Status: "success",
        Code:   200,
    }
    data1, _ := json.MarshalIndent(resp1, "", "  ")
    fmt.Println("Success response:\n", string(data1))
    
    resp2 := APIResponse{
        Status: "error",
        Error:  "Not found",
        Code:   404,
        Debug:  "This is debug info",  // 不会出现在 JSON 中
    }
    data2, _ := json.MarshalIndent(resp2, "", "  ")
    fmt.Println("Error response:\n", string(data2))
    
    // string 标签示例
    resp3 := APIResponse{
        Status: "success",
        Code:   200,
        Count:  42,  // 会变成 "42"
    }
    data3, _ := json.MarshalIndent(resp3, "", "  ")
    fmt.Println("String tag:\n", string(data3))
    
    // 安全处理：密码不暴露
    user := User{
        ID:       1,
        Username: "alice",
        Password: "secret123",  // 不会出现在 JSON 中
    }
    userData, _ := json.MarshalIndent(user, "", "  ")
    fmt.Println("User:\n", string(userData))
}
```

##### 处理动态 JSON

```go
package main

import (
    "encoding/json"
    "fmt"
)

// 方法1：使用 interface{}
func parseDynamicJSON(data []byte) {
    var result map[string]interface{}
    json.Unmarshal(data, &result)
    
    for key, value := range result {
        switch v := value.(type) {
        case string:
            fmt.Printf("%s: string = %s\n", key, v)
        case float64:
            fmt.Printf("%s: number = %f\n", key, v)
        case bool:
            fmt.Printf("%s: bool = %v\n", key, v)
        case []interface{}:
            fmt.Printf("%s: array = %v\n", key, v)
        case map[string]interface{}:
            fmt.Printf("%s: object = %v\n", key, v)
        case nil:
            fmt.Printf("%s: null\n", key)
        }
    }
}

// 方法2：使用 json.RawMessage 延迟解析
type Event struct {
    Type    string          `json:"type"`
    Payload json.RawMessage `json:"payload"`
}

type UserCreatedEvent struct {
    UserID   string `json:"user_id"`
    Username string `json:"username"`
}

type OrderCreatedEvent struct {
    OrderID string `json:"order_id"`
    Amount  float64 `json:"amount"`
}

func processEvent(data []byte) {
    var event Event
    if err := json.Unmarshal(data, &event); err != nil {
        panic(err)
    }
    
    switch event.Type {
    case "user_created":
        var userEvent UserCreatedEvent
        json.Unmarshal(event.Payload, &userEvent)
        fmt.Printf("User created: %+v\n", userEvent)
    case "order_created":
        var orderEvent OrderCreatedEvent
        json.Unmarshal(event.Payload, &orderEvent)
        fmt.Printf("Order created: %+v\n", orderEvent)
    }
}

// 方法3：自定义 UnmarshalJSON
type FlexibleString string

func (fs *FlexibleString) UnmarshalJSON(data []byte) error {
    var s string
    if err := json.Unmarshal(data, &s); err == nil {
        *fs = FlexibleString(s)
        return nil
    }
    
    var num float64
    if err := json.Unmarshal(data, &num); err == nil {
        *fs = FlexibleString(fmt.Sprintf("%.0f", num))
        return nil
    }
    
    return fmt.Errorf("cannot unmarshal into FlexibleString")
}

type Config struct {
    Value FlexibleString `json:"value"`
}

func main() {
    // 动态 JSON
    jsonData := `{"name":"Alice","age":30,"active":true,"tags":["a","b"]}`
    parseDynamicJSON([]byte(jsonData))
    
    // 延迟解析
    eventJSON := `{"type":"user_created","payload":{"user_id":"123","username":"alice"}}`
    processEvent([]byte(eventJSON))
    
    // 灵活类型
    configJSON := `{"value":123}`  // 数字会被转为字符串
    var config Config
    json.Unmarshal([]byte(configJSON), &config)
    fmt.Printf("Config value: %s\n", config.Value)
}
```

> **💡 新手提示**：
> - 使用 `omitempty` 减少不必要的字段输出
> - 敏感字段使用 `json:"-"` 标签
> - 使用 `json.RawMessage` 延迟解析，提高性能

> **🎓 专家视角**：JSON 性能优化：
> 1. **避免反射**：实现 `MarshalJSON`/`UnmarshalJSON` 可以避免反射开销
> 2. **使用流式 API**：`json.Encoder`/`Decoder` 比 `Marshal`/`Unmarshal` 内存效率更高
> 3. **预分配缓冲区**：对于大 JSON，使用 `bytes.Buffer` 预分配
> 4. **考虑替代库**：`json-iterator/go` 比 encoding/json 快 2-3 倍
> 5. **避免 interface{}**：类型断言有开销，尽量使用具体类型
```

### 3.2 自定义 JSON 处理

```go
package main

import (
    "encoding/json"
    "fmt"
    "strings"
    "time"
)

// 自定义类型实现 Marshaler/Unmarshaler
type CustomTime struct {
    time.Time
}

func (ct *CustomTime) MarshalJSON() ([]byte, error) {
    return json.Marshal(ct.Time.Format("2006-01-02"))
}

func (ct *CustomTime) UnmarshalJSON(data []byte) error {
    var s string
    if err := json.Unmarshal(data, &s); err != nil {
        return err
    }
    t, err := time.Parse("2006-01-02", s)
    if err != nil {
        return err
    }
    ct.Time = t
    return nil
}

// 自定义字符串类型（大小写不敏感）
type CaseInsensitive string

func (ci *CaseInsensitive) UnmarshalJSON(data []byte) error {
    var s string
    if err := json.Unmarshal(data, &s); err != nil {
        return err
    }
    *ci = CaseInsensitive(strings.ToLower(s))
    return nil
}

type Event struct {
    Name      string         `json:"name"`
    Timestamp CustomTime     `json:"timestamp"`
    Status    CaseInsensitive `json:"status"`
}

func main() {
    // 自定义时间处理
    e := Event{
        Name:      "Meeting",
        Timestamp: CustomTime{Time: time.Now()},
        Status:    CaseInsensitive("ACTIVE"),
    }
    
    jsonData, _ := json.MarshalIndent(e, "", "  ")
    fmt.Println("Event JSON:", string(jsonData))
    
    // 解码
    jsonStr := `{"name":"Conference","timestamp":"2024-01-15","status":"PENDING"}`
    var e2 Event
    json.Unmarshal([]byte(jsonStr), &e2)
    fmt.Printf("Event: %+v, Status: %s\n", e2, e2.Status)
}
```

---

## 4. 时间处理

```go
package main

import (
    "fmt"
    "time"
)

func main() {
    // 当前时间
    now := time.Now()
    fmt.Println("Now:", now)
    
    // 创建时间
    t := time.Date(2024, 1, 15, 10, 30, 0, 0, time.UTC)
    fmt.Println("Created:", t)
    
    // 解析时间
    t2, err := time.Parse("2006-01-02 15:04:05", "2024-01-15 10:30:00")
    if err != nil {
        panic(err)
    }
    fmt.Println("Parsed:", t2)
    
    // 解析带时区
    t3, _ := time.ParseInLocation("2006-01-02 15:04:05", "2024-01-15 10:30:00", time.Local)
    fmt.Println("Local:", t3)
    
    // 格式化时间
    fmt.Println("Format:", now.Format("2006-01-02 15:04:05"))
    fmt.Println("RFC3339:", now.Format(time.RFC3339))
    
    // 时间组件
    fmt.Printf("Year: %d, Month: %d, Day: %d\n", now.Year(), now.Month(), now.Day())
    fmt.Printf("Hour: %d, Minute: %d, Second: %d\n", now.Hour(), now.Minute(), now.Second())
    
    // 时间操作
    tomorrow := now.Add(24 * time.Hour)
    yesterday := now.Add(-24 * time.Hour)
    fmt.Println("Tomorrow:", tomorrow)
    
    // 时间差
    diff := tomorrow.Sub(now)
    fmt.Println("Difference:", diff)
    
    // 比较
    fmt.Println("Before:", now.Before(tomorrow))
    fmt.Println("After:", now.After(yesterday))
    fmt.Println("Equal:", now.Equal(now))
    
    // 时区
    loc, _ := time.LoadLocation("America/New_York")
    nyTime := now.In(loc)
    fmt.Println("New York:", nyTime)
    
    // 定时器
    timer := time.NewTimer(2 * time.Second)
    <-timer.C
    fmt.Println("Timer expired")
    
    // 延迟执行
    time.AfterFunc(1*time.Second, func() {
        fmt.Println("AfterFunc executed")
    })
    
    // Ticker
    ticker := time.NewTicker(500 * time.Millisecond)
    go func() {
        for t := range ticker.C {
            fmt.Println("Tick at", t)
        }
    }()
    
    time.Sleep(2 * time.Second)
    ticker.Stop()
    
    // Duration
    d := 5 * time.Second
    fmt.Println("Duration:", d)
    fmt.Println("Minutes:", d.Minutes())
    fmt.Println("Seconds:", d.Seconds())
}
```

---

## 5. 反射

```go
package main

import (
    "fmt"
    "reflect"
)

type User struct {
    Name string `json:"name" validate:"required"`
    Age  int    `json:"age" validate:"min=0,max=150"`
}

func main() {
    // 基本类型反射
    x := 42
    v := reflect.ValueOf(x)
    t := reflect.TypeOf(x)
    
    fmt.Printf("Value: %v, Type: %v, Kind: %v\n", v, t, t.Kind())
    
    // 修改值（需要指针）
    v = reflect.ValueOf(&x).Elem()
    v.SetInt(100)
    fmt.Println("Modified x:", x)
    
    // 结构体反射
    u := User{Name: "Alice", Age: 30}
    t = reflect.TypeOf(u)
    v = reflect.ValueOf(u)
    
    // 遍历字段
    for i := 0; i < t.NumField(); i++ {
        field := t.Field(i)
        value := v.Field(i)
        
        fmt.Printf("Field: %s, Type: %v, Value: %v\n",
            field.Name, field.Type, value)
        
        // 读取标签
        jsonTag := field.Tag.Get("json")
        validateTag := field.Tag.Get("validate")
        fmt.Printf("  JSON tag: %s, Validate tag: %s\n", jsonTag, validateTag)
    }
    
    // 方法反射
    v = reflect.ValueOf(&u).Elem()
    method := v.MethodByName("String")
    if method.IsValid() {
        result := method.Call(nil)
        fmt.Println("Method result:", result[0])
    }
    
    // 创建新实例
    newU := reflect.New(t).Elem()
    newU.FieldByName("Name").SetString("Bob")
    newU.FieldByName("Age").SetInt(25)
    fmt.Printf("New instance: %+v\n", newU.Interface())
    
    // 判断类型
    fmt.Println("Is struct:", t.Kind() == reflect.Struct)
    fmt.Println("Is slice:", reflect.TypeOf([]int{}).Kind() == reflect.Slice)
    fmt.Println("Is map:", reflect.TypeOf(map[string]int{}).Kind() == reflect.Map)
}

func (u *User) String() string {
    return fmt.Sprintf("User{Name: %s, Age: %d}", u.Name, u.Age)
}
```

---

## 6. 其他常用包

### 6.1 字符串处理

```go
package main

import (
    "fmt"
    "strconv"
    "strings"
    "unicode"
)

func main() {
    // strings 包
    s := "Hello, World!"
    
    fmt.Println("Contains:", strings.Contains(s, "World"))
    fmt.Println("HasPrefix:", strings.HasPrefix(s, "Hello"))
    fmt.Println("HasSuffix:", strings.HasSuffix(s, "!"))
    fmt.Println("Index:", strings.Index(s, "World"))
    fmt.Println("Count:", strings.Count(s, "l"))
    
    // 分割与连接
    parts := strings.Split("a,b,c", ",")
    fmt.Println("Split:", parts)
    
    joined := strings.Join(parts, "-")
    fmt.Println("Join:", joined)
    
    // 替换
    fmt.Println("Replace:", strings.Replace(s, "World", "Go", 1))
    fmt.Println("ReplaceAll:", strings.ReplaceAll("aaa", "a", "b"))
    
    // 大小写
    fmt.Println("Upper:", strings.ToUpper(s))
    fmt.Println("Lower:", strings.ToLower(s))
    fmt.Println("Title:", strings.Title("hello world"))
    
    // 修剪
    fmt.Println("Trim:", strings.Trim("  hello  ", " "))
    fmt.Println("TrimSpace:", strings.TrimSpace("  hello  "))
    fmt.Println("TrimPrefix:", strings.TrimPrefix("hello.txt", "hello"))
    
    // Builder
    var builder strings.Builder
    builder.WriteString("Hello")
    builder.WriteString(", ")
    builder.WriteString("World")
    fmt.Println("Builder:", builder.String())
    
    // strconv 包
    i, _ := strconv.Atoi("42")
    fmt.Println("Atoi:", i)
    
    s2 := strconv.Itoa(42)
    fmt.Println("Itoa:", s2)
    
    f, _ := strconv.ParseFloat("3.14", 64)
    fmt.Println("ParseFloat:", f)
    
    b, _ := strconv.ParseBool("true")
    fmt.Println("ParseBool:", b)
    
    // unicode 包
    fmt.Println("IsLetter:", unicode.IsLetter('A'))
    fmt.Println("IsDigit:", unicode.IsDigit('5'))
    fmt.Println("IsUpper:", unicode.IsUpper('A'))
}
```

### 6.2 排序

```go
package main

import (
    "fmt"
    "sort"
)

type Person struct {
    Name string
    Age  int
}

type ByAge []Person

func (a ByAge) Len() int           { return len(a) }
func (a ByAge) Swap(i, j int)      { a[i], a[j] = a[j], a[i] }
func (a ByAge) Less(i, j int) bool { return a[i].Age < a[j].Age }

func main() {
    // 基本类型排序
    ints := []int{3, 1, 4, 1, 5, 9, 2, 6}
    sort.Ints(ints)
    fmt.Println("Sorted ints:", ints)
    
    floats := []float64{3.14, 2.71, 1.41}
    sort.Float64s(floats)
    fmt.Println("Sorted floats:", floats)
    
    strings_ := []string{"banana", "apple", "cherry"}
    sort.Strings(strings_)
    fmt.Println("Sorted strings:", strings_)
    
    // 自定义排序
    people := []Person{
        {"Alice", 30},
        {"Bob", 25},
        {"Charlie", 35},
    }
    
    sort.Sort(ByAge(people))
    fmt.Println("Sorted by age:", people)
    
    // 使用 sort.Slice
    sort.Slice(people, func(i, j int) bool {
        return people[i].Name < people[j].Name
    })
    fmt.Println("Sorted by name:", people)
    
    // 搜索
    sortedInts := []int{1, 2, 3, 4, 5, 6, 7, 8, 9}
    idx := sort.SearchInts(sortedInts, 5)
    fmt.Println("Index of 5:", idx)
    
    // 检查是否已排序
    fmt.Println("Is sorted:", sort.IntsAreSorted(sortedInts))
}
```

### 6.3 加密与哈希

```go
package main

import (
    "crypto/md5"
    "crypto/sha256"
    "encoding/hex"
    "fmt"
)

func main() {
    // MD5
    data := []byte("Hello, World!")
    hash := md5.Sum(data)
    fmt.Println("MD5:", hex.EncodeToString(hash[:]))
    
    // SHA256
    h := sha256.New()
    h.Write(data)
    sha256Hash := h.Sum(nil)
    fmt.Println("SHA256:", hex.EncodeToString(sha256Hash))
    
    // 文件哈希
    // file, _ := os.Open("file.txt")
    // defer file.Close()
    // h := sha256.New()
    // io.Copy(h, file)
    // fmt.Println(hex.EncodeToString(h.Sum(nil)))
}
```
