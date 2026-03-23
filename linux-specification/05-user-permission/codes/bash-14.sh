# 常用sudo命令
sudo -l                        # 查看当前用户sudo权限
sudo -u user command           # 以指定用户执行
sudo -u user -g group command # 以指定用户和组执行
sudo -i                        # 切换到root shell
sudo -s                        # 切换到root shell (不加载完整环境)

# 编辑sudoers (建议使用visudo)
sudo visudo                     # 编辑sudoers
sudo visudo -f /etc/sudoers.d/custom  # 编辑自定义文件

# sudo日志
cat /var/log/auth.log | grep sudo  # Debian/Ubuntu
cat /var/log/secure               # CentOS/RHEL