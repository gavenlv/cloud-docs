# 优化后：使用Alpine + 多阶段构建
FROM python:3.11-alpine AS builder

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --user=appuser -r requirements.txt

COPY . .
RUN python -m pip install --user .

FROM python:3.11-alpine

WORKDIR /app

COPY --from=builder /root/.local /root/.local
COPY --from=builder /app /app

ENV PATH=/root/.local/bin:$PATH

ENV PYTHONUNBUFFERED=1

EXPOSE 8000

CMD ["python", "app.py"]

# 镜像大小：50MB