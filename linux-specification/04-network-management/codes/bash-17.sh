# /etc/hosts - 本地静态解析

cat /etc/hosts
# 127.0.0.1   localhost
# ::1         localhost ip6-localhost ip6-loopback

# 添加自定义解析
echo "192.168.1.100 myserver.local" >> /etc/hosts
ping myserver.local

# /etc/nsswitch.conf - 名称解析顺序
grep "^hosts:" /etc/nsswitch.conf
# hosts:          files dns  <-- 先查/etc/hosts,再查DNS