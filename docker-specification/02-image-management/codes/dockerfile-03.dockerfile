# 优化前：传统构建
FROM python:3.11

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

ENV PYTHONUNBUFFERED=1

EXPOSE 8000

CMD ["python", "app.py"]

# 镜像大小：900MB