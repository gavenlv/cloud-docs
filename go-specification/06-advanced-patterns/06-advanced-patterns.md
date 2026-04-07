# Go 高级模式

> **🎯 核心概念**：设计模式是解决常见问题的可复用方案。Go 的特性使得某些模式的实现与其他语言不同，理解这些差异能让你写出更地道的 Go 代码。

## 1. 设计模式实现

> **🎯 核心概念**：Go 不是传统的面向对象语言，但它的接口和组合特性使得设计模式的实现更加简洁。

### 1.1 创建型模式

```go
package patterns

import "sync"

// 单例模式
type Singleton struct {
    data string
}

var (
    instance     *Singleton
    once         sync.Once
)

func GetSingleton() *Singleton {
    once.Do(func() {
        instance = &Singleton{data: "initialized"}
    })
    return instance
}

// 工厂模式
type Animal interface {
    Speak() string
}

type Dog struct{}

func (d *Dog) Speak() string { return "Woof!" }

type Cat struct{}

func (c *Cat) Speak() string { return "Meow!" }

func NewAnimal(animalType string) Animal {
    switch animalType {
    case "dog":
        return &Dog{}
    case "cat":
        return &Cat{}
    default:
        return nil
    }
}

// 建造者模式
type Request struct {
    Method  string
    URL     string
    Headers map[string]string
    Body    string
    Timeout int
}

type RequestBuilder struct {
    request *Request
}

func NewRequestBuilder() *RequestBuilder {
    return &RequestBuilder{
        request: &Request{
            Headers: make(map[string]string),
        },
    }
}

func (b *RequestBuilder) Method(method string) *RequestBuilder {
    b.request.Method = method
    return b
}

func (b *RequestBuilder) URL(url string) *RequestBuilder {
    b.request.URL = url
    return b
}

func (b *RequestBuilder) Header(key, value string) *RequestBuilder {
    b.request.Headers[key] = value
    return b
}

func (b *RequestBuilder) Body(body string) *RequestBuilder {
    b.request.Body = body
    return b
}

func (b *RequestBuilder) Timeout(timeout int) *RequestBuilder {
    b.request.Timeout = timeout
    return b
}

func (b *RequestBuilder) Build() *Request {
    return b.request
}

// 使用
req := NewRequestBuilder().
    Method("POST").
    URL("https://api.example.com").
    Header("Content-Type", "application/json").
    Body(`{"key": "value"}`).
    Timeout(30).
    Build()
```

#### 🔬 深度解析：Go 中设计模式的独特之处

```
┌─────────────────────────────────────────────────────────────────┐
│  Go 设计模式的独特之处                                            │
└─────────────────────────────────────────────────────────────────┘

1. 单例模式
   ├── 使用 sync.Once 保证线程安全
   ├── 无需双重检查锁定
   └── 比其他语言更简洁

2. 工厂模式
   ├── 使用接口而非继承
   ├── 返回接口类型
   └── 简单工厂足够，无需抽象工厂

3. 建造者模式
   ├── 链式调用
   ├── 可选参数模式
   └── 函数选项模式更常用
```

##### 函数选项模式（Go 惯用方式）

```go
package options

// 函数选项模式：比 Builder 更 Go 化
type Server struct {
    host    string
    port    int
    timeout time.Duration
    logger  Logger
}

type ServerOption func(*Server)

func WithHost(host string) ServerOption {
    return func(s *Server) {
        s.host = host
    }
}

func WithPort(port int) ServerOption {
    return func(s *Server) {
        s.port = port
    }
}

func WithTimeout(timeout time.Duration) ServerOption {
    return func(s *Server) {
        s.timeout = timeout
    }
}

func WithLogger(logger Logger) ServerOption {
    return func(s *Server) {
        s.logger = logger
    }
}

func NewServer(opts ...ServerOption) *Server {
    server := &Server{
        host:    "localhost",
        port:    8080,
        timeout: 30 * time.Second,
        logger:  DefaultLogger{},
    }
    
    for _, opt := range opts {
        opt(server)
    }
    
    return server
}

// 使用
server := NewServer(
    WithPort(3000),
    WithTimeout(60*time.Second),
    WithLogger(zapLogger),
)
```

> **💡 新手提示**：
> - Go 更倾向于组合而非继承
> - 函数选项模式是 Go 中处理可选配置的惯用方式
> - 使用 `sync.Once` 实现线程安全的单例

> **🎓 专家视角**：设计模式的选择：
> 1. **优先使用组合**：Go 的接口是隐式实现的
> 2. **避免过度设计**：简单工厂通常足够
> 3. **利用标准库**：`sync.Once`、`sync.Pool` 等已经实现了常见模式
> 4. **考虑泛型**：Go 1.18+ 后，泛型可以简化某些模式

### 1.2 结构型模式

```go
package patterns

import "fmt"

// 适配器模式
type LegacyPrinter interface {
    Print(s string) string
}

type ModernPrinter interface {
    PrintStored() string
}

type PrinterAdapter struct {
    OldPrinter LegacyPrinter
    Msg        string
}

func (p *PrinterAdapter) PrintStored() string {
    if p.OldPrinter != nil {
        return p.OldPrinter.Print(p.Msg)
    }
    return p.Msg
}

// 装饰器模式
type DataSource interface {
    WriteData(data string)
    ReadData() string
}

type FileDataSource struct {
    data string
}

func (f *FileDataSource) WriteData(data string) { f.data = data }
func (f *FileDataSource) ReadData() string      { return f.data }

type EncryptionDecorator struct {
    source DataSource
}

func (e *EncryptionDecorator) WriteData(data string) {
    encrypted := "encrypted(" + data + ")"
    e.source.WriteData(encrypted)
}

func (e *EncryptionDecorator) ReadData() string {
    data := e.source.ReadData()
    // 解密逻辑
    return data
}

// 使用
source := &FileDataSource{}
encrypted := &EncryptionDecorator{source: source}
encrypted.WriteData("sensitive data")

// 代理模式
type Database interface {
    Query(sql string) string
}

type RealDatabase struct{}

func (d *RealDatabase) Query(sql string) string {
    return "result from database"
}

type DatabaseProxy struct {
    real    *RealDatabase
    cache   map[string]string
    enabled bool
}

func (p *DatabaseProxy) Query(sql string) string {
    if p.enabled {
        if cached, ok := p.cache[sql]; ok {
            return cached
        }
    }
    
    result := p.real.Query(sql)
    
    if p.enabled {
        p.cache[sql] = result
    }
    
    return result
}
```

### 1.3 行为型模式

```go
package patterns

import "fmt"

// 策略模式
type PaymentStrategy interface {
    Pay(amount float64) string
}

type CreditCardPayment struct{}

func (c *CreditCardPayment) Pay(amount float64) string {
    return fmt.Sprintf("Paid %.2f via Credit Card", amount)
}

type PayPalPayment struct{}

func (p *PayPalPayment) Pay(amount float64) string {
    return fmt.Sprintf("Paid %.2f via PayPal", amount)
}

type ShoppingCart struct {
    strategy PaymentStrategy
}

func (s *ShoppingCart) SetStrategy(strategy PaymentStrategy) {
    s.strategy = strategy
}

func (s *ShoppingCart) Checkout(amount float64) string {
    return s.strategy.Pay(amount)
}

// 观察者模式
type Observer interface {
    Update(message string)
}

type Subject struct {
    observers []Observer
}

func (s *Subject) Attach(observer Observer) {
    s.observers = append(s.observers, observer)
}

func (s *Subject) Detach(observer Observer) {
    for i, o := range s.observers {
        if o == observer {
            s.observers = append(s.observers[:i], s.observers[i+1:]...)
            break
        }
    }
}

func (s *Subject) Notify(message string) {
    for _, o := range s.observers {
        o.Update(message)
    }
}

type EmailNotifier struct{}

func (e *EmailNotifier) Update(message string) {
    fmt.Printf("Email notification: %s\n", message)
}

type SMSNotifier struct{}

func (s *SMSNotifier) Update(message string) {
    fmt.Printf("SMS notification: %s\n", message)
}

// 责任链模式
type Handler interface {
    SetNext(handler Handler) Handler
    Handle(request string) string
}

type BaseHandler struct {
    next Handler
}

func (h *BaseHandler) SetNext(handler Handler) Handler {
    h.next = handler
    return handler
}

func (h *BaseHandler) Handle(request string) string {
    if h.next != nil {
        return h.next.Handle(request)
    }
    return ""
}

type AuthHandler struct {
    BaseHandler
}

func (h *AuthHandler) Handle(request string) string {
    if request == "auth" {
        return "Authentication passed"
    }
    return h.BaseHandler.Handle(request)
}

type LogHandler struct {
    BaseHandler
}

func (h *LogHandler) Handle(request string) string {
    fmt.Printf("Logging: %s\n", request)
    return h.BaseHandler.Handle(request)
}
```

---

## 2. 函数式编程

### 2.1 高阶函数

```go
package functional

// Map 函数
func Map[T, U any](slice []T, fn func(T) U) []U {
    result := make([]U, len(slice))
    for i, v := range slice {
        result[i] = fn(v)
    }
    return result
}

// Filter 函数
func Filter[T any](slice []T, predicate func(T) bool) []T {
    result := []T{}
    for _, v := range slice {
        if predicate(v) {
            result = append(result, v)
        }
    }
    return result
}

// Reduce 函数
func Reduce[T, U any](slice []T, initial U, fn func(U, T) U) U {
    result := initial
    for _, v := range slice {
        result = fn(result, v)
    }
    return result
}

// 使用
func main() {
    nums := []int{1, 2, 3, 4, 5}
    
    // Map
    doubled := Map(nums, func(n int) int { return n * 2 })
    // [2, 4, 6, 8, 10]
    
    // Filter
    evens := Filter(nums, func(n int) bool { return n%2 == 0 })
    // [2, 4]
    
    // Reduce
    sum := Reduce(nums, 0, func(acc, n int) int { return acc + n })
    // 15
}
```

### 2.2 函数组合

```go
package functional

// 函数组合
func Compose[T, U, V any](f func(U) V, g func(T) U) func(T) V {
    return func(t T) V {
        return f(g(t))
    }
}

// Pipeline
func Pipeline[T any](value T, functions ...func(T) T) T {
    result := value
    for _, fn := range functions {
        result = fn(result)
    }
    return result
}

// 使用
func main() {
    // 函数组合
    addOne := func(x int) int { return x + 1 }
    double := func(x int) int { return x * 2 }
    
    addOneThenDouble := Compose(double, addOne)
    fmt.Println(addOneThenDouble(5))  // (5 + 1) * 2 = 12
    
    // Pipeline
    result := Pipeline(5,
        func(x int) int { return x + 1 },
        func(x int) int { return x * 2 },
        func(x int) int { return x - 3 },
    )
    fmt.Println(result)  // ((5 + 1) * 2) - 3 = 9
}
```

### 2.3 柯里化

```go
package functional

// 柯里化
func Add(a int) func(int) int {
    return func(b int) int {
        return a + b
    }
}

// 通用柯里化
func Curry[T, U, V any](fn func(T, U) V) func(T) func(U) V {
    return func(t T) func(U) V {
        return func(u U) V {
            return fn(t, u)
        }
    }
}

// 使用
func main() {
    addFive := Add(5)
    fmt.Println(addFive(3))  // 8
    
    multiply := func(a, b int) int { return a * b }
    curriedMultiply := Curry(multiply)
    double := curriedMultiply(2)
    fmt.Println(double(5))  // 10
}
```

---

## 3. 泛型编程

### 3.1 泛型容器

```go
package container

// 泛型栈
type Stack[T any] struct {
    elements []T
}

func NewStack[T any]() *Stack[T] {
    return &Stack[T]{elements: []T{}}
}

func (s *Stack[T]) Push(v T) {
    s.elements = append(s.elements, v)
}

func (s *Stack[T]) Pop() (T, bool) {
    var zero T
    if len(s.elements) == 0 {
        return zero, false
    }
    v := s.elements[len(s.elements)-1]
    s.elements = s.elements[:len(s.elements)-1]
    return v, true
}

func (s *Stack[T]) Peek() (T, bool) {
    var zero T
    if len(s.elements) == 0 {
        return zero, false
    }
    return s.elements[len(s.elements)-1], true
}

func (s *Stack[T]) Size() int {
    return len(s.elements)
}

// 泛型队列
type Queue[T any] struct {
    elements []T
}

func NewQueue[T any]() *Queue[T] {
    return &Queue[T]{elements: []T{}}
}

func (q *Queue[T]) Enqueue(v T) {
    q.elements = append(q.elements, v)
}

func (q *Queue[T]) Dequeue() (T, bool) {
    var zero T
    if len(q.elements) == 0 {
        return zero, false
    }
    v := q.elements[0]
    q.elements = q.elements[1:]
    return v, true
}

// 泛型集合
type Set[T comparable] struct {
    elements map[T]struct{}
}

func NewSet[T comparable]() *Set[T] {
    return &Set[T]{elements: make(map[T]struct{})}
}

func (s *Set[T]) Add(v T) {
    s.elements[v] = struct{}{}
}

func (s *Set[T]) Remove(v T) {
    delete(s.elements, v)
}

func (s *Set[T]) Contains(v T) bool {
    _, ok := s.elements[v]
    return ok
}

func (s *Set[T]) ToSlice() []T {
    result := make([]T, 0, len(s.elements))
    for v := range s.elements {
        result = append(result, v)
    }
    return result
}
```

### 3.2 泛型约束

```go
package constraints

// 类型约束
type Number interface {
    int | int64 | float32 | float64
}

type Ordered interface {
    int | int64 | float32 | float64 | string
}

// 泛型最小值
func Min[T Ordered](a, b T) T {
    if a < b {
        return a
    }
    return b
}

// 泛型最大值
func Max[T Ordered](a, b T) T {
    if a > b {
        return a
    }
    return b
}

// 泛型排序
func Sort[T Ordered](slice []T) []T {
    result := make([]T, len(slice))
    copy(result, slice)
    
    for i := 0; i < len(result)-1; i++ {
        for j := i + 1; j < len(result); j++ {
            if result[j] < result[i] {
                result[i], result[j] = result[j], result[i]
            }
        }
    }
    
    return result
}

// 泛型查找
func Find[T comparable](slice []T, target T) (int, bool) {
    for i, v := range slice {
        if v == target {
            return i, true
        }
    }
    return -1, false
}

// 泛型去重
func Unique[T comparable](slice []T) []T {
    seen := make(map[T]struct{})
    result := []T{}
    
    for _, v := range slice {
        if _, ok := seen[v]; !ok {
            seen[v] = struct{}{}
            result = append(result, v)
        }
    }
    
    return result
}
```

---

## 4. 插件系统

### 4.1 基于接口的插件

```go
package plugin

// 插件接口
type Plugin interface {
    Name() string
    Init(config map[string]interface{}) error
    Execute(input string) (string, error)
    Close() error
}

// 插件管理器
type PluginManager struct {
    plugins map[string]Plugin
}

func NewPluginManager() *PluginManager {
    return &PluginManager{
        plugins: make(map[string]Plugin),
    }
}

func (m *PluginManager) Register(plugin Plugin) error {
    if _, exists := m.plugins[plugin.Name()]; exists {
        return fmt.Errorf("plugin %s already registered", plugin.Name())
    }
    m.plugins[plugin.Name()] = plugin
    return nil
}

func (m *PluginManager) Get(name string) (Plugin, bool) {
    plugin, ok := m.plugins[name]
    return plugin, ok
}

func (m *PluginManager) Execute(pluginName, input string) (string, error) {
    plugin, ok := m.plugins[pluginName]
    if !ok {
        return "", fmt.Errorf("plugin %s not found", pluginName)
    }
    return plugin.Execute(input)
}

// 示例插件
type UpperCasePlugin struct{}

func (p *UpperCasePlugin) Name() string { return "uppercase" }
func (p *UpperCasePlugin) Init(config map[string]interface{}) error { return nil }
func (p *UpperCasePlugin) Execute(input string) (string, error) {
    return strings.ToUpper(input), nil
}
func (p *UpperCasePlugin) Close() error { return nil }
```

### 4.2 基于反射的插件

```go
package plugin

import (
    "reflect"
    "plugin"
)

// 加载 .so 插件
func LoadPlugin(path string) (Plugin, error) {
    p, err := plugin.Open(path)
    if err != nil {
        return nil, err
    }
    
    symbol, err := p.Lookup("Plugin")
    if err != nil {
        return nil, err
    }
    
    pluginInstance, ok := symbol.(Plugin)
    if !ok {
        return nil, fmt.Errorf("symbol does not implement Plugin interface")
    }
    
    return pluginInstance, nil
}

// 动态注册
func (m *PluginManager) LoadAndRegister(path string) error {
    plugin, err := LoadPlugin(path)
    if err != nil {
        return err
    }
    return m.Register(plugin)
}
```

---

## 5. 中间件模式

### 5.1 HTTP 中间件

```go
package middleware

import (
    "net/http"
    "time"
)

type Middleware func(http.Handler) http.Handler

// 链式中间件
func Chain(h http.Handler, middlewares ...Middleware) http.Handler {
    for i := len(middlewares) - 1; i >= 0; i-- {
        h = middlewares[i](h)
    }
    return h
}

// 日志中间件
func Logging(logger Logger) Middleware {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            start := time.Now()
            
            wrapped := &responseWriter{ResponseWriter: w}
            next.ServeHTTP(wrapped, r)
            
            logger.Info("request",
                "method", r.Method,
                "path", r.URL.Path,
                "status", wrapped.status,
                "duration", time.Since(start),
            )
        })
    }
}

// 认证中间件
func Auth(authenticator Authenticator) Middleware {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            token := r.Header.Get("Authorization")
            
            user, err := authenticator.Authenticate(token)
            if err != nil {
                http.Error(w, "Unauthorized", http.StatusUnauthorized)
                return
            }
            
            ctx := context.WithValue(r.Context(), "user", user)
            next.ServeHTTP(w, r.WithContext(ctx))
        })
    }
}

// 限流中间件
func RateLimiter(limiter *Limiter) Middleware {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            if !limiter.Allow(r.RemoteAddr) {
                http.Error(w, "Too Many Requests", http.StatusTooManyRequests)
                return
            }
            next.ServeHTTP(w, r)
        })
    }
}

// 使用
func main() {
    handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.Write([]byte("Hello"))
    })
    
    http.Handle("/", Chain(handler,
        Logging(logger),
        Auth(authenticator),
        RateLimiter(limiter),
    ))
}
```

### 5.2 函数中间件

```go
package middleware

// 函数中间件
type FuncMiddleware func(Func) Func

type Func func(ctx context.Context, req interface{}) (interface{}, error)

// 函数中间件链
func ChainFunc(f Func, middlewares ...FuncMiddleware) Func {
    for i := len(middlewares) - 1; i >= 0; i-- {
        f = middlewares[i](f)
    }
    return f
}

// 超时中间件
func Timeout(timeout time.Duration) FuncMiddleware {
    return func(next Func) Func {
        return func(ctx context.Context, req interface{}) (interface{}, error) {
            ctx, cancel := context.WithTimeout(ctx, timeout)
            defer cancel()
            
            resultCh := make(chan interface{})
            errCh := make(chan error)
            
            go func() {
                result, err := next(ctx, req)
                if err != nil {
                    errCh <- err
                    return
                }
                resultCh <- result
            }()
            
            select {
            case result := <-resultCh:
                return result, nil
            case err := <-errCh:
                return nil, err
            case <-ctx.Done():
                return nil, ctx.Err()
            }
        }
    }
}

// 重试中间件
func Retry(maxRetries int) FuncMiddleware {
    return func(next Func) Func {
        return func(ctx context.Context, req interface{}) (interface{}, error) {
            var lastErr error
            for i := 0; i < maxRetries; i++ {
                result, err := next(ctx, req)
                if err == nil {
                    return result, nil
                }
                lastErr = err
                
                select {
                case <-ctx.Done():
                    return nil, ctx.Err()
                case <-time.After(time.Second * time.Duration(i+1)):
                }
            }
            return nil, lastErr
        }
    }
}
```
