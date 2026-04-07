# Go 语言规范验证清单

## 基础验证

### 环境配置
- [ ] Go 版本 >= 1.22
- [ ] GOPATH 正确设置
- [ ] Go modules 启用
- [ ] IDE 配置完成（gopls）

### 基础语法
- [ ] 变量声明与类型推断
- [ ] 常量与 iota
- [ ] 切片操作
- [ ] Map 操作
- [ ] 结构体与方法
- [ ] 接口实现
- [ ] 错误处理

## 并发验证

### Goroutine
- [ ] 启动 goroutine
- [ ] WaitGroup 使用
- [ ] Context 控制
- [ ] 避免泄漏

### Channel
- [ ] 无缓冲 channel
- [ ] 有缓冲 channel
- [ ] select 多路复用
- [ ] 关闭 channel

### 同步原语
- [ ] Mutex/RWMutex
- [ ] sync.Once
- [ ] sync.Pool
- [ ] sync.Cond

## 标准库验证

### IO 操作
- [ ] 文件读写
- [ ] bufio 使用
- [ ] io.Copy/TeeReader

### 网络编程
- [ ] HTTP 服务端
- [ ] HTTP 客户端
- [ ] JSON 处理

### 其他
- [ ] 时间处理
- [ ] 字符串处理
- [ ] 反射使用

## 测试验证

### 单元测试
- [ ] 基本测试函数
- [ ] 表驱动测试
- [ ] 子测试 (t.Run)

### 测试工具
- [ ] testify 使用
- [ ] Mock 实现
- [ ] 测试覆盖率

### 基准测试
- [ ] Benchmark 函数
- [ ] 内存分析
- [ ] 并行基准

## 最佳实践验证

### 代码组织
- [ ] 项目结构规范
- [ ] 包命名规范
- [ ] 导出/未导出

### 错误处理
- [ ] 哨兵错误
- [ ] 错误包装
- [ ] errors.Is/As

### 并发安全
- [ ] 无数据竞争
- [ ] 正确使用锁
- [ ] Context 传递

## 高级模式验证

### 设计模式
- [ ] 单例模式
- [ ] 工厂模式
- [ ] 策略模式
- [ ] 观察者模式

### 泛型
- [ ] 泛型函数
- [ ] 泛型类型
- [ ] 类型约束

## 性能优化验证

### 内存优化
- [ ] 预分配
- [ ] sync.Pool
- [ ] 减少逃逸

### 工具使用
- [ ] pprof 分析
- [ ] benchmark 测试
- [ ] trace 追踪

## 命令验证

```bash
# 基础命令
go version
go env
go mod init
go mod tidy
go build
go run
go test

# 测试命令
go test -v ./...
go test -race ./...
go test -cover ./...
go test -bench=.

# 分析命令
go tool pprof
go tool trace
go vet ./...
golangci-lint run
```

## 项目实战验证

### CLI 应用
- [ ] 命令行参数解析
- [ ] 配置文件读取
- [ ] 日志输出

### Web 服务
- [ ] HTTP 路由
- [ ] 中间件
- [ ] JSON API
- [ ] 错误处理

### 数据库操作
- [ ] 连接池
- [ ] 查询操作
- [ ] 事务处理

## 学习路径完成度

| 阶段 | 章节 | 状态 |
|------|------|------|
| 入门 | 01-fundamentals | [ ] |
| 进阶 | 02-concurrency | [ ] |
| 进阶 | 03-standard-library | [ ] |
| 高级 | 04-testing | [ ] |
| 高级 | 05-best-practices | [ ] |
| 高级 | 06-advanced-patterns | [ ] |
| 高级 | 07-performance | [ ] |

## 认证标准

### 初级
- 完成基础语法学习
- 能编写简单程序
- 理解错误处理

### 中级
- 掌握并发编程
- 熟悉标准库
- 能编写测试

### 高级
- 掌握设计模式
- 性能优化能力
- 架构设计能力
