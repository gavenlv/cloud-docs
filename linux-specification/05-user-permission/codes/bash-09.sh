# chown - 修改文件所有者

chown user file                 # 修改owner
chown user:group file          # 修改owner和group
chown :group file              # 只修改group (等价于chgrp)
chown -R user:group /path      # 递归修改

# 参考另一个文件
chown --reference=file1 file2

# 常用示例
chown -R www-data:www-data /var/www
chown root:root /etc/shadow
chown $USER:$USER ~/.ssh/*

# chgrp - 修改组所有权 (简写)
chgrp group file
chgrp -R group /path