# 镜像优化实战 - 一个Go应用的大小对比

# ============================================================
# 方案1: 直接使用 golang 镜像
# ============================================================
FROM golang:1.21

WORKDIR /app
COPY . .
RUN go build -o main .

# 最终镜像大小: ~800MB+ ❌
# 问题: 包含完整的Go编译器和所有构建工具


# ============================================================
# 方案2: 使用多阶段构建
# ============================================================
FROM golang:1.21 AS builder

WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o main .

FROM alpine:3.18
COPY --from=builder /app/main .
CMD ["./main"]

# 最终镜像大小: ~15MB ✓✓✓
# 优化点:
# ├── 只复制编译好的二进制
# ├── 使用最小的运行时镜像
# └── 不包含任何编译工具


# ============================================================
# 方案3: 进一步优化 - distroless
# ============================================================
FROM golang:1.21 AS builder

WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o main .

FROM gcr.io/distroless/static:nonroot
COPY --from=builder /app/main .
CMD ["./main"]

# 最终镜像大小: ~5MB ✓✓✓✓
# 优化点:
# ├── distroless只有最基本的文件
# ├── 没有shell
# ├── 最小化攻击面
# └── 极度安全