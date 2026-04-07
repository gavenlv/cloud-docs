# Go 最佳实践

> **🎯 核心概念**：最佳实践是经验的结晶。理解这些实践背后的原因，能让你写出更易维护、更可靠的代码。

## 1. 项目结构

> **🎯 核心概念**：良好的项目结构是可维护性的基础。Go 社区有一些约定俗成的布局模式，理解它们有助于组织代码。

### 1.1 标准项目布局

```
project/
├── cmd/                    # 主程序入口
│   ├── api/
│   │   └── main.go        # API 服务入口
│   └── cli/
│       └── main.go        # CLI 工具入口
├── internal/               # 私有代码（不可被外部导入）
│   ├── handler/           # HTTP handlers
│   ├── service/           # 业务逻辑
│   ├── repository/        # 数据访问
│   └── model/             # 内部模型
├── pkg/                    # 公开代码（可被外部导入）
│   ├── utils/             # 工具函数
│   └── validator/         # 验证器
├── api/                    # API 定义
│   ├── openapi/           # OpenAPI/Swagger 规范
│   └── proto/             # Protobuf 定义
├── configs/                # 配置文件
├── scripts/                # 脚本文件
├── test/                   # 额外测试
│   ├── integration/       # 集成测试
│   └── e2e/               # 端到端测试
├── docs/                   # 文档
├── deployments/            # 部署配置
│   ├── docker/
│   └── kubernetes/
├── go.mod
├── go.sum
├── Makefile
└── README.md
```

#### 🔬 深度解析：为什么这样组织？

```
┌─────────────────────────────────────────────────────────────────┐
│  项目结构设计原则                                                 │
└─────────────────────────────────────────────────────────────────┘

1. cmd/ vs pkg/ vs internal/
   ├── cmd/: 每个子目录是一个可执行程序
   ├── pkg/: 可被外部项目导入的公共库
   └── internal/: 只能被本项目导入（编译器强制）

2. internal/ 的价值
   ├── 防止 API 泄漏
   ├── 强制模块边界
   └── 允许内部重构而不影响外部

3. 分层架构
   ├── handler: 处理 HTTP 请求/响应
   ├── service: 业务逻辑
   ├── repository: 数据访问
   └── model: 数据模型
```

##### 实战案例：Web 服务项目结构

```go
// cmd/api/main.go
package main

import (
    "log"
    
    "myapp/internal/handler"
    "myapp/internal/repository"
    "myapp/internal/service"
    "myapp/pkg/config"
)

func main() {
    cfg, err := config.Load()
    if err != nil {
        log.Fatal(err)
    }
    
    db, err := repository.NewDB(cfg.Database)
    if err != nil {
        log.Fatal(err)
    }
    defer db.Close()
    
    userRepo := repository.NewUserRepository(db)
    userService := service.NewUserService(userRepo)
    userHandler := handler.NewUserHandler(userService)
    
    server := handler.NewServer(cfg.Server, userHandler)
    if err := server.Start(); err != nil {
        log.Fatal(err)
    }
}
```

```go
// internal/handler/user.go
package handler

import (
    "encoding/json"
    "net/http"
    
    "myapp/internal/service"
)

type UserHandler struct {
    service *service.UserService
}

func NewUserHandler(service *service.UserService) *UserHandler {
    return &UserHandler{service: service}
}

func (h *UserHandler) GetUser(w http.ResponseWriter, r *http.Request) {
    id := r.PathValue("id")
    
    user, err := h.service.GetUser(r.Context(), id)
    if err != nil {
        handleError(w, err)
        return
    }
    
    json.NewEncoder(w).Encode(user)
}
```

```go
// internal/service/user.go
package service

import (
    "context"
    
    "myapp/internal/model"
    "myapp/internal/repository"
)

type UserService struct {
    repo repository.UserRepository
}

func NewUserService(repo repository.UserRepository) *UserService {
    return &UserService{repo: repo}
}

func (s *UserService) GetUser(ctx context.Context, id string) (*model.User, error) {
    return s.repo.FindByID(ctx, id)
}
```

```go
// internal/repository/user.go
package repository

import (
    "context"
    "database/sql"
    
    "myapp/internal/model"
)

type UserRepository interface {
    FindByID(ctx context.Context, id string) (*model.User, error)
    Create(ctx context.Context, user *model.User) error
}

type userRepository struct {
    db *sql.DB
}

func NewUserRepository(db *sql.DB) UserRepository {
    return &userRepository{db: db}
}

func (r *userRepository) FindByID(ctx context.Context, id string) (*model.User, error) {
    query := `SELECT id, name, email FROM users WHERE id = $1`
    
    var user model.User
    err := r.db.QueryRowContext(ctx, query, id).Scan(&user.ID, &user.Name, &user.Email)
    if err != nil {
        return nil, err
    }
    
    return &user, nil
}
```

> **💡 新手提示**：
> - 小项目不需要复杂的目录结构，保持简单
> - `internal/` 目录是 Go 编译器强制的，外部无法导入
> - 每个包应该有清晰的职责

> **🎓 专家视角**：项目结构的演进：
> 1. **开始简单**：单文件或扁平结构
> 2. **按功能拆分**：当文件变大时
> 3. **引入分层**：当需要测试和替换实现时
> 4. **模块化**：当项目变大时，考虑拆分为多个模块

### 1.2 简单项目布局

```
simple-project/
├── main.go
├── handlers.go
├── models.go
├── service.go
├── repository.go
├── handlers_test.go
├── models_test.go
├── go.mod
└── README.md
```

---

## 2. 错误处理最佳实践

### 2.1 错误定义

```go
package errors

import "errors"

// 哨兵错误
var (
    ErrNotFound     = errors.New("resource not found")
    ErrUnauthorized = errors.New("unauthorized")
    ErrInvalidInput = errors.New("invalid input")
)

// 自定义错误类型
type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation error: %s - %s", e.Field, e.Message)
}

func NewValidationError(field, message string) error {
    return &ValidationError{
        Field:   field,
        Message: message,
    }
}

// 包装错误
func (s *Service) GetUser(id int) (*User, error) {
    user, err := s.repo.FindByID(id)
    if err != nil {
        return nil, fmt.Errorf("failed to get user %d: %w", id, err)
    }
    return user, nil
}

// 检查错误
func (h *Handler) HandleGetUser(w http.ResponseWriter, r *http.Request) {
    user, err := h.service.GetUser(id)
    if err != nil {
        if errors.Is(err, ErrNotFound) {
            http.Error(w, "User not found", http.StatusNotFound)
            return
        }
        
        var ve *ValidationError
        if errors.As(err, &ve) {
            http.Error(w, ve.Error(), http.StatusBadRequest)
            return
        }
        
        http.Error(w, "Internal server error", http.StatusInternalServerError)
        return
    }
    
    json.NewEncoder(w).Encode(user)
}
```

### 2.2 错误处理模式

```go
package service

import (
    "errors"
    "fmt"
)

// 模式1: 提前返回
func ProcessData(data string) error {
    if data == "" {
        return errors.New("data cannot be empty")
    }
    
    if len(data) > 100 {
        return errors.New("data too long")
    }
    
    // 处理数据
    return nil
}

// 模式2: 错误包装
func (s *Service) CreateUser(user *User) error {
    if err := s.validateUser(user); err != nil {
        return fmt.Errorf("validation failed: %w", err)
    }
    
    if err := s.repo.Create(user); err != nil {
        return fmt.Errorf("failed to create user: %w", err)
    }
    
    return nil
}

// 模式3: 多错误合并
func (s *Service) BatchCreate(users []*User) error {
    var errs []error
    
    for _, user := range users {
        if err := s.CreateUser(user); err != nil {
            errs = append(errs, fmt.Errorf("user %s: %w", user.Name, err))
        }
    }
    
    if len(errs) > 0 {
        return errors.Join(errs...)
    }
    
    return nil
}

// 模式4: 错误上下文
type ErrorWithContext struct {
    Err       error
    Context   map[string]interface{}
    StackTrace string
}

func (e *ErrorWithContext) Error() string {
    return fmt.Sprintf("%v (context: %v)", e.Err, e.Context)
}

func (e *ErrorWithContext) Unwrap() error {
    return e.Err
}
```

---

## 3. 接口设计原则

### 3.1 接口设计

```go
package service

// 原则1: 接口要小
type Reader interface {
    Read(p []byte) (n int, err error)
}

type Writer interface {
    Write(p []byte) (n int, err error)
}

// 组合接口
type ReadWriter interface {
    Reader
    Writer
}

// 原则2: 接口在使用方定义
// 错误: 在实现方定义大接口
type UserRepository interface {
    FindByID(id int) (*User, error)
    FindByEmail(email string) (*User, error)
    Create(user *User) error
    Update(user *User) error
    Delete(id int) error
    FindAll() ([]*User, error)
    Count() (int, error)
}

// 正确: 在使用方定义需要的接口
type UserFinder interface {
    FindByID(id int) (*User, error)
}

type UserCreator interface {
    Create(user *User) error
}

// 原则3: 接收接口，返回结构体
func NewUserService(finder UserFinder) *UserService {
    return &UserService{finder: finder}
}

func (s *UserService) GetUser(id int) (*User, error) {
    return s.finder.FindByID(id)
}
```

### 3.2 依赖注入

```go
package main

import (
    "database/sql"
    
    "github.com/gin-gonic/gin"
    "go.uber.org/zap"
)

// 使用结构体组合
type UserService struct {
    repo   UserRepository
    logger *zap.Logger
    cache  Cache
}

func NewUserService(repo UserRepository, logger *zap.Logger, cache Cache) *UserService {
    return &UserService{
        repo:   repo,
        logger: logger,
        cache:  cache,
    }
}

// 使用函数选项模式
type Server struct {
    port    int
    handler http.Handler
    logger  *zap.Logger
}

type ServerOption func(*Server)

func WithPort(port int) ServerOption {
    return func(s *Server) {
        s.port = port
    }
}

func WithLogger(logger *zap.Logger) ServerOption {
    return func(s *Server) {
        s.logger = logger
    }
}

func NewServer(handler http.Handler, opts ...ServerOption) *Server {
    s := &Server{
        port:    8080,
        handler: handler,
        logger:  zap.NewNop(),
    }
    
    for _, opt := range opts {
        opt(s)
    }
    
    return s
}

// 使用
server := NewServer(
    handler,
    WithPort(3000),
    WithLogger(logger),
)
```

---

## 4. 并发最佳实践

### 4.1 Context 传递

```go
package service

import (
    "context"
    "time"
)

// 正确: context 作为第一个参数
func (s *Service) GetUser(ctx context.Context, id int) (*User, error) {
    // 传递 context 到下游
    user, err := s.repo.FindByID(ctx, id)
    if err != nil {
        return nil, err
    }
    
    // 检查 context 是否取消
    select {
    case <-ctx.Done():
        return nil, ctx.Err()
    default:
    }
    
    return user, nil
}

// 不要在结构体中存储 context
type Service struct {
    repo Repository
    // ctx context.Context  // 错误!
}

// 正确: 在方法中传递 context
func (s *Service) DoSomething(ctx context.Context) error {
    return s.repo.DoWork(ctx)
}
```

### 4.2 Goroutine 管理

```go
package worker

import (
    "context"
    "sync"
)

// 使用 errgroup 管理 goroutine
import "golang.org/x/sync/errgroup"

func (w *Worker) ProcessAll(ctx context.Context, items []Item) error {
    g, ctx := errgroup.WithContext(ctx)
    
    for _, item := range items {
        item := item  // 捕获变量
        g.Go(func() error {
            return w.process(ctx, item)
        })
    }
    
    return g.Wait()
}

// 使用 semaphore 控制并发
import "golang.org/x/sync/semaphore"

func (w *Worker) ProcessWithLimit(ctx context.Context, items []Item) error {
    sem := semaphore.NewWeighted(10)  // 最多 10 个并发
    
    var wg sync.WaitGroup
    var err error
    var mu sync.Mutex
    
    for _, item := range items {
        if err := sem.Acquire(ctx, 1); err != nil {
            break
        }
        
        wg.Add(1)
        go func(item Item) {
            defer wg.Done()
            defer sem.Release(1)
            
            if e := w.process(ctx, item); e != nil {
                mu.Lock()
                err = e
                mu.Unlock()
            }
        }(item)
    }
    
    wg.Wait()
    return err
}
```

---

## 5. 代码质量工具

### 5.1 Linter 配置

```yaml
# .golangci.yml
run:
  timeout: 5m
  tests: true

linters:
  enable:
    - gofmt
    - goimports
    - govet
    - errcheck
    - staticcheck
    - ineffassign
    - typecheck
    - gosimple
    - goconst
    - gocyclo
    - dupl
    - misspell

linters-settings:
  gocyclo:
    min-complexity: 15
  goconst:
    min-len: 3
    min-occurrences: 3

issues:
  exclude-rules:
    - path: _test\.go
      linters:
        - dupl
```

### 5.2 Makefile

```makefile
.PHONY: all build test lint fmt clean

APP_NAME := myapp
VERSION := $(shell git describe --tags --always --dirty)
BUILD_TIME := $(shell date -u '+%Y-%m-%d_%H:%M:%S')
LDFLAGS := -ldflags "-X main.Version=$(VERSION) -X main.BuildTime=$(BUILD_TIME)"

all: lint test build

build:
	go build $(LDFLAGS) -o bin/$(APP_NAME) ./cmd/api

test:
	go test -v -race -coverprofile=coverage.out ./...

lint:
	golangci-lint run

fmt:
	go fmt ./...
	goimports -w .

clean:
	rm -rf bin/
	rm -f coverage.out

docker-build:
	docker build -t $(APP_NAME):$(VERSION) .

run:
	go run ./cmd/api
```

### 5.3 Pre-commit Hooks

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files

  - repo: https://github.com/golangci/golangci-lint
    rev: v1.55.2
    hooks:
      - id: golangci-lint

  - repo: https://github.com/dnephin/pre-commit-golang
    rev: v0.5.1
    hooks:
      - id: go-fmt
      - id: go-imports
      - id: go-mod-tidy
```

---

## 6. 日志规范

### 6.1 结构化日志

```go
package logger

import (
    "go.uber.org/zap"
    "go.uber.org/zap/zapcore"
)

func NewLogger(env string) (*zap.Logger, error) {
    var config zap.Config
    
    if env == "production" {
        config = zap.NewProductionConfig()
        config.Level = zap.NewAtomicLevelAt(zapcore.InfoLevel)
    } else {
        config = zap.NewDevelopmentConfig()
        config.Level = zap.NewAtomicLevelAt(zapcore.DebugLevel)
    }
    
    config.EncoderConfig.TimeKey = "timestamp"
    config.EncoderConfig.EncodeTime = zapcore.ISO8601TimeEncoder
    
    return config.Build()
}

// 使用
func (s *Service) CreateUser(ctx context.Context, user *User) error {
    s.logger.Info("creating user",
        zap.String("user_id", user.ID),
        zap.String("email", user.Email),
        zap.String("request_id", ctx.Value("request_id").(string)),
    )
    
    if err := s.repo.Create(user); err != nil {
        s.logger.Error("failed to create user",
            zap.Error(err),
            zap.String("user_id", user.ID),
        )
        return err
    }
    
    s.logger.Info("user created successfully",
        zap.String("user_id", user.ID),
        zap.Duration("duration", time.Since(start)),
    )
    
    return nil
}
```

### 6.2 日志级别使用

```
┌─────────────────────────────────────────────────────────────────┐
│  日志级别使用指南                                                  │
└─────────────────────────────────────────────────────────────────┘

DEBUG: 开发调试信息
├── 详细的程序流程
├── 变量值和状态
└── 性能测量点

INFO: 正常业务信息
├── 服务启动/关闭
├── 重要的业务事件
├── 请求处理完成
└── 定时任务执行

WARN: 警告信息
├── 潜在问题
├── 性能下降
├── 即将废弃的功能
└── 可恢复的错误

ERROR: 错误信息
├── 操作失败
├── 异常情况
├── 需要关注的错误
└── 重试失败

FATAL: 致命错误
├── 无法恢复的错误
├── 服务必须停止
└── 配置错误
```

---

## 7. 配置管理

### 7.1 环境变量配置

```go
package config

import (
    "os"
    "strconv"
    "time"
)

type Config struct {
    Server   ServerConfig
    Database DatabaseConfig
    Redis    RedisConfig
}

type ServerConfig struct {
    Port         int
    ReadTimeout  time.Duration
    WriteTimeout time.Duration
}

type DatabaseConfig struct {
    Host     string
    Port     int
    User     string
    Password string
    Database string
}

func Load() (*Config, error) {
    return &Config{
        Server: ServerConfig{
            Port:         getEnvInt("SERVER_PORT", 8080),
            ReadTimeout:  getEnvDuration("SERVER_READ_TIMEOUT", 30*time.Second),
            WriteTimeout: getEnvDuration("SERVER_WRITE_TIMEOUT", 30*time.Second),
        },
        Database: DatabaseConfig{
            Host:     getEnv("DB_HOST", "localhost"),
            Port:     getEnvInt("DB_PORT", 5432),
            User:     getEnv("DB_USER", "postgres"),
            Password: getEnv("DB_PASSWORD", ""),
            Database: getEnv("DB_NAME", "myapp"),
        },
    }, nil
}

func getEnv(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}

func getEnvInt(key string, defaultValue int) int {
    if value := os.Getenv(key); value != "" {
        if i, err := strconv.Atoi(value); err == nil {
            return i
        }
    }
    return defaultValue
}

func getEnvDuration(key string, defaultValue time.Duration) time.Duration {
    if value := os.Getenv(key); value != "" {
        if d, err := time.ParseDuration(value); err == nil {
            return d
        }
    }
    return defaultValue
}
```

### 7.2 配置文件

```yaml
# config.yaml
server:
  port: 8080
  read_timeout: 30s
  write_timeout: 30s

database:
  host: localhost
  port: 5432
  user: postgres
  password: ${DB_PASSWORD}
  database: myapp
  max_connections: 100

redis:
  host: localhost
  port: 6379
  password: ""
  db: 0

logging:
  level: info
  format: json
```

```go
package config

import (
    "os"
    
    "gopkg.in/yaml.v3"
)

func LoadFromFile(path string) (*Config, error) {
    data, err := os.ReadFile(path)
    if err != nil {
        return nil, err
    }
    
    // 替换环境变量
    expanded := os.ExpandEnv(string(data))
    
    var config Config
    if err := yaml.Unmarshal([]byte(expanded), &config); err != nil {
        return nil, err
    }
    
    return &config, nil
}
```

---

## 8. 代码审查清单

```
┌─────────────────────────────────────────────────────────────────┐
│  Go 代码审查清单                                                  │
└─────────────────────────────────────────────────────────────────┘

代码风格
├── 是否通过 gofmt 格式化
├── 是否通过 goimports 检查
├── 命名是否清晰、一致
└── 注释是否充分

错误处理
├── 是否正确处理所有错误
├── 错误是否添加上下文
├── 是否使用哨兵错误
└── 是否正确使用 errors.Is/As

并发安全
├── 是否存在数据竞争
├── goroutine 是否能正确退出
├── context 是否正确传递
└── 是否有 goroutine 泄漏风险

性能
├── 是否有不必要的内存分配
├── 循环中是否有可优化的操作
├── 是否正确使用 sync.Pool
└── 是否有潜在的性能瓶颈

测试
├── 测试覆盖率是否足够
├── 是否测试边界条件
├── 是否测试错误路径
└── 是否有基准测试

安全
├── 是否有 SQL 注入风险
├── 是否有敏感信息泄露
├── 输入是否经过验证
└── 是否正确处理认证授权
```
