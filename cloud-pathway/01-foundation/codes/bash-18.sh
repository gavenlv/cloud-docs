前台/后台：
command &           后台运行
nohup command &     忽略挂断信号后台运行
jobs                查看后台任务
fg %1               将任务1调到前台
bg %1               将任务1放到后台

进程终止：
kill PID            发送TERM信号
kill -9 PID         发送KILL信号（强制）
kill -HUP PID       发送HUP信号（重载配置）
killall name        按名称终止进程
pkill pattern       按模式终止进程