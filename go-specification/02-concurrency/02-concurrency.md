# Go 并发编程

## 1. 并发基础

### 1.1 并发 vs 并行

> **🎯 核心概念**：理解并发和并行的区别是掌握 Go 并发编程的第一步。

```
┌─────────────────────────────────────────────────────────────────┐
│  并发 vs 并行                                                     │
└─────────────────────────────────────────────────────────────────┘

并发 (Concurrency):
├── 多个任务交替执行
├── 单核也可以实现
├── 关注任务的结构组织
└── Go: goroutine + channel

并行 (Parallelism):
├── 多个任务同时执行
├── 需要多核
├── 关注任务的执行效率
└── Go: GOMAXPROCS 设置并行度

Go 的哲学:
"Don't communicate by sharing memory; share memory by communicating."
不要通过共享内存来通信，而要通过通信来共享内存。
```

#### 🔬 深度解析：为什么 Go 选择 CSP 模型？

```go
// 传统方式：通过共享内存通信（需要手动加锁）
type Counter struct {
    mu    sync.Mutex
    value int
}

func (c *Counter) Increment() {
    c.mu.Lock()
    c.value++
    c.mu.Unlock()
}

// Go 方式：通过通信共享内存（无需显式加锁）
func counterService(increment <-chan struct{}, result chan<- int) {
    count := 0
    for range increment {
        count++
    }
    result <- count
}
```

**为什么 CSP 更好？**

| 维度 | 共享内存 + 锁 | CSP (Channel) |
|------|--------------|---------------|
| 心智负担 | 高（需考虑锁粒度、死锁） | 低（数据归属明确） |
| 调试难度 | 困难（竞态条件难复现） | 简单（数据流清晰） |
| 可组合性 | 差（锁难以组合） | 好（channel 可组合） |
| 性能 | 高（无额外开销） | 中等（有调度开销） |

> **💡 新手提示**：不要因为 channel 有开销就拒绝使用。在大多数场景下，channel 的性能足够好，而它带来的代码清晰度提升是无价的。

> **🎓 专家视角**：CSP 模型的核心思想是"数据归属"——同一时刻只有一个 goroutine 拥有数据的所有权。这从根本上避免了数据竞争。但在高性能场景（如每秒百万次操作），sync 包的原语仍然是更好的选择。

### 1.2 Goroutine 原理

> **🎯 核心概念**：Goroutine 是 Go 并发的基石，理解其底层原理对写出高效并发程序至关重要。

```
┌─────────────────────────────────────────────────────────────────┐
│  Goroutine vs OS Thread                                          │
└─────────────────────────────────────────────────────────────────┘

特性对比:
┌─────────────────┬────────────────┬────────────────┐
│     特性         │   Goroutine    │   OS Thread    │
├─────────────────┼────────────────┼────────────────┤
│ 初始栈大小       │ 2KB            │ 1-8MB          │
│ 创建开销         │ ~300ns         │ ~100µs         │
│ 上下文切换       │ ~200ns         │ ~1µs           │
│ 内存占用         │ 动态增长        │ 固定           │
│ 调度器           │ Go runtime     │ OS kernel      │
│ 数量上限         │ 百万级          │ 千级           │
└─────────────────┴────────────────┴────────────────┘
```

#### 🔬 深度解析：GMP 调度模型

GMP 是 Go 运行时的核心调度模型，理解它对于写出高性能并发程序至关重要。

```
GMP 调度模型:
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│   G (Goroutine)                                                 │
│   ├── 用户级协程                                                 │
│   ├── 包含栈、指令指针等信息                                      │
│   └── 初始栈 2KB，最大可达 1GB                                    │
│                                                                  │
│   M (Machine/Thread)                                             │
│   ├── 操作系统线程                                                │
│   ├── 执行 G 的载体                                               │
│   └── 最多 10000 个                                               │
│                                                                  │
│   P (Processor)                                                  │
│   ├── 逻辑处理器                                                  │
│   ├── 持有本地运行队列                                            │
│   └── 默认等于 CPU 核数                                           │
│                                                                  │
│   ┌───┐   ┌───┐   ┌───┐                                        │
│   │ G │──▶│ M │──▶│ P │                                        │
│   └───┘   └───┘   └───┘                                        │
│                                                                  │
│   调度策略:                                                       │
│   ├── Work Stealing: P 从其他 P 偷 G                             │
│   ├── Hand Off: 阻塞的 M 释放 P                                  │
│   └── Preemption: 基于信号抢占                                   │
└─────────────────────────────────────────────────────────────────┘
```

##### GMP 调度流程详解

```go
// 模拟 GMP 调度过程
package main

import (
    "fmt"
    "runtime"
    "time"
)

func main() {
    // 查看 P 的数量（等于 GOMAXPROCS）
    fmt.Printf("GOMAXPROCS: %d\n", runtime.GOMAXPROCS(0))
    fmt.Printf("NumCPU: %d\n", runtime.NumCPU())
    
    // 调度器行为演示
    for i := 0; i < 10; i++ {
        go func(id int) {
            // 每个 G 会被分配到某个 P 的本地队列
            // 如果 P 的本地队列满，会放入全局队列
            fmt.Printf("Goroutine %d running on P\n", id)
        }(i)
    }
    
    time.Sleep(time.Second)
}
```

**调度策略详解：**

| 策略 | 描述 | 触发条件 |
|------|------|---------|
| Work Stealing | P 从其他 P 的本地队列偷 G | 本地队列空 |
| Hand Off | M 阻塞时释放 P | 系统调用、cgo 调用 |
| Preemption | 强制抢占长时间运行的 G | 10ms 未让出 CPU |
| Network Poller | 处理网络 I/O 的 G | 网络 I/O 就绪 |

##### 栈增长机制

```go
// 栈增长演示
package main

import (
    "fmt"
    "runtime"
)

func deepRecursion(n int) int {
    if n <= 0 {
        // 打印当前栈大小
        var buf [1 << 20]byte
        fmt.Printf("Stack size: %d KB\n", len(buf)/1024)
        return 0
    }
    // 每次递归分配 1KB 栈空间
    var buf [1024]byte
    buf[0] = 0
    return deepRecursion(n-1) + int(buf[0])
}

func main() {
    fmt.Println("Before recursion:")
    deepRecursion(100)
}
```

> **💡 新手提示**：Goroutine 的栈是动态增长的，从 2KB 开始，最多可以增长到 1GB（64位系统）。这意味着你不需要担心递归深度导致的栈溢出，除非你的递归真的非常深。

> **🎓 专家视角**：Go 1.4 之后使用连续栈（contiguous stack）代替分段栈。当栈空间不足时，会分配一个 2 倍大的新栈，复制旧栈数据。这避免了分段栈的"热分裂"问题，但复制有开销。如果你的程序有深度递归，考虑使用迭代替代。

##### 调度器调优

```go
// 调度器调优示例
package main

import (
    "fmt"
    "runtime"
    "runtime/debug"
    "time"
)

func main() {
    // 设置 P 的数量（影响并行度）
    runtime.GOMAXPROCS(4)
    
    // 设置最大线程数
    debug.SetMaxThreads(100)
    
    // 查看调度器信息
    var stats runtime.MemStats
    runtime.ReadMemStats(&stats)
    fmt.Printf("Goroutines: %d\n", runtime.NumGoroutine())
    
    // 触发 GC（会暂停调度）
    runtime.GC()
    
    // 让出 CPU，触发调度
    runtime.Gosched()
    
    // 使用 LockOSThread 绑定 M
    // 适用于需要线程局部存储或 cgo 的场景
    runtime.LockOSThread()
    defer runtime.UnlockOSThread()
    
    time.Sleep(time.Second)
}
```

**何时使用 LockOSThread？**

```go
// 场景1：cgo 调用需要固定线程
// #include <pthread.h>
import "C"

func cgoCall() {
    runtime.LockOSThread()
    defer runtime.UnlockOSThread()
    // C 代码可能依赖线程局部状态
    C.some_c_function()
}

// 场景2：OpenGL 等图形库要求
func renderLoop() {
    runtime.LockOSThread()
    defer runtime.UnlockOSThread()
    // OpenGL 上下文绑定到特定线程
    for {
        renderFrame()
    }
}
```

---

## 2. Goroutine

### 2.1 基本使用

```go
package main

import (
    "fmt"
    "runtime"
    "sync"
    "time"
)

func sayHello() {
    fmt.Println("Hello from goroutine")
}

func main() {
    // 启动 goroutine
    go sayHello()
    
    // 匿名函数
    go func() {
        fmt.Println("Hello from anonymous goroutine")
    }()
    
    // 带参数的匿名函数
    go func(msg string) {
        fmt.Println(msg)
    }("Hello with argument")
    
    // 等待 goroutine 完成
    time.Sleep(100 * time.Millisecond)
    
    // 使用 WaitGroup
    var wg sync.WaitGroup
    
    for i := 0; i < 5; i++ {
        wg.Add(1)
        go func(n int) {
            defer wg.Done()
            fmt.Printf("Worker %d\n", n)
        }(i)
    }
    
    wg.Wait()
    fmt.Println("All workers done")
    
    // 查看 goroutine 数量
    fmt.Printf("Goroutines: %d\n", runtime.NumGoroutine())
}
```

### 2.2 Goroutine 生命周期

```go
package main

import (
    "context"
    "fmt"
    "time"
)

func worker(ctx context.Context, id int) {
    for {
        select {
        case <-ctx.Done():
            fmt.Printf("Worker %d: shutting down\n", id)
            return
        default:
            fmt.Printf("Worker %d: working\n", id)
            time.Sleep(500 * time.Millisecond)
        }
    }
}

func main() {
    // 使用 context 控制 goroutine 生命周期
    ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
    defer cancel()
    
    // 启动多个 worker
    for i := 0; i < 3; i++ {
        go worker(ctx, i)
    }
    
    // 等待 context 超时
    <-ctx.Done()
    fmt.Println("Main: context done")
    
    time.Sleep(100 * time.Millisecond)  // 让 worker 完成清理
}
```

---

## 3. Channel

> **🎯 核心概念**：Channel 是 Go 并发的核心，它是 CSP 模型的具体实现，用于 goroutine 之间的通信。

### 3.1 Channel 基础

```go
package main

import "fmt"

func main() {
    // 无缓冲 channel
    ch := make(chan int)
    
    go func() {
        ch <- 42  // 发送
    }()
    
    value := <-ch  // 接收
    fmt.Println("Received:", value)
    
    // 有缓冲 channel
    bufferedCh := make(chan int, 3)
    
    bufferedCh <- 1
    bufferedCh <- 2
    bufferedCh <- 3
    // bufferedCh <- 4  // 阻塞，缓冲区满
    
    fmt.Println("Buffered:", <-bufferedCh)
    fmt.Println("Buffered:", <-bufferedCh)
    
    // 关闭 channel
    close(bufferedCh)
    
    // 从关闭的 channel 读取
    val, ok := <-bufferedCh
    fmt.Printf("Value: %d, Open: %v\n", val, ok)
    
    val, ok = <-bufferedCh  // 返回零值和 false
    fmt.Printf("Value: %d, Open: %v\n", val, ok)
    
    // range 遍历 channel
    ch2 := make(chan int, 3)
    ch2 <- 1
    ch2 <- 2
    ch2 <- 3
    close(ch2)
    
    for v := range ch2 {
        fmt.Println("Range:", v)
    }
}
```

#### 🔬 深度解析：Channel 底层实现

```go
// Channel 的内部结构（简化版）
type hchan struct {
    qcount   uint           // 缓冲区中元素数量
    dataqsiz uint           // 缓冲区大小
    buf      unsafe.Pointer // 缓冲区指针
    elemsize uint16         // 元素大小
    closed   uint32         // 是否关闭
    elemtype *_type         // 元素类型
    sendx    uint           // 发送索引
    recvx    uint           // 接收索引
    recvq    waitq          // 接收等待队列
    sendq    waitq          // 发送等待队列
    lock     mutex          // 互斥锁
}
```

**Channel 操作的内部流程：**

```
发送操作 (ch <- x):
┌─────────────────────────────────────────────────────────────────┐
│  1. 获取 channel 锁                                               │
│  2. 检查 channel 是否关闭                                         │
│  3. 如果有等待的接收者 → 直接发送给接收者                           │
│  4. 如果缓冲区未满 → 放入缓冲区                                    │
│  5. 否则 → 将当前 G 加入发送队列，阻塞                             │
│  6. 释放锁                                                        │
└─────────────────────────────────────────────────────────────────┘

接收操作 (<-ch):
┌─────────────────────────────────────────────────────────────────┐
│  1. 获取 channel 锁                                               │
│  2. 如果有等待的发送者 → 直接从发送者接收                           │
│  3. 如果缓冲区非空 → 从缓冲区取出                                  │
│  4. 如果 channel 已关闭且缓冲区空 → 返回零值                        │
│  5. 否则 → 将当前 G 加入接收队列，阻塞                             │
│  6. 释放锁                                                        │
└─────────────────────────────────────────────────────────────────┘
```

##### 无缓冲 vs 有缓冲 Channel

```go
package main

import (
    "fmt"
    "time"
)

func main() {
    // 无缓冲 channel：同步传递
    // 发送和接收必须同时准备好
    unbuffered := make(chan int)
    
    go func() {
        fmt.Println("Sender: waiting to send")
        unbuffered <- 1  // 阻塞直到有人接收
        fmt.Println("Sender: sent")
    }()
    
    time.Sleep(100 * time.Millisecond)
    fmt.Println("Receiver: waiting to receive")
    <-unbuffered  // 阻塞直到有人发送
    fmt.Println("Receiver: received")
    
    // 有缓冲 channel：异步传递
    // 缓冲区未满时发送不阻塞
    buffered := make(chan int, 2)
    
    buffered <- 1  // 不阻塞
    buffered <- 2  // 不阻塞
    // buffered <- 3  // 阻塞，缓冲区满
    
    fmt.Println(<-buffered)
    fmt.Println(<-buffered)
}
```

**性能对比：**

```go
package main

import (
    "fmt"
    "sync"
    "time"
)

func benchmarkUnbuffered(n int) time.Duration {
    ch := make(chan int)
    var wg sync.WaitGroup
    wg.Add(2)
    
    start := time.Now()
    
    go func() {
        defer wg.Done()
        for i := 0; i < n; i++ {
            ch <- i
        }
        close(ch)
    }()
    
    go func() {
        defer wg.Done()
        for range ch {
        }
    }()
    
    wg.Wait()
    return time.Since(start)
}

func benchmarkBuffered(n int, bufferSize int) time.Duration {
    ch := make(chan int, bufferSize)
    var wg sync.WaitGroup
    wg.Add(2)
    
    start := time.Now()
    
    go func() {
        defer wg.Done()
        for i := 0; i < n; i++ {
            ch <- i
        }
        close(ch)
    }()
    
    go func() {
        defer wg.Done()
        for range ch {
        }
    }()
    
    wg.Wait()
    return time.Since(start)
}

func main() {
    n := 1000000
    
    fmt.Printf("Unbuffered: %v\n", benchmarkUnbuffered(n))
    fmt.Printf("Buffered(1): %v\n", benchmarkBuffered(n, 1))
    fmt.Printf("Buffered(100): %v\n", benchmarkBuffered(n, 100))
    fmt.Printf("Buffered(1000): %v\n", benchmarkBuffered(n, 1000))
}
```

> **💡 新手提示**：
> - 无缓冲 channel 用于同步：确保发送和接收"握手"
> - 有缓冲 channel 用于解耦：生产者和消费者可以不同步
> - 缓冲区大小不是越大越好，过大会增加内存占用和 GC 压力

> **🎓 专家视角**：Channel 的性能瓶颈在于锁竞争。在高并发场景下，可以考虑以下优化：
> 1. 使用更大的缓冲区减少阻塞
> 2. 使用多个 channel 分片（类似分片锁）
> 3. 在极端性能场景下，考虑使用 sync 包的无锁结构
```

### 3.2 Channel 方向

```go
package main

import "fmt"

// 只发送 channel
func sender(ch chan<- int) {
    for i := 0; i < 5; i++ {
        ch <- i
    }
    close(ch)
}

// 只接收 channel
func receiver(ch <-chan int) {
    for v := range ch {
        fmt.Println("Received:", v)
    }
}

// 双向 channel
func pipeline(in <-chan int, out chan<- int) {
    for v := range in {
        out <- v * 2
    }
    close(out)
}

func main() {
    ch := make(chan int)
    
    go sender(ch)
    receiver(ch)
    
    // Pipeline 模式
    in := make(chan int, 5)
    out := make(chan int, 5)
    
    go func() {
        for i := 0; i < 5; i++ {
            in <- i
        }
        close(in)
    }()
    
    go pipeline(in, out)
    
    for v := range out {
        fmt.Println("Pipeline output:", v)
    }
}
```

### 3.3 Select 多路复用

```go
package main

import (
    "fmt"
    "time"
)

func main() {
    ch1 := make(chan string)
    ch2 := make(chan string)
    
    go func() {
        time.Sleep(100 * time.Millisecond)
        ch1 <- "from ch1"
    }()
    
    go func() {
        time.Sleep(200 * time.Millisecond)
        ch2 <- "from ch2"
    }()
    
    // select 等待多个 channel
    for i := 0; i < 2; i++ {
        select {
        case msg1 := <-ch1:
            fmt.Println("Received:", msg1)
        case msg2 := <-ch2:
            fmt.Println("Received:", msg2)
        }
    }
    
    // 带超时的 select
    select {
    case msg := <-ch1:
        fmt.Println(msg)
    case <-time.After(50 * time.Millisecond):
        fmt.Println("Timeout!")
    }
    
    // 非阻塞 select
    select {
    case msg := <-ch1:
        fmt.Println(msg)
    default:
        fmt.Println("No message available")
    }
    
    // 检查 channel 是否关闭
    select {
    case v, ok := <-ch1:
        if !ok {
            fmt.Println("ch1 is closed")
        } else {
            fmt.Println("ch1:", v)
        }
    default:
        fmt.Println("No value from ch1")
    }
}
```

---

## 4. Context

### 4.1 Context 基础

```go
package main

import (
    "context"
    "fmt"
    "time"
)

func main() {
    // Background: 根 context
    ctx := context.Background()
    
    // TODO: 占位 context
    ctx2 := context.TODO()
    
    // WithValue: 携带值
    ctxWithValue := context.WithValue(ctx, "userID", 123)
    fmt.Println("UserID:", ctxWithValue.Value("userID"))
    
    // WithCancel: 手动取消
    ctxCancel, cancel := context.WithCancel(ctx)
    go func() {
        time.Sleep(100 * time.Millisecond)
        cancel()  // 取消
    }()
    
    <-ctxCancel.Done()
    fmt.Println("Context cancelled:", ctxCancel.Err())
    
    // WithTimeout: 超时取消
    ctxTimeout, cancel2 := context.WithTimeout(ctx, 200*time.Millisecond)
    defer cancel2()
    
    select {
    case <-ctxTimeout.Done():
        fmt.Println("Timeout:", ctxTimeout.Err())
    }
    
    // WithDeadline: 截止时间
    deadline := time.Now().Add(300 * time.Millisecond)
    ctxDeadline, cancel3 := context.WithDeadline(ctx, deadline)
    defer cancel3()
    
    <-ctxDeadline.Done()
    fmt.Println("Deadline reached:", ctxDeadline.Err())
}
```

### 4.2 Context 在 HTTP 请求中的应用

```go
package main

import (
    "context"
    "fmt"
    "net/http"
    "time"
)

func main() {
    http.HandleFunc("/slow", func(w http.ResponseWriter, r *http.Request) {
        ctx := r.Context()
        
        select {
        case <-time.After(5 * time.Second):
            fmt.Fprintf(w, "Request completed")
        case <-ctx.Done():
            fmt.Println("Request cancelled:", ctx.Err())
            http.Error(w, "Request cancelled", http.StatusRequestTimeout)
        }
    })
    
    http.HandleFunc("/with-timeout", func(w http.ResponseWriter, r *http.Request) {
        ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
        defer cancel()
        
        result, err := slowOperation(ctx)
        if err != nil {
            http.Error(w, err.Error(), http.StatusInternalServerError)
            return
        }
        
        fmt.Fprintf(w, "Result: %s", result)
    })
    
    http.ListenAndServe(":8080", nil)
}

func slowOperation(ctx context.Context) (string, error) {
    select {
    case <-time.After(3 * time.Second):
        return "done", nil
    case <-ctx.Done():
        return "", ctx.Err()
    }
}
```

---

## 5. 同步原语

### 5.1 Mutex 与 RWMutex

```go
package main

import (
    "fmt"
    "sync"
)

type SafeCounter struct {
    mu    sync.RWMutex
    count int
}

func (c *SafeCounter) Increment() {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.count++
}

func (c *SafeCounter) Decrement() {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.count--
}

func (c *SafeCounter) Value() int {
    c.mu.RLock()
    defer c.mu.RUnlock()
    return c.count
}

func main() {
    counter := SafeCounter{}
    var wg sync.WaitGroup
    
    for i := 0; i < 1000; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            counter.Increment()
        }()
    }
    
    for i := 0; i < 500; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            counter.Decrement()
        }()
    }
    
    wg.Wait()
    fmt.Println("Final count:", counter.Value())
}
```

### 5.2 WaitGroup 与 Once

```go
package main

import (
    "fmt"
    "sync"
)

func main() {
    // WaitGroup: 等待一组 goroutine
    var wg sync.WaitGroup
    
    for i := 0; i < 5; i++ {
        wg.Add(1)
        go func(n int) {
            defer wg.Done()
            fmt.Printf("Worker %d done\n", n)
        }(i)
    }
    
    wg.Wait()
    fmt.Println("All workers completed")
    
    // Once: 只执行一次
    var once sync.Once
    
    for i := 0; i < 5; i++ {
        once.Do(func() {
            fmt.Println("This will only print once")
        })
    }
    
    // 单例模式
    var instance *Singleton
    var onceInstance sync.Once
    
    getInstance := func() *Singleton {
        onceInstance.Do(func() {
            instance = &Singleton{name: "singleton"}
        })
        return instance
    }
    
    fmt.Println(getInstance())
    fmt.Println(getInstance())
}

type Singleton struct {
    name string
}
```

### 5.3 Cond 与 Pool

```go
package main

import (
    "fmt"
    "sync"
    "time"
)

func main() {
    // Cond: 条件变量
    var mu sync.Mutex
    cond := sync.NewCond(&mu)
    ready := false
    
    go func() {
        time.Sleep(100 * time.Millisecond)
        mu.Lock()
        ready = true
        cond.Broadcast()  // 或 cond.Signal()
        mu.Unlock()
    }()
    
    mu.Lock()
    for !ready {
        cond.Wait()
    }
    mu.Unlock()
    fmt.Println("Condition met!")
    
    // Pool: 对象池
    pool := &sync.Pool{
        New: func() interface{} {
            fmt.Println("Creating new object")
            return &Object{id: time.Now().UnixNano()}
        },
    }
    
    obj1 := pool.Get().(*Object)
    fmt.Println("Got object:", obj1.id)
    pool.Put(obj1)
    
    obj2 := pool.Get().(*Object)
    fmt.Println("Got object again:", obj2.id)
}

type Object struct {
    id int64
}
```

---

## 6. 并发模式

### 6.1 Worker Pool

```go
package main

import (
    "fmt"
    "sync"
    "time"
)

type Job struct {
    ID   int
    Data string
}

type Result struct {
    Job    Job
    Result string
}

func worker(id int, jobs <-chan Job, results chan<- Result, wg *sync.WaitGroup) {
    defer wg.Done()
    for job := range jobs {
        fmt.Printf("Worker %d processing job %d\n", id, job.ID)
        time.Sleep(100 * time.Millisecond)
        results <- Result{Job: job, Result: fmt.Sprintf("processed-%s", job.Data)}
    }
}

func main() {
    const numWorkers = 3
    const numJobs = 10
    
    jobs := make(chan Job, numJobs)
    results := make(chan Result, numJobs)
    
    var wg sync.WaitGroup
    
    // 启动 workers
    for w := 1; w <= numWorkers; w++ {
        wg.Add(1)
        go worker(w, jobs, results, &wg)
    }
    
    // 发送任务
    for j := 1; j <= numJobs; j++ {
        jobs <- Job{ID: j, Data: fmt.Sprintf("data-%d", j)}
    }
    close(jobs)
    
    // 等待完成
    go func() {
        wg.Wait()
        close(results)
    }()
    
    // 收集结果
    for result := range results {
        fmt.Printf("Result: job %d -> %s\n", result.Job.ID, result.Result)
    }
}
```

### 6.2 Pipeline

```go
package main

import "fmt"

func generator(nums ...int) <-chan int {
    out := make(chan int)
    go func() {
        for _, n := range nums {
            out <- n
        }
        close(out)
    }()
    return out
}

func square(in <-chan int) <-chan int {
    out := make(chan int)
    go func() {
        for n := range in {
            out <- n * n
        }
        close(out)
    }()
    return out
}

func filter(in <-chan int, predicate func(int) bool) <-chan int {
    out := make(chan int)
    go func() {
        for n := range in {
            if predicate(n) {
                out <- n
            }
        }
        close(out)
    }()
    return out
}

func main() {
    // Pipeline: generator -> square -> filter
    nums := generator(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
    squared := square(nums)
    evens := filter(squared, func(n int) bool { return n%2 == 0 })
    
    for n := range evens {
        fmt.Println(n)
    }
}
```

### 6.3 Fan-out/Fan-in

```go
package main

import (
    "fmt"
    "sync"
)

func producer(nums ...int) <-chan int {
    out := make(chan int)
    go func() {
        for _, n := range nums {
            out <- n
        }
        close(out)
    }()
    return out
}

func squareWorker(in <-chan int, wg *sync.WaitGroup) <-chan int {
    out := make(chan int)
    go func() {
        defer wg.Done()
        for n := range in {
            out <- n * n
        }
        close(out)
    }()
    return out
}

func merge(channels ...<-chan int) <-chan int {
    out := make(chan int)
    var wg sync.WaitGroup
    
    for _, ch := range channels {
        wg.Add(1)
        go func(c <-chan int) {
            defer wg.Done()
            for n := range c {
                out <- n
            }
        }(ch)
    }
    
    go func() {
        wg.Wait()
        close(out)
    }()
    
    return out
}

func main() {
    // Fan-out: 多个 worker 处理同一个输入
    input := producer(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
    
    var wg sync.WaitGroup
    numWorkers := 3
    
    // 创建多个 worker
    workers := make([]<-chan int, numWorkers)
    for i := 0; i < numWorkers; i++ {
        wg.Add(1)
        workers[i] = squareWorker(input, &wg)
    }
    
    // Fan-in: 合并多个 worker 的输出
    output := merge(workers...)
    
    for n := range output {
        fmt.Println(n)
    }
}
```

### 6.4 Graceful Shutdown

```go
package main

import (
    "context"
    "fmt"
    "os"
    "os/signal"
    "syscall"
    "time"
)

func main() {
    ctx, cancel := context.WithCancel(context.Background())
    defer cancel()
    
    // 监听系统信号
    sigCh := make(chan os.Signal, 1)
    signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)
    
    // 启动 worker
    go worker(ctx, 1)
    go worker(ctx, 2)
    go worker(ctx, 3)
    
    // 等待信号
    sig := <-sigCh
    fmt.Printf("\nReceived signal: %v\n", sig)
    
    // 发送取消信号
    cancel()
    
    // 等待一段时间让 worker 完成清理
    time.Sleep(time.Second)
    fmt.Println("Graceful shutdown complete")
}

func worker(ctx context.Context, id int) {
    for {
        select {
        case <-ctx.Done():
            fmt.Printf("Worker %d: shutting down...\n", id)
            return
        default:
            fmt.Printf("Worker %d: working...\n", id)
            time.Sleep(500 * time.Millisecond)
        }
    }
}
```

---

## 7. 并发陷阱

> **🎯 核心概念**：并发编程中最难的不是写出正确的代码，而是避免隐蔽的并发陷阱。理解这些陷阱的根源和解决方案，是成为并发编程专家的必经之路。

### 7.1 数据竞争

```go
package main

import (
    "fmt"
    "sync"
)

// 错误示例：数据竞争
func dataRace() {
    var counter int
    var wg sync.WaitGroup
    
    for i := 0; i < 1000; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            counter++  // 数据竞争！
        }()
    }
    
    wg.Wait()
    fmt.Println("Counter (race):", counter)  // 结果不确定
}

// 正确示例：使用 Mutex
func noDataRace() {
    var counter int
    var mu sync.Mutex
    var wg sync.WaitGroup
    
    for i := 0; i < 1000; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            mu.Lock()
            counter++
            mu.Unlock()
        }()
    }
    
    wg.Wait()
    fmt.Println("Counter (safe):", counter)  // 结果确定
}

// 使用 atomic
func atomicCounter() {
    var counter int64
    var wg sync.WaitGroup
    
    for i := 0; i < 1000; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            // atomic.AddInt64(&counter, 1)
        }()
    }
    
    wg.Wait()
    fmt.Println("Counter (atomic):", counter)
}

func main() {
    dataRace()
    noDataRace()
    atomicCounter()
}
```

#### 🔬 深度解析：数据竞争的本质

**什么是数据竞争？**

数据竞争发生在两个或多个 goroutine 同时访问同一内存，且至少有一个是写操作，且没有同步机制。

```
┌─────────────────────────────────────────────────────────────────┐
│  数据竞争的内存视图                                               │
└─────────────────────────────────────────────────────────────────┘

Goroutine 1:                    Goroutine 2:
counter++                       counter++
├── 读取 counter (0)            ├── 读取 counter (0)
├── 加 1 (1)                    ├── 加 1 (1)
└── 写入 counter (1)            └── 写入 counter (1)

结果：counter = 1（期望是 2）
```

**使用 race detector 检测：**

```bash
# 编译时检测
go build -race main.go
./main

# 运行时检测
go run -race main.go

# 测试时检测
go test -race ./...
```

**Race detector 输出示例：**

```
==================
WARNING: DATA RACE
Write at 0x00c0000b4008 by goroutine 8:
  main.dataRace.func1()
      /path/main.go:15 +0x6e

Previous read at 0x00c0000b4008 by goroutine 7:
  main.dataRace.func1()
      /path/main.go:15 +0x4a

Goroutine 8 (running) created at:
  main.dataRace()
      /path/main.go:13 +0x9a
==================
```

##### 常见数据竞争场景

```go
package main

import (
    "fmt"
    "sync"
)

// 场景1：循环变量捕获
func loopVariableRace() {
    var wg sync.WaitGroup
    for i := 0; i < 5; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            fmt.Println(i)  // 数据竞争！所有 goroutine 可能打印 5
        }()
    }
    wg.Wait()
}

// 修复：传递参数
func loopVariableFixed() {
    var wg sync.WaitGroup
    for i := 0; i < 5; i++ {
        wg.Add(1)
        go func(n int) {  // 捕获参数
            defer wg.Done()
            fmt.Println(n)
        }(i)  // 传递 i
    }
    wg.Wait()
}

// 场景2：共享切片
func sliceRace() {
    var wg sync.WaitGroup
    results := make([]int, 10)
    
    for i := 0; i < 10; i++ {
        wg.Add(1)
        go func(idx int) {
            defer wg.Done()
            results[idx] = idx * 2  // 数据竞争！
        }(i)
    }
    wg.Wait()
}

// 修复：使用 channel 收集结果
func sliceFixed() {
    var wg sync.WaitGroup
    results := make(chan int, 10)
    
    for i := 0; i < 10; i++ {
        wg.Add(1)
        go func(idx int) {
            defer wg.Done()
            results <- idx * 2
        }(i)
    }
    
    go func() {
        wg.Wait()
        close(results)
    }()
    
    for r := range results {
        fmt.Println(r)
    }
}

// 场景3：Map 并发读写
func mapRace() {
    m := make(map[int]int)
    var wg sync.WaitGroup
    
    for i := 0; i < 10; i++ {
        wg.Add(1)
        go func(k int) {
            defer wg.Done()
            m[k] = k  // panic: concurrent map writes
        }(i)
    }
    wg.Wait()
}

// 修复：使用 sync.Map 或加锁
func mapFixed() {
    var m sync.Map
    var wg sync.WaitGroup
    
    for i := 0; i < 10; i++ {
        wg.Add(1)
        go func(k int) {
            defer wg.Done()
            m.Store(k, k)
        }(i)
    }
    wg.Wait()
    
    m.Range(func(key, value interface{}) bool {
        fmt.Println(key, value)
        return true
    })
}

func main() {
    fmt.Println("=== Loop Variable ===")
    loopVariableFixed()
    
    fmt.Println("\n=== Slice ===")
    sliceFixed()
    
    fmt.Println("\n=== Map ===")
    mapFixed()
}
```

> **💡 新手提示**：
> - 永远使用 `-race` 标志运行测试
> - 循环变量必须作为参数传递给 goroutine
> - Map 不是并发安全的，使用 `sync.Map` 或加锁

> **🎓 专家视角**：数据竞争的本质是内存可见性问题。即使没有数据竞争，不同 goroutine 对同一变量的修改也可能不可见（CPU 缓存）。Go 的内存模型保证：
> - 在 channel 发送前发生的写入，在接收后对接收者可见
> - 在 Mutex 解锁前发生的写入，在下次加锁后对加锁者可见
> - 在 WaitGroup.Done() 前发生的写入，在 Wait() 返回后可见
```

### 7.2 死锁

```go
package main

import (
    "fmt"
    "sync"
    "time"
)

// 死锁示例
func deadlock() {
    var mu1, mu2 sync.Mutex
    
    go func() {
        mu1.Lock()
        time.Sleep(100 * time.Millisecond)
        mu2.Lock()  // 死锁！
        mu2.Unlock()
        mu1.Unlock()
    }()
    
    mu2.Lock()
    time.Sleep(100 * time.Millisecond)
    mu1.Lock()  // 死锁！
    mu1.Unlock()
    mu2.Unlock()
    
    fmt.Println("This will never print")
}

// 避免死锁：统一锁顺序
func noDeadlock() {
    var mu1, mu2 sync.Mutex
    
    go func() {
        mu1.Lock()
        defer mu1.Unlock()
        time.Sleep(100 * time.Millisecond)
        mu2.Lock()
        defer mu2.Unlock()
    }()
    
    mu1.Lock()
    defer mu1.Unlock()
    time.Sleep(100 * time.Millisecond)
    mu2.Lock()
    defer mu2.Unlock()
    
    fmt.Println("No deadlock!")
}

// 使用 trylock 检测（Go 1.18+）
func tryLock() {
    var mu sync.Mutex
    mu.Lock()
    
    if mu.TryLock() {
        fmt.Println("Got lock")
        mu.Unlock()
    } else {
        fmt.Println("Lock already held")
    }
    
    mu.Unlock()
}

func main() {
    // deadlock()  // 会卡住
    noDeadlock()
    tryLock()
}
```

#### 🔬 深度解析：死锁的四个必要条件

死锁发生需要同时满足四个条件（Coffman 条件）：

```
┌─────────────────────────────────────────────────────────────────┐
│  死锁的四个必要条件                                               │
└─────────────────────────────────────────────────────────────────┘

1. 互斥条件 (Mutual Exclusion)
   └── 资源一次只能被一个进程使用

2. 持有并等待 (Hold and Wait)
   └── 进程持有资源同时等待其他资源

3. 不可抢占 (No Preemption)
   └── 已分配的资源不能被强制抢占

4. 循环等待 (Circular Wait)
   └── 存在进程资源的循环等待链

破坏任意一个条件即可避免死锁！
```

##### 死锁检测与预防

```go
package main

import (
    "context"
    "fmt"
    "sync"
    "time"
)

// 策略1：统一锁顺序（破坏循环等待）
type BankAccount struct {
    id      int
    balance int
    mu      sync.Mutex
}

func transfer(a1, a2 *BankAccount, amount int) error {
    // 按账户 ID 排序加锁，确保全局一致
    if a1.id < a2.id {
        a1.mu.Lock()
        defer a1.mu.Unlock()
        a2.mu.Lock()
        defer a2.mu.Unlock()
    } else {
        a2.mu.Lock()
        defer a2.mu.Unlock()
        a1.mu.Lock()
        defer a1.mu.Unlock()
    }
    
    if a1.balance < amount {
        return fmt.Errorf("insufficient funds")
    }
    a1.balance -= amount
    a2.balance += amount
    return nil
}

// 策略2：超时机制（破坏不可抢占）
func transferWithTimeout(a1, a2 *BankAccount, amount int, timeout time.Duration) error {
    ctx, cancel := context.WithTimeout(context.Background(), timeout)
    defer cancel()
    
    done := make(chan error, 1)
    
    go func() {
        a1.mu.Lock()
        defer a1.mu.Unlock()
        
        select {
        case <-ctx.Done():
            return
        default:
        }
        
        a2.mu.Lock()
        defer a2.mu.Unlock()
        
        if a1.balance < amount {
            done <- fmt.Errorf("insufficient funds")
            return
        }
        a1.balance -= amount
        a2.balance += amount
        done <- nil
    }()
    
    select {
    case err := <-done:
        return err
    case <-ctx.Done():
        return fmt.Errorf("transfer timeout")
    }
}

// 策略3：TryLock（Go 1.18+）
func transferTryLock(a1, a2 *BankAccount, amount int) error {
    // 尝试获取第一个锁
    if !a1.mu.TryLock() {
        return fmt.Errorf("account %d is busy", a1.id)
    }
    defer a1.mu.Unlock()
    
    // 尝试获取第二个锁
    if !a2.mu.TryLock() {
        return fmt.Errorf("account %d is busy", a2.id)
    }
    defer a2.mu.Unlock()
    
    if a1.balance < amount {
        return fmt.Errorf("insufficient funds")
    }
    a1.balance -= amount
    a2.balance += amount
    return nil
}

// 策略4：使用单一锁（简单但性能低）
type Bank struct {
    accounts map[int]*BankAccount
    mu       sync.RWMutex
}

func (b *Bank) transfer(from, to, amount int) error {
    b.mu.Lock()
    defer b.mu.Unlock()
    
    a1, ok1 := b.accounts[from]
    a2, ok2 := b.accounts[to]
    if !ok1 || !ok2 {
        return fmt.Errorf("account not found")
    }
    
    if a1.balance < amount {
        return fmt.Errorf("insufficient funds")
    }
    a1.balance -= amount
    a2.balance += amount
    return nil
}

func main() {
    acc1 := &BankAccount{id: 1, balance: 1000}
    acc2 := &BankAccount{id: 2, balance: 500}
    
    // 测试转账
    if err := transfer(acc1, acc2, 100); err != nil {
        fmt.Println("Transfer failed:", err)
    } else {
        fmt.Println("Transfer successful")
    }
    
    fmt.Printf("Account 1: %d, Account 2: %d\n", acc1.balance, acc2.balance)
}
```

##### Channel 死锁

```go
package main

import (
    "fmt"
    "time"
)

// Channel 死锁场景
func channelDeadlock() {
    ch := make(chan int)
    ch <- 1  // 死锁！没有接收者
    fmt.Println(<-ch)
}

// 无缓冲 channel 死锁
func unbufferedDeadlock() {
    ch := make(chan int)
    
    go func() {
        ch <- 1  // 等待接收
    }()
    
    // 如果这里没有接收，goroutine 会永远阻塞
}

// 修复：使用有缓冲 channel
func bufferedFix() {
    ch := make(chan int, 1)
    ch <- 1  // 不阻塞
    fmt.Println(<-ch)
}

// 修复：使用 select + default
func selectFix() {
    ch := make(chan int)
    
    select {
    case ch <- 1:
        fmt.Println("Sent")
    default:
        fmt.Println("Channel blocked, skipped")
    }
}

// 修复：使用 context 超时
func contextFix() {
    ch := make(chan int)
    
    go func() {
        time.Sleep(100 * time.Millisecond)
        ch <- 1
    }()
    
    select {
    case v := <-ch:
        fmt.Println("Received:", v)
    case <-time.After(50 * time.Millisecond):
        fmt.Println("Timeout")
    }
}

func main() {
    // channelDeadlock()  // 会死锁
    bufferedFix()
    selectFix()
    contextFix()
}
```

> **💡 新手提示**：
> - 永远不要在不知道如何退出的情况下启动 goroutine
> - 无缓冲 channel 需要接收者准备好才能发送
> - 使用 select + default 避免永久阻塞

> **🎓 专家视角**：死锁检测工具：
> - `go run -race` 可以检测部分死锁
> - 使用 `pprof` 查看 goroutine 堆栈：`curl http://localhost:6060/debug/pprof/goroutine?debug=1`
> - 使用 `gops` 查看进程状态：`gops stack <pid>`
> - 生产环境可以使用 deadlock 检测库：`github.com/sasha-s/go-deadlock`
```

### 7.3 Goroutine 泄漏

```go
package main

import (
    "context"
    "fmt"
    "runtime"
    "time"
)

// 泄漏的 goroutine
func leakyGoroutine() {
    ch := make(chan int)
    
    go func() {
        <-ch  // 永远阻塞，因为没人发送
        fmt.Println("Never reached")
    }()
}

// 正确做法：使用 context
func fixedGoroutine() {
    ctx, cancel := context.WithTimeout(context.Background(), time.Second)
    defer cancel()
    
    ch := make(chan int)
    
    go func() {
        select {
        case <-ch:
            fmt.Println("Received")
        case <-ctx.Done():
            fmt.Println("Timeout, exiting")
        }
    }()
}

func main() {
    leakyGoroutine()
    fixedGoroutine()
    
    time.Sleep(2 * time.Second)
    fmt.Printf("Goroutines: %d\n", runtime.NumGoroutine())
}
```

#### 🔬 深度解析：Goroutine 泄漏的原因与检测

**Goroutine 泄漏的常见原因：**

```
┌─────────────────────────────────────────────────────────────────┐
│  Goroutine 泄漏的常见原因                                         │
└─────────────────────────────────────────────────────────────────┘

1. Channel 阻塞
   ├── 向无缓冲 channel 发送但无接收者
   ├── 从 channel 接收但无发送者
   └── channel 未关闭导致 range 永不退出

2. 锁阻塞
   ├── 尝试获取已被持有的锁
   └── 死锁导致 goroutine 永远等待

3. 无限循环
   ├── 忘记检查退出条件
   └── 没有响应 context 取消

4. 等待外部事件
   ├── 等待永远不会到来的事件
   └── 依赖的服务不可用
```

##### 泄漏检测工具

```go
package main

import (
    "context"
    "fmt"
    "net/http"
    _ "net/http/pprof"
    "runtime"
    "time"
)

func main() {
    // 启动 pprof 服务
    go func() {
        http.ListenAndServe("localhost:6060", nil)
    }()
    
    // 模拟 goroutine 泄漏
    for i := 0; i < 10; i++ {
        go leakyWorker(i)
    }
    
    // 定期打印 goroutine 数量
    ticker := time.NewTicker(time.Second)
    for i := 0; i < 10; i++ {
        <-ticker.C
        fmt.Printf("Goroutines: %d\n", runtime.NumGoroutine())
    }
}

func leakyWorker(id int) {
    ch := make(chan int)
    <-ch  // 永远阻塞
}
```

**使用 pprof 分析：**

```bash
# 查看 goroutine 堆栈
curl http://localhost:6060/debug/pprof/goroutine?debug=1

# 保存 goroutine profile
curl http://localhost:6060/debug/pprof/goroutine -o goroutine.out

# 使用 go tool pprof 分析
go tool pprof -http=:8080 goroutine.out
```

##### 使用 goleak 检测

```go
package main

import (
    "testing"
    
    "go.uber.org/goleak"
)

func TestMain(m *testing.M) {
    goleak.VerifyTestMain(m)
}

func TestNoLeak(t *testing.T) {
    // 如果这个测试导致 goroutine 泄漏，goleak 会报错
    doSomething()
}
```

##### 常见泄漏模式与修复

```go
package main

import (
    "context"
    "fmt"
    "sync"
    "time"
)

// 泄漏模式1：忘记关闭 channel
func leakPattern1() {
    ch := make(chan int)
    
    go func() {
        for v := range ch {  // 永远不会退出
            fmt.Println(v)
        }
    }()
    
    ch <- 1
    ch <- 2
    // 忘记 close(ch)
}

// 修复：确保关闭 channel
func fixedPattern1() {
    ch := make(chan int)
    
    go func() {
        for v := range ch {
            fmt.Println(v)
        }
    }()
    
    ch <- 1
    ch <- 2
    close(ch)  // 关闭 channel
}

// 泄漏模式2：无限循环无退出条件
func leakPattern2() {
    go func() {
        for {
            doWork()  // 永远运行
        }
    }()
}

// 修复：检查退出条件
func fixedPattern2(ctx context.Context) {
    go func() {
        for {
            select {
            case <-ctx.Done():
                return
            default:
                doWork()
            }
        }
    }()
}

// 泄漏模式3：select 忘记处理 context
func leakPattern3() {
    ch := make(chan int)
    
    go func() {
        select {
        case v := <-ch:
            fmt.Println(v)
        // 忘记 case <-ctx.Done()
        }
    }()
}

// 修复：总是处理 context
func fixedPattern3(ctx context.Context) {
    ch := make(chan int)
    
    go func() {
        select {
        case v := <-ch:
            fmt.Println(v)
        case <-ctx.Done():
            return
        }
    }()
}

// 泄漏模式4：WaitGroup 使用错误
func leakPattern4() {
    var wg sync.WaitGroup
    
    for i := 0; i < 10; i++ {
        go func() {
            wg.Add(1)  // 错误：在 goroutine 内部 Add
            defer wg.Done()
            doWork()
        }()
    }
    
    wg.Wait()  // 可能永远不会完成
}

// 修复：在启动 goroutine 前调用 Add
func fixedPattern4() {
    var wg sync.WaitGroup
    
    for i := 0; i < 10; i++ {
        wg.Add(1)  // 正确：在 goroutine 外部 Add
        go func() {
            defer wg.Done()
            doWork()
        }()
    }
    
    wg.Wait()
}

func doWork() {
    time.Sleep(100 * time.Millisecond)
}

func main() {
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()
    
    fixedPattern1()
    fixedPattern2(ctx)
    fixedPattern3(ctx)
    fixedPattern4()
    
    time.Sleep(time.Second)
}
```

> **💡 新手提示**：
> - 每个 goroutine 都应该有明确的退出机制
> - 使用 context 传递取消信号
> - 定期检查 goroutine 数量：`runtime.NumGoroutine()`

> **🎓 专家视角**：生产环境的 goroutine 泄漏检测策略：
> 1. **监控**：定期记录 goroutine 数量，设置告警阈值
> 2. **pprof**：集成 pprof，方便排查问题
> 3. **goleak**：在测试中集成 goleak，防止引入新的泄漏
> 4. **架构设计**：使用 worker pool 模式控制 goroutine 数量
> 5. **优雅关闭**：实现 graceful shutdown，确保所有 goroutine 正确退出
```

---

## 8. 总结

### 8.1 并发最佳实践

```
┌─────────────────────────────────────────────────────────────────┐
│  Go 并发最佳实践                                                  │
└─────────────────────────────────────────────────────────────────┘

1. 通过通信共享内存，而不是通过共享内存通信
   ├── 优先使用 channel
   └── 必要时使用 sync 原语

2. 永远不要在不知道如何停止的情况下启动 goroutine
   ├── 使用 context 控制生命周期
   └── 确保 goroutine 可以正常退出

3. 避免 goroutine 泄漏
   ├── 使用 defer + recover
   ├── 监控 goroutine 数量
   └── 使用 pprof 分析

4. 合理设置并发数
   ├── CPU 密集型：GOMAXPROCS
   ├── I/O 密集型：根据资源限制
   └── 使用 semaphore 控制并发

5. 错误处理
   ├── goroutine 中的错误要传递出来
   ├── 使用 errgroup 等待并收集错误
   └── 不要忽略 goroutine 中的 panic
```

### 8.2 工具推荐

```bash
# 检测数据竞争
go build -race main.go

# 查看 goroutine 数量
curl http://localhost:6060/debug/pprof/goroutine?debug=1

# 性能分析
go tool pprof http://localhost:6060/debug/pprof/profile

# goroutine 泄漏检测
# https://github.com/uber-go/goleak
```
