# Memorystore Redis Python客户端示例

import redis
import os


class RedisClient:
    def __init__(self):
        self.host = os.environ.get('REDIS_HOST', 'localhost')
        self.port = int(os.environ.get('REDIS_PORT', 6379))
        self.password = os.environ.get('REDIS_PASSWORD')
        self.use_ssl = os.environ.get('REDIS_USE_SSL', 'false').lower() == 'true'

        self.client = redis.Redis(
            host=self.host,
            port=self.port,
            password=self.password,
            decode_responses=True,
            ssl=self.use_ssl,
            socket_connect_timeout=5,
            socket_timeout=5,
            retry_on_timeout=True
        )

    def set(self, key, value, expire=None):
        if expire:
            return self.client.setex(key, expire, value)
        return self.client.set(key, value)

    def get(self, key):
        return self.client.get(key)

    def delete(self, key):
        return self.client.delete(key)

    def exists(self, key):
        return self.client.exists(key)

    def incr(self, key, amount=1):
        return self.client.incrby(key, amount)

    def decr(self, key, amount=1):
        return self.client.decrby(key, amount)

    def expire(self, key, seconds):
        return self.client.expire(key, seconds)

    def ttl(self, key):
        return self.client.ttl(key)

    def hset(self, name, key, value):
        return self.client.hset(name, key, value)

    def hget(self, name, key):
        return self.client.hget(name, key)

    def hgetall(self, name):
        return self.client.hgetall(name)

    def lpush(self, key, *values):
        return self.client.lpush(key, *values)

    def rpop(self, key):
        return self.client.rpop(key)

    def llen(self, key):
        return self.client.llen(key)

    def ping(self):
        return self.client.ping()


redis_client = RedisClient()

if __name__ == "__main__":
    print(f"Testing Redis connection to {redis_client.host}:{redis_client.port}")
    print(f"Ping response: {redis_client.ping()}")

    redis_client.set("test_key", "test_value", expire=60)
    print(f"GET test_key: {redis_client.get('test_key')}")
    print(f"TTL test_key: {redis_client.ttl('test_key')}")

    redis_client.delete("test_key")
    print(f"Key deleted: {not redis_client.exists('test_key')}")
