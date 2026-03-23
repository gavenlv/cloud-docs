ps          查看进程
ps aux      显示所有进程详细信息
ps -ef      完整格式显示
ps aux | grep nginx    查找特定进程

top         动态显示进程
htop        增强版top（需安装）

pstree      以树形显示进程

pgrep       按名称查找进程ID
pgrep nginx
pgrep -l nginx    显示进程名

pidof       查找进程ID
pidof nginx