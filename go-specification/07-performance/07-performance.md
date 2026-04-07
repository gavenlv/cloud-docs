# Go 性能优化

> **🎯 核心概念**：性能优化是系统性的工作，需要先测量再优化。理解 Go 的内存模型和运行时机制，能让你找到真正的性能瓶颈。

## 1. 内存管理

> **🎯 核心概念**：Go 是垃圾回收语言，理解内存分配和 GC 行为对性能优化至关重要。

### 1.1 内存分配优化

```go
package optimization

import "testing"

// 避免不必要的分配
func BenchmarkSliceWithMake(b *testing.B) {
    for i := 0; i < b.N; i++ {
        // 预分配容量
        s := make([]int, 0, 100)
        for j := 0; j < 100; j++ {
            s = append(s, j)
        }
    }
}

func BenchmarkSliceWithoutMake(b *testing.B) {
    for i := 0; i < b.N; i++ {
        // 动态增长，多次分配
        var s []int
        for j := 0; j < 100; j++ {
            s = append(s, j)
        }
    }
}

// 使用 sync.Pool 复用对象
var bufferPool = sync.Pool{
    New: func() interface{} {
        return new(bytes.Buffer)
    },
}

func ProcessData(data []byte) string {
    buf := bufferPool.Get().(*bytes.Buffer)
    defer func() {
        buf.Reset()
        bufferPool.Put(buf)
    }()
    
    buf.Write(data)
    return buf.String()
}

// 避免逃逸分析问题
type Data struct {
    values [1000]int
}

// 值返回（栈分配）
func createData() Data {
    return Data{}
}

// 指针返回（堆分配）
func createDataPointer() *Data {
    return &Data{}  // 逃逸到堆
}
```

#### 🔬 深度解析：逃逸分析

```
┌─────────────────────────────────────────────────────────────────┐
│  Go 逃逸分析                                                      │
└─────────────────────────────────────────────────────────────────┘

什么是逃逸？
├── 变量从栈"逃逸"到堆
├── 编译器自动决定
└── 影响性能和 GC 压力

常见逃逸场景:
├── 返回局部变量指针
├── 发送到 channel
├── 存储在全局变量
├── 闭包捕获
└── 接口转换

查看逃逸分析:
└── go build -gcflags="-m"
```

##### 逃逸分析实战

```go
package escape

// 场景1: 返回局部变量指针
func escape1() *int {
    x := 1
    return &x  // x 逃逸到堆
}

func noEscape1() int {
    x := 1
    return x   // x 在栈上
}

// 场景2: 切片容量不确定
func escape2() []int {
    n := 10
    return make([]int, n)  // n 逃逸（不确定大小）
}

func noEscape2() []int {
    return make([]int, 10)  // 常量大小，不逃逸
}

// 场景3: 接口转换
func escape3(x interface{}) {
    if s, ok := x.(string); ok {
        _ = s
    }
}

// 场景4: 闭包捕获
func escape4() func() int {
    x := 1
    return func() int {  // x 逃逸（被闭包捕获）
        return x
    }
}

// 使用 go build -gcflags="-m" 查看逃逸分析结果
```

##### sync.Pool 最佳实践

```go
package pool

import (
    "bytes"
    "sync"
)

// 场景1: 缓冲区复用
var bufferPool = sync.Pool{
    New: func() interface{} {
        return bytes.NewBuffer(make([]byte, 0, 1024))
    },
}

func ProcessBuffer(data []byte) []byte {
    buf := bufferPool.Get().(*bytes.Buffer)
    defer func() {
        buf.Reset()
        bufferPool.Put(buf)
    }()
    
    buf.Write(data)
    // 处理...
    result := make([]byte, buf.Len())
    copy(result, buf.Bytes())
    return result
}

// 场景2: 结构体复用
type Request struct {
    ID      int
    Headers map[string]string
    Body    []byte
}

var requestPool = sync.Pool{
    New: func() interface{} {
        return &Request{
            Headers: make(map[string]string, 10),
            Body:    make([]byte, 0, 1024),
        }
    },
}

func AcquireRequest() *Request {
    req := requestPool.Get().(*Request)
    req.ID = 0
    for k := range req.Headers {
        delete(req.Headers, k)
    }
    req.Body = req.Body[:0]
    return req
}

func ReleaseRequest(req *Request) {
    requestPool.Put(req)
}
```

> **💡 新手提示**：
> - 使用 `go build -gcflags="-m"` 查看逃逸分析
> - 预分配切片和 map 可以显著提高性能
> - `sync.Pool` 适合复用临时对象，不适合长期存储

> **🎓 专家视角**：内存优化的高级技巧：
> 1. **减少指针**：指针会导致逃逸，小结构体用值类型
> 2. **预分配**：`make([]T, 0, cap)` 比 `var s []T` + append 快
> 3. **字符串拼接**：`strings.Builder` 比 `+` 快得多
> 4. **避免 []byte 和 string 转换**：使用 `unsafe` 或重写函数
> 5. **GC 调优**：`GOGC` 环境变量控制 GC 频率
```

### 1.2 字符串优化

```go
package optimization

import (
    "bytes"
    "strings"
)

// 使用 strings.Builder
func concatStrings(parts []string) string {
    var builder strings.Builder
    builder.Grow(len(parts) * 10)  // 预估大小
    
    for _, part := range parts {
        builder.WriteString(part)
    }
    
    return builder.String()
}

// 使用 bytes.Buffer
func concatBytes(parts [][]byte) []byte {
    var buffer bytes.Buffer
    buffer.Grow(len(parts) * 10)
    
    for _, part := range parts {
        buffer.Write(part)
    }
    
    return buffer.Bytes()
}

// 避免字符串到字节转换
func processString(s string) []byte {
    // 错误: 不必要的转换
    // return []byte(s)
    
    // 正确: 如果只读，使用 unsafe（谨慎使用）
    // 或者直接处理 string
    return []byte(s)
}

// 使用 strconv 代替 fmt
func intToString(n int) string {
    // 慢
    // return fmt.Sprintf("%d", n)
    
    // 快
    return strconv.Itoa(n)
}
```

---

## 2. 切片与 Map 优化

### 2.1 切片优化

```go
package optimization

// 预分配切片
func processItems(items []Item) []Result {
    // 预分配结果切片
    results := make([]Result, 0, len(items))
    
    for _, item := range items {
        results = append(results, process(item))
    }
    
    return results
}

// 切片过滤（避免分配新切片）
func filterInPlace(slice []int, predicate func(int) bool) []int {
    n := 0
    for _, v := range slice {
        if predicate(v) {
            slice[n] = v
            n++
        }
    }
    return slice[:n]
}

// 切片去重
func unique(slice []int) []int {
    seen := make(map[int]struct{}, len(slice))
    result := make([]int, 0, len(slice))
    
    for _, v := range slice {
        if _, ok := seen[v]; !ok {
            seen[v] = struct{}{}
            result = append(result, v)
        }
    }
    
    return result
}

// 批量处理
func processBatch(items []Item, batchSize int) [][]Result {
    batches := make([][]Result, 0, (len(items)+batchSize-1)/batchSize)
    
    for i := 0; i < len(items); i += batchSize {
        end := i + batchSize
        if end > len(items) {
            end = len(items)
        }
        
        batch := processItems(items[i:end])
        batches = append(batches, batch)
    }
    
    return batches
}
```

### 2.2 Map 优化

```go
package optimization

// 预分配 Map
func countWords(words []string) map[string]int {
    // 预分配大小
    counts := make(map[string]int, len(words)/2)
    
    for _, word := range words {
        counts[word]++
    }
    
    return counts
}

// 使用 sync.Map（并发场景）
type Cache struct {
    m sync.Map
}

func (c *Cache) Get(key string) (interface{}, bool) {
    return c.m.Load(key)
}

func (c *Cache) Set(key string, value interface{}) {
    c.m.Store(key, value)
}

// 分片 Map（高并发场景）
type ShardedMap struct {
    shards []*shard
}

type shard struct {
    sync.RWMutex
    data map[string]interface{}
}

func NewShardedMap(numShards int) *ShardedMap {
    shards := make([]*shard, numShards)
    for i := 0; i < numShards; i++ {
        shards[i] = &shard{
            data: make(map[string]interface{}),
        }
    }
    return &ShardedMap{shards: shards}
}

func (m *ShardedMap) getShard(key string) *shard {
    hash := fnv32(key)
    return m.shards[hash%uint32(len(m.shards))]
}

func (m *ShardedMap) Get(key string) (interface{}, bool) {
    shard := m.getShard(key)
    shard.RLock()
    defer shard.RUnlock()
    return shard.data[key]
}

func (m *ShardedMap) Set(key string, value interface{}) {
    shard := m.getShard(key)
    shard.Lock()
    defer shard.Unlock()
    shard.data[key] = value
}

func fnv32(key string) uint32 {
    hash := uint32(2166136261)
    const prime32 = uint32(16777619)
    for i := 0; i < len(key); i++ {
        hash *= prime32
        hash ^= uint32(key[i])
    }
    return hash
}
```

---

## 3. 并发优化

### 3.1 Goroutine 池

```go
package pool

import (
    "sync"
)

type Task func()

type Pool struct {
    tasks   chan Task
    workers int
    wg      sync.WaitGroup
}

func NewPool(workers int, taskCapacity int) *Pool {
    p := &Pool{
        tasks:   make(chan Task, taskCapacity),
        workers: workers,
    }
    
    p.start()
    return p
}

func (p *Pool) start() {
    for i := 0; i < p.workers; i++ {
        p.wg.Add(1)
        go func() {
            defer p.wg.Done()
            for task := range p.tasks {
                task()
            }
        }()
    }
}

func (p *Pool) Submit(task Task) {
    p.tasks <- task
}

func (p *Pool) Close() {
    close(p.tasks)
    p.wg.Wait()
}

// 使用
func main() {
    pool := NewPool(10, 100)
    
    for i := 0; i < 1000; i++ {
        pool.Submit(func() {
            // 处理任务
        })
    }
    
    pool.Close()
}
```

### 3.2 批处理与合并

```go
package batch

import (
    "sync"
    "time"
)

type Batcher struct {
    items     []Item
    mu        sync.Mutex
    maxSize   int
    maxWait   time.Duration
    processor func([]Item)
    timer     *time.Timer
}

func NewBatcher(maxSize int, maxWait time.Duration, processor func([]Item)) *Batcher {
    b := &Batcher{
        items:     make([]Item, 0, maxSize),
        maxSize:   maxSize,
        maxWait:   maxWait,
        processor: processor,
    }
    b.timer = time.AfterFunc(maxWait, b.flush)
    return b
}

func (b *Batcher) Add(item Item) {
    b.mu.Lock()
    defer b.mu.Unlock()
    
    b.items = append(b.items, item)
    
    if len(b.items) >= b.maxSize {
        b.flush()
        b.timer.Reset(b.maxWait)
    }
}

func (b *Batcher) flush() {
    if len(b.items) == 0 {
        return
    }
    
    items := b.items
    b.items = make([]Item, 0, b.maxSize)
    
    go b.processor(items)
}
```

---

## 4. 性能分析工具

### 4.1 pprof 使用

```go
package main

import (
    "net/http"
    _ "net/http/pprof"
)

func main() {
    // 启动 pprof 服务
    go func() {
        http.ListenAndServe(":6060", nil)
    }()
    
    // 应用代码
    // ...
}
```

```bash
# CPU 分析
go tool pprof http://localhost:6060/debug/pprof/profile?seconds=30

# 内存分析
go tool pprof http://localhost:6060/debug/pprof/heap

# Goroutine 分析
go tool pprof http://localhost:6060/debug/pprof/goroutine

# 阻塞分析
go tool pprof http://localhost:6060/debug/pprof/block

# 互斥锁分析
go tool pprof http://localhost:6060/debug/pprof/mutex

# Web 界面
go tool pprof -http=:8080 http://localhost:6060/debug/pprof/profile
```

### 4.2 benchmark 分析

```bash
# 运行基准测试
go test -bench=. -benchmem

# 生成 CPU profile
go test -bench=. -cpuprofile=cpu.prof

# 生成内存 profile
go test -bench=. -memprofile=mem.prof

# 分析
go tool pprof cpu.prof
go tool pprof mem.prof

# 比较基准测试
go test -bench=. -count=5 | tee old.txt
# 修改代码
go test -bench=. -count=5 | tee new.txt
# 比较
go install golang.org/x/perf/cmd/benchstat@latest
benchstat old.txt new.txt
```

### 4.3 trace 分析

```go
package main

import (
    "os"
    "runtime/trace"
)

func main() {
    f, _ := os.Create("trace.out")
    defer f.Close()
    
    trace.Start(f)
    defer trace.Stop()
    
    // 应用代码
}
```

```bash
# 查看 trace
go tool trace trace.out
```

---

## 5. 编译优化

### 5.1 编译选项

```bash
# 禁用内联（调试用）
go build -gcflags="-l"

# 优化级别
go build -gcflags="-l=4"

# 禁用优化
go build -gcflags="-N -l"

# 查看编译决策
go build -gcflags="-m"

# 减小二进制大小
go build -ldflags="-s -w"

# 使用 UPX 进一步压缩
upx --best --lzma myapp

# 交叉编译
GOOS=linux GOARCH=amd64 go build
GOOS=darwin GOARCH=arm64 go build
GOOS=windows GOARCH=amd64 go build
```

### 5.2 链接时优化

```bash
# PGO (Profile-Guided Optimization)
# 1. 生成 profile
go test -cpuprofile=cpu.pprof -bench=.

# 2. 使用 profile 编译
go build -pgo=cpu.pprof
```

---

## 6. 常见优化技巧

### 6.1 避免常见陷阱

```go
package optimization

// 1. 避免在循环中分配
func bad() {
    for i := 0; i < 1000; i++ {
        _ = make([]byte, 100)  // 每次循环都分配
    }
}

func good() {
    buf := make([]byte, 100)  // 循环外分配
    for i := 0; i < 1000; i++ {
        // 使用 buf
    }
}

// 2. 使用值类型代替指针（小对象）
type Point struct {
    X, Y int
}

func processPoints(points []Point) {  // 值类型
    // ...
}

// 3. 避免接口类型（性能关键代码）
func sumInts(nums []int) int {  // 具体类型
    total := 0
    for _, n := range nums {
        total += n
    }
    return total
}

func sumInterfaces(nums []interface{}) int {  // 接口类型（慢）
    total := 0
    for _, n := range nums {
        total += n.(int)  // 类型断言开销
    }
    return total
}

// 4. 使用 sync.Pool 复用
var byteSlicePool = sync.Pool{
    New: func() interface{} {
        return make([]byte, 1024)
    },
}

func processWithPool() {
    buf := byteSlicePool.Get().([]byte)
    defer byteSlicePool.Put(buf)
    
    // 使用 buf
}

// 5. 避免反射（性能关键代码）
func badReflection() {
    v := reflect.ValueOf(someStruct)
    field := v.FieldByName("Name")  // 慢
}

func goodDirect() {
    name := someStruct.Name  // 快
}
```

### 6.2 数据结构选择

```
┌─────────────────────────────────────────────────────────────────┐
│  数据结构选择指南                                                  │
└─────────────────────────────────────────────────────────────────┘

场景: 需要快速查找
├── 小数据量 (< 100): 线性搜索切片
├── 中等数据量: map
└── 大数据量: 预分配 map 或第三方库

场景: 需要有序遍历
├── 使用切片 + sort
└── 或使用第三方有序 map

场景: 需要频繁插入/删除
├── 头部插入: list.List 或 container/list
├── 尾部插入: 切片
└── 中间插入: 考虑其他数据结构

场景: 需要去重
├── map[T]struct{}
└── 第三方 set 实现

场景: 需要优先级
├── container/heap
└── 第三方优先队列

场景: 高并发
├── sync.Map
├── 分片 map
└── 第三方并发安全数据结构
```

---

## 7. 性能优化清单

```
┌─────────────────────────────────────────────────────────────────┐
│  Go 性能优化清单                                                  │
└─────────────────────────────────────────────────────────────────┘

内存优化
├── 预分配切片和 map
├── 使用 sync.Pool 复用对象
├── 避免不必要的指针
├── 减少逃逸到堆
└── 使用值类型（小对象）

CPU 优化
├── 避免反射
├── 使用具体类型代替接口
├── 内联小函数
├── 避免频繁的类型断言
└── 使用 strconv 代替 fmt

并发优化
├── 使用 goroutine 池
├── 控制并发数量
├── 减少锁竞争
├── 使用读写锁
└── 批处理请求

I/O 优化
├── 使用缓冲 I/O
├── 批量读写
├── 异步处理
├── 连接池
└── 压缩传输

工具使用
├── pprof 分析
├── benchmark 测试
├── trace 追踪
├── 竞争检测 (-race)
└── 内存分析
```
