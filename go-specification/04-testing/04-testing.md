# Go 测试

> **🎯 核心概念**：测试是保证代码质量的关键。Go 内置的测试框架简洁而强大，理解其设计哲学和最佳实践，能让你写出可维护、可靠的测试代码。

## 1. 单元测试基础

> **🎯 核心概念**：单元测试是测试金字塔的基础，Go 的测试框架设计简洁，通过 `testing` 包提供核心功能。

### 1.1 基本测试

```go
package calculator

import "testing"

func Add(a, b int) int {
    return a + b
}

func Subtract(a, b int) int {
    return a - b
}

func Divide(a, b int) (int, error) {
    if b == 0 {
        return 0, fmt.Errorf("division by zero")
    }
    return a / b, nil
}

// 测试文件: calculator_test.go
// 测试函数以 Test 开头，参数为 *testing.T

func TestAdd(t *testing.T) {
    result := Add(2, 3)
    if result != 5 {
        t.Errorf("Add(2, 3) = %d; want 5", result)
    }
}

func TestSubtract(t *testing.T) {
    result := Subtract(5, 3)
    if result != 2 {
        t.Errorf("Subtract(5, 3) = %d; want 2", result)
    }
}

func TestDivide(t *testing.T) {
    // 正常情况
    result, err := Divide(10, 2)
    if err != nil {
        t.Errorf("Divide(10, 2) returned error: %v", err)
    }
    if result != 5 {
        t.Errorf("Divide(10, 2) = %d; want 5", result)
    }
    
    // 错误情况
    _, err = Divide(10, 0)
    if err == nil {
        t.Error("Divide(10, 0) should return error")
    }
}
```

#### 🔬 深度解析：Go 测试框架的设计哲学

```
┌─────────────────────────────────────────────────────────────────┐
│  Go 测试框架设计原则                                              │
└─────────────────────────────────────────────────────────────────┘

1. 内置而非第三方
   ├── go test 命令内置
   ├── testing 包是标准库
   └── 无需额外依赖

2. 约定优于配置
   ├── 文件名: *_test.go
   ├── 函数名: Test*, Benchmark*, Fuzz*
   └── 参数: *testing.T, *testing.B, *testing.F

3. 简单直接
   ├── 无断言库（使用 if 语句）
   ├── 无 setup/teardown 方法（使用普通函数）
   └── 无测试类（使用函数）

4. 可组合
   ├── t.Run() 子测试
   ├── t.Parallel() 并行测试
   └── t.Helper() 辅助函数
```

##### 测试函数的生命周期

```go
package main

import (
    "fmt"
    "os"
    "testing"
)

// TestMain: 测试入口（可选）
func TestMain(m *testing.M) {
    fmt.Println("=== Setup (before all tests) ===")
    
    // 运行测试
    code := m.Run()
    
    fmt.Println("=== Teardown (after all tests) ===")
    os.Exit(code)
}

func TestExample(t *testing.T) {
    t.Log("This is a test")
    
    t.Run("subtest1", func(t *testing.T) {
        t.Log("Subtest 1")
    })
    
    t.Run("subtest2", func(t *testing.T) {
        t.Log("Subtest 2")
    })
}

// Cleanup: 测试后清理（Go 1.14+）
func TestWithCleanup(t *testing.T) {
    // 注册清理函数
    t.Cleanup(func() {
        fmt.Println("Cleaning up...")
    })
    
    t.Log("Test body")
}
```

> **💡 新手提示**：
> - 测试文件必须以 `_test.go` 结尾
> - 测试函数必须以 `Test` 开头
> - 使用 `t.Log()`、`t.Error()`、`t.Fatal()` 报告结果
> - `t.Error()` 失败继续，`t.Fatal()` 失败立即停止

> **🎓 专家视角**：测试框架的高级用法：
> 1. **t.Helper()**：标记辅助函数，错误报告正确的行号
> 2. **t.TempDir()**：创建临时目录，自动清理
> 3. **t.Setenv()**：设置环境变量，测试后自动恢复
> 4. **t.Parallel()**：标记可并行执行的测试
```

### 1.2 表驱动测试

> **🎯 核心概念**：表驱动测试是 Go 社区推崇的测试模式，它将测试数据和测试逻辑分离，使测试更清晰、更易维护。

```go
package calculator

import "testing"

func TestAddTableDriven(t *testing.T) {
    tests := []struct {
        name     string
        a, b     int
        expected int
    }{
        {"positive numbers", 2, 3, 5},
        {"negative numbers", -2, -3, -5},
        {"mixed numbers", -2, 3, 1},
        {"zeros", 0, 0, 0},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := Add(tt.a, tt.b)
            if result != tt.expected {
                t.Errorf("Add(%d, %d) = %d; want %d",
                    tt.a, tt.b, result, tt.expected)
            }
        })
    }
}

func TestDivideTableDriven(t *testing.T) {
    tests := []struct {
        name      string
        a, b      int
        expected  int
        wantError bool
    }{
        {"normal division", 10, 2, 5, false},
        {"division by zero", 10, 0, 0, true},
        {"negative division", -10, 2, -5, false},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result, err := Divide(tt.a, tt.b)
            
            if tt.wantError {
                if err == nil {
                    t.Error("expected error but got nil")
                }
                return
            }
            
            if err != nil {
                t.Errorf("unexpected error: %v", err)
                return
            }
            
            if result != tt.expected {
                t.Errorf("Divide(%d, %d) = %d; want %d",
                    tt.a, tt.b, result, tt.expected)
            }
        })
    }
}
```

#### 🔬 深度解析：表驱动测试的优势

**为什么 Go 社区推崇表驱动测试？**

```
┌─────────────────────────────────────────────────────────────────┐
│  表驱动测试 vs 传统测试                                           │
└─────────────────────────────────────────────────────────────────┘

传统测试:
├── 每个测试场景一个函数
├── 大量重复代码
└── 难以添加新场景

表驱动测试:
├── 测试数据与逻辑分离
├── 易于添加新场景
├── 测试失败信息清晰
└── 支持子测试并行
```

##### 高级表驱动测试模式

```go
package advanced

import (
    "testing"
    "time"
)

type TestCase struct {
    name        string
    input       string
    expected    string
    wantError   bool
    skip        bool    // 跳过某些测试
    timeout     time.Duration
}

func TestAdvanced(t *testing.T) {
    tests := []TestCase{
        {
            name:     "basic case",
            input:    "hello",
            expected: "HELLO",
        },
        {
            name:      "error case",
            input:     "",
            wantError: true,
        },
        {
            name:  "skip case",
            input: "skip",
            skip:  true,  // 跳过这个测试
        },
        {
            name:    "timeout case",
            input:   "slow",
            timeout: 100 * time.Millisecond,
        },
    }
    
    for _, tt := range tests {
        tt := tt  // 捕获循环变量
        t.Run(tt.name, func(t *testing.T) {
            if tt.skip {
                t.Skip("skipping this test")
            }
            
            if tt.timeout > 0 {
                t.Parallel()  // 标记为可并行
            }
            
            result, err := Process(tt.input)
            
            if tt.wantError {
                if err == nil {
                    t.Error("expected error")
                }
                return
            }
            
            if err != nil {
                t.Errorf("unexpected error: %v", err)
                return
            }
            
            if result != tt.expected {
                t.Errorf("got %q, want %q", result, tt.expected)
            }
        })
    }
}

// 使用 map 组织测试数据
func TestWithMap(t *testing.T) {
    tests := map[string]struct {
        input    string
        expected int
    }{
        "one":   {"1", 1},
        "two":   {"2", 2},
        "three": {"3", 3},
    }
    
    for name, tt := range tests {
        t.Run(name, func(t *testing.T) {
            result := ParseInt(tt.input)
            if result != tt.expected {
                t.Errorf("got %d, want %d", result, tt.expected)
            }
        })
    }
}
```

> **💡 新手提示**：
> - 使用 `t.Run()` 创建子测试，失败信息更清晰
> - 循环中注意捕获变量：`tt := tt`
> - 测试名称要描述清楚场景和预期结果

> **🎓 专家视角**：表驱动测试的高级技巧：
> 1. **Golden Files**：对于复杂输出，使用 golden 文件存储预期结果
> 2. **Fixture**：将测试数据放在 `testdata/` 目录
> 3. **Builders**：使用 builder 模式构建复杂测试数据
> 4. **Property-based Testing**：结合 fuzzing 进行属性测试
```

---

## 2. 测试辅助工具

### 2.1 testify 库

```go
package calculator

import (
    "testing"
    
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
    "github.com/stretchr/testify/suite"
)

func TestAddWithAssert(t *testing.T) {
    // assert: 失败继续执行
    assert.Equal(t, 5, Add(2, 3), "should add correctly")
    assert.NotEqual(t, 6, Add(2, 3))
    
    // 多个断言
    assert.True(t, Add(1, 1) == 2)
    assert.False(t, Add(1, 1) == 3)
    
    // Nil/NotNil
    assert.Nil(t, nil)
    assert.NotNil(t, "value")
}

func TestDivideWithRequire(t *testing.T) {
    // require: 失败立即停止
    result, err := Divide(10, 2)
    require.NoError(t, err, "division should not fail")
    require.Equal(t, 5, result)
    
    _, err = Divide(10, 0)
    require.Error(t, err)
    require.Contains(t, err.Error(), "zero")
}

// 测试套件
type CalculatorSuite struct {
    suite.Suite
}

func (s *CalculatorSuite) SetupTest() {
    // 每个测试前执行
}

func (s *CalculatorSuite) TearDownTest() {
    // 每个测试后执行
}

func (s *CalculatorSuite) TestAdd() {
    s.Equal(5, Add(2, 3))
}

func (s *CalculatorSuite) TestSubtract() {
    s.Equal(2, Subtract(5, 3))
}

func TestCalculatorSuite(t *testing.T) {
    suite.Run(t, new(CalculatorSuite))
}
```

### 2.2 Mock 与 Stub

```go
package service

import (
    "testing"
    
    "github.com/stretchr/testify/mock"
)

// 接口定义
type UserRepository interface {
    FindByID(id int) (*User, error)
    Save(user *User) error
}

type User struct {
    ID   int
    Name string
}

type UserService struct {
    repo UserRepository
}

func (s *UserService) GetUser(id int) (*User, error) {
    return s.repo.FindByID(id)
}

// Mock 实现
type MockUserRepository struct {
    mock.Mock
}

func (m *MockUserRepository) FindByID(id int) (*User, error) {
    args := m.Called(id)
    if args.Get(0) == nil {
        return nil, args.Error(1)
    }
    return args.Get(0).(*User), args.Error(1)
}

func (m *MockUserRepository) Save(user *User) error {
    args := m.Called(user)
    return args.Error(0)
}

// 使用 Mock 测试
func TestGetUser(t *testing.T) {
    mockRepo := new(MockUserRepository)
    service := &UserService{repo: mockRepo}
    
    // 设置期望
    expectedUser := &User{ID: 1, Name: "Alice"}
    mockRepo.On("FindByID", 1).Return(expectedUser, nil)
    
    // 调用方法
    user, err := service.GetUser(1)
    
    // 断言
    assert.NoError(t, err)
    assert.Equal(t, expectedUser, user)
    
    // 验证期望被满足
    mockRepo.AssertExpectations(t)
}
```

---

## 3. 基准测试

### 3.1 基本基准测试

```go
package benchmark

import "testing"

func Fibonacci(n int) int {
    if n <= 1 {
        return n
    }
    return Fibonacci(n-1) + Fibonacci(n-2)
}

func BenchmarkFibonacci(b *testing.B) {
    for i := 0; i < b.N; i++ {
        Fibonacci(20)
    }
}

// 不同输入大小的基准测试
func BenchmarkFibonacciSizes(b *testing.B) {
    sizes := []int{10, 20, 30}
    for _, size := range sizes {
        b.Run(fmt.Sprintf("n=%d", size), func(b *testing.B) {
            for i := 0; i < b.N; i++ {
                Fibonacci(size)
            }
        })
    }
}

// 并行基准测试
func BenchmarkFibonacciParallel(b *testing.B) {
    b.RunParallel(func(pb *testing.PB) {
        for pb.Next() {
            Fibonacci(20)
        }
    })
}
```

### 3.2 内存分配分析

```go
package benchmark

import "testing"

func makeSlice(n int) []int {
    return make([]int, n)
}

func makeSliceWithCap(n int) []int {
    return make([]int, 0, n)
}

func BenchmarkMakeSlice(b *testing.B) {
    b.ReportAllocs()
    for i := 0; i < b.N; i++ {
        makeSlice(100)
    }
}

func BenchmarkMakeSliceWithCap(b *testing.B) {
    b.ReportAllocs()
    for i := 0; i < b.N; i++ {
        makeSliceWithCap(100)
    }
}

// 重置计时器
func BenchmarkWithReset(b *testing.B) {
    // 准备工作（不计入基准测试时间）
    setup()
    
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        // 只测量这部分
        doWork()
    }
    
    b.StopTimer()
    cleanup()
}
```

---

## 4. Fuzzing 模糊测试

```go
package fuzz

import (
    "testing"
    "unicode/utf8"
)

func Reverse(s string) string {
    runes := []rune(s)
    for i, j := 0, len(runes)-1; i < j; i, j = i+1, j-1 {
        runes[i], runes[j] = runes[j], runes[i]
    }
    return string(runes)
}

// 单元测试
func TestReverse(t *testing.T) {
    tests := []struct {
        input, expected string
    }{
        {"hello", "olleh"},
        {"", ""},
        {"a", "a"},
    }
    
    for _, tt := range tests {
        result := Reverse(tt.input)
        if result != tt.expected {
            t.Errorf("Reverse(%q) = %q; want %q", tt.input, result, tt.expected)
        }
    }
}

// 模糊测试
func FuzzReverse(f *testing.F) {
    // 添加种子语料
    testcases := []string{"Hello, world", " ", "!12345"}
    for _, tc := range testcases {
        f.Add(tc)
    }
    
    f.Fuzz(func(t *testing.T, orig string) {
        rev := Reverse(orig)
        doubleRev := Reverse(rev)
        
        // 属性测试：反转两次应该得到原字符串
        if orig != doubleRev {
            t.Errorf("Before: %q, after: %q", orig, doubleRev)
        }
        
        // 检查 UTF-8 有效性
        if utf8.ValidString(orig) && !utf8.ValidString(rev) {
            t.Errorf("Reverse produced invalid UTF-8 string %q", rev)
        }
    })
}
```

---

## 5. 测试覆盖率

### 5.1 生成覆盖率报告

```bash
# 运行测试并收集覆盖率
go test -cover ./...

# 生成覆盖率报告
go test -coverprofile=coverage.out ./...

# 查看覆盖率
go tool cover -func=coverage.out

# HTML 报告
go tool cover -html=coverage.out -o coverage.html

# 按包显示覆盖率
go test -cover -covermode=count -coverprofile=coverage.out ./...
go tool cover -func=coverage.out
```

### 5.2 覆盖率模式

```go
// 三种覆盖率模式：
// 1. set: 是否执行（默认）
// 2. count: 执行次数
// 3. atomic: 原子计数（并发安全）

// 命令
// go test -covermode=set
// go test -covermode=count
// go test -covermode=atomic
```

---

## 6. 集成测试

### 6.1 测试数据库

```go
package repository

import (
    "database/sql"
    "testing"
    
    _ "github.com/lib/pq"
)

func setupTestDB(t *testing.T) *sql.DB {
    db, err := sql.Open("postgres", "postgres://test:test@localhost:5432/testdb?sslmode=disable")
    if err != nil {
        t.Fatalf("Failed to connect to database: %v", err)
    }
    
    // 清理表
    db.Exec("TRUNCATE users CASCADE")
    
    return db
}

func TestUserRepository_Create(t *testing.T) {
    db := setupTestDB(t)
    defer db.Close()
    
    repo := NewUserRepository(db)
    
    user := &User{Name: "Alice", Email: "alice@example.com"}
    err := repo.Create(user)
    
    if err != nil {
        t.Errorf("Failed to create user: %v", err)
    }
    
    if user.ID == 0 {
        t.Error("User ID should be set after creation")
    }
}

// 使用 build tags 控制集成测试
//go:build integration
// +build integration

func TestIntegrationUserFlow(t *testing.T) {
    // 这个测试只在运行 go test -tags=integration 时执行
}

// 运行: go test -tags=integration ./...
```

### 6.2 测试 HTTP 服务

```go
package handler

import (
    "encoding/json"
    "net/http"
    "net/http/httptest"
    "testing"
    
    "github.com/stretchr/testify/assert"
)

func TestGetUserHandler(t *testing.T) {
    // 创建请求
    req := httptest.NewRequest(http.MethodGet, "/users/1", nil)
    
    // 创建响应记录器
    rr := httptest.NewRecorder()
    
    // 创建 handler
    handler := http.HandlerFunc(GetUserHandler)
    
    // 执行请求
    handler.ServeHTTP(rr, req)
    
    // 检查状态码
    assert.Equal(t, http.StatusOK, rr.Code)
    
    // 检查响应体
    var user User
    json.Unmarshal(rr.Body.Bytes(), &user)
    assert.Equal(t, 1, user.ID)
}

func TestCreateUserHandler(t *testing.T) {
    user := User{Name: "Alice", Email: "alice@example.com"}
    body, _ := json.Marshal(user)
    
    req := httptest.NewRequest(http.MethodPost, "/users", bytes.NewBuffer(body))
    req.Header.Set("Content-Type", "application/json")
    
    rr := httptest.NewRecorder()
    handler := http.HandlerFunc(CreateUserHandler)
    
    handler.ServeHTTP(rr, req)
    
    assert.Equal(t, http.StatusCreated, rr.Code)
}
```

---

## 7. 测试最佳实践

### 7.1 测试组织

```
project/
├── main.go
├── main_test.go          # 同包测试
├── calculator/
│   ├── calculator.go
│   ├── calculator_test.go # 白盒测试（可访问私有函数）
│   └── calculator_integration_test.go
├── internal/
│   └── service/
│       ├── service.go
│       └── service_test.go
└── test/
    ├── fixtures/          # 测试数据
    ├── mocks/             # Mock 实现
    └── helpers/           # 测试辅助函数
```

### 7.2 测试命名规范

```go
// 测试函数命名: Test<函数名>_<场景>_<预期结果>
func TestAdd_WithPositiveNumbers_ReturnsSum(t *testing.T) {}
func TestDivide_ByZero_ReturnsError(t *testing.T) {}
func TestUser_Create_WithValidData_Succeeds(t *testing.T) {}

// 表驱动测试命名
func TestAdd(t *testing.T) {
    tests := []struct {
        name string
        // ...
    }{
        {"positive numbers", 2, 3, 5},
        {"negative numbers", -2, -3, -5},
    }
}
```

### 7.3 测试辅助函数

```go
package testutil

import "testing"

// 断言辅助函数
func AssertEqual(t *testing.T, expected, actual interface{}) {
    t.Helper()  // 标记为辅助函数，错误报告正确行号
    if expected != actual {
        t.Errorf("Expected %v, got %v", expected, actual)
    }
}

func AssertError(t *testing.T, err error, expectedMsg string) {
    t.Helper()
    if err == nil {
        t.Error("Expected error, got nil")
        return
    }
    if !strings.Contains(err.Error(), expectedMsg) {
        t.Errorf("Error message %q does not contain %q", err.Error(), expectedMsg)
    }
}

// 使用
func TestSomething(t *testing.T) {
    result := Add(2, 3)
    testutil.AssertEqual(t, 5, result)
}
```

---

## 8. 运行测试

```bash
# 运行所有测试
go test ./...

# 运行特定包
go test ./calculator

# 运行特定测试
go test -run TestAdd
go test -run TestAdd/TestPositive

# 详细输出
go test -v ./...

# 运行基准测试
go test -bench=. ./...
go test -bench=Fibonacci -benchtime=5s

# 运行模糊测试
go test -fuzz=FuzzReverse
go test -fuzz=FuzzReverse -fuzztime=30s

# 检测数据竞争
go test -race ./...

# 并行运行
go test -parallel 4 ./...

# 超时设置
go test -timeout 30s ./...

# 生成覆盖率
go test -cover -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```
