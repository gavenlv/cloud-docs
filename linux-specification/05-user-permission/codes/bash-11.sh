# /etc/pam.d/ - PAM配置文件

# 查看PAM配置
ls /etc/pam.d/
# atd                cron               login
# other              passwd             sshd
# system-auth        system-login       systemd-user

# system-auth (CentOS/RHEL)
cat /etc/pam.d/system-auth
# auth        required      pam_env.so
# auth        required      pam_faildelay.so delay=2000000
# auth        sufficient    pam_unix.so nullok try_first_pass
# auth        requisite     pam_succeed_if.so uid >= 1000 quiet_success
# auth        required      pam_deny.so

# account     required      pam_unix.so
# account     sufficient    pam_localuser.so
# account     sufficient    pam_succeed_if.so uid < 1000 quiet
# account     required      pam_permit.so

# password    requisite     pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type=
# password    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok
# password    required      pam_deny.so

# session     optional      pam_keyinit.so revoke
# session     required      pam_limits.so
# session     optional      pam_unix.so
# session     optional      pam_systemd.so

# PAM控制标记:
# required    - 必须成功,失败继续但最终返回失败
# requisite   - 必须成功,失败立即返回失败
# sufficient  - 成功则足够,忽略后续模块
# optional    - 结果可忽略
# include     - 包含其他配置文件