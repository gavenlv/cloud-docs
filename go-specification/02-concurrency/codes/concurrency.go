package main

import (
    "context"
    "fmt"
    "sync"
    "time"
)

func main() {
    fmt.Println("=== Go 并发编程示例 ===")
    
    // Goroutine
    fmt.Println("\n--- Goroutine ---")
    var wg sync.WaitGroup
    
    for i := 0; i < 5; i++ {
        wg.Add(1)
        go func(n int) {
            defer wg.Done()
            fmt.Printf("Worker %d\n", n)
        }(i)
    }
    wg.Wait()
    
    // Channel
    fmt.Println("\n--- Channel ---")
    ch := make(chan int, 3)
    
    go func() {
        for i := 0; i < 5; i++ {
            ch <- i
        }
        close(ch)
    }()
    
    for v := range ch {
        fmt.Println("Received:", v)
    }
    
    // Select
    fmt.Println("\n--- Select ---")
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
    
    for i := 0; i < 2; i++ {
        select {
        case msg := <-ch1:
            fmt.Println(msg)
        case msg := <-ch2:
            fmt.Println(msg)
        }
    }
    
    // Context
    fmt.Println("\n--- Context ---")
    ctx, cancel := context.WithTimeout(context.Background(), 500*time.Millisecond)
    defer cancel()
    
    go func() {
        time.Sleep(1 * time.Second)
        fmt.Println("This won't print")
    }()
    
    <-ctx.Done()
    fmt.Println("Context done:", ctx.Err())
    
    // Worker Pool
    fmt.Println("\n--- Worker Pool ---")
    jobs := make(chan int, 10)
    results := make(chan int, 10)
    
    for w := 1; w <= 3; w++ {
        go worker(w, jobs, results)
    }
    
    for j := 1; j <= 5; j++ {
        jobs <- j
    }
    close(jobs)
    
    for r := 0; r < 5; r++ {
        fmt.Println("Result:", <-results)
    }
}

func worker(id int, jobs <-chan int, results chan<- int) {
    for j := range jobs {
        fmt.Printf("Worker %d processing job %d\n", id, j)
        results <- j * 2
    }
}
