# 传统DNS: 明文, 可被监听和篡改
# DoH: DNS查询通过HTTPS加密传输

# 使用DoH (需要支持DoH的DNS客户端)
# Cloudflare: https://cloudflare-dns.com/dns-query
# Google: https://dns.google/dns-query

# curl测试DoH
curl -H 'accept: application/dns-json' \
     'https://cloudflare-dns.com/dns-query?name=www.example.com&type=A'

# Firefox启用DoH
# about:config → network.trr.mode = 2 (DoH启用)