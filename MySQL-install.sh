 #!/bin/bash
 yum -y install libaio
 yum remove mariadb-libs.x86_64
 groupadd mysql
 useradd -r -g mysql -s /bin/false mysql
 cd /usr/local
 tar zxvf /usr/local/mysql-5.7.22-linux-glibc2.12-x86_64.tar.gz
 ln -s mysql-5.7.22-linux-glibc2.12-x86_64 mysql
 cd mysql
 mkdir mysql-files
 chown mysql:mysql mysql-files
 chmod 750 mysql-files
 bin/mysqld --initialize --user=mysql
 bin/mysql_ssl_rsa_setup
 bin/mysqld_safe --user=mysql &
 # Next command is optional
 cp support-files/mysql.server /etc/init.d/mysql.server
