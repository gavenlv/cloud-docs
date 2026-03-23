visudo      编辑sudoers文件

配置示例：
root    ALL=(ALL:ALL) ALL
user    ALL=(ALL) NOPASSWD: ALL
%admin  ALL=(ALL) ALL

使用sudo：
sudo command
sudo -u username command