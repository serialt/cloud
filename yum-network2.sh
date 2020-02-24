#!/bin/bash
#get repo file from network


ping -c 1 www.baidu.com &>/dev/null
if [ $? -ne 0 ]
then 
	exit
fi
which wget &>/dev/null
if [ $? -ne 0 ]
then
	echo "wget is installing,please waite"
	yum -y install wget &>/dev/null

	if [ $? -ne 0 ]
	then 
		echo "wget install failed"
		exit
	fi
	
fi

echo "wget install succeed !"

waite_s(){
	sleep 1
}
	
menu(){
cat<<eof

=================================
	  配置yum源
=================================
	1、aliyun
	2、neteasy-163
	3、huaweicloud
	4、tsinghua
	5、安装epel-release
	6、配置本地yum源   
	m、help
	q、exit
	b、备份本地已有的yum源
	d、delete all repo file
	t、test
	l、显示所有的repo文件
	h、yum安装时出现错误

=================================

eof
}

succeed(){
	waite_s
	echo
	echo "******repo file crated******"
	echo 
}

bak(){
	if [ -f /etc/yum.repos.d/bak ]
	then
		mv -f  /etc/yum.repos.d/*.repo  /etc/yum.repos.d/bak/  &> /dev/null
	else
		mkdir -p /etc/yum.repos.d/bak
		mv /etc/yum.repos.d/*.repo  /etc/yum.repos.d/bak/  &> /dev/null
	
	fi
	echo	
	echo "******备份成功******"
	echo
}
menu
while true 
do
echo
echo "*********在配置yum源前建议先备份************"
echo "if you do not want to backup, please ignore !"
echo
read -p"  input the number(entry m for get help):" select
case $select in

	1)
		wget -O /etc/yum.repos.d/aliyun.repo http://mirrors.aliyun.com/repo/Centos-7.repo &>/dev/null
		succeed
		;;
	2)
		wget -O /etc/yum.repos.d/163.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo &>/dev/null
		succeed
		;;
	3) 
		wget -O /etc/yum.repos.d/huaweicloud.repo https://mirrors.huaweicloud.com/repository/conf/CentOS-7-anon.repo &>/dev/null
		succeed
		;;
	4)
	cat >/etc/yum.repos.d/tsinghua.repo <<EOF

[base]
name=CentOS-$releasever - Base
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos/$releasever/os/$basearch/
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=os
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

name=CentOS-$releasever - Updates
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos/$releasever/updates/$basearch/
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=updates
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that may be useful
[extras]
name=CentOS-$releasever - Extras
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos/$releasever/extras/$basearch/
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=extras
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that extend functionality of existing packages
[centosplus]
name=CentOS-$releasever - Plus
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos/$releasever/centosplus/$basearch/
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=centosplus
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

EOF
		succeed
		;;
	5)
		wget -O /etc/yum.repos.d/epel-huawei.repo https://mirrors.huaweicloud.com/repository/conf/epel-7-anon.repo &>/dev/null
                succeed
		;;

	6)
		if [ -d /var/ftp/local ]
		then
			umount /mnt/local &>/dev/null
			mount /dev/cdrom /mnt/local
		else
			mkdir /mnt/local
			mount /dev/cdrom /mnt/local &>/dev/null
		fi

cat > /etc/yum.repos.d/local.repo << EOF
[local]
basename=local
baseurl=file:///mnt/local
enabled=1
gpgcheck=0
EOF
		succeed
		;;	
	q)
		exit
		;;
	m)
		menu
		;;
	t)	
		yum clean all && yum makecache &>/dev/null
		if [ $? -ne 0 ]
		then
			echo "unknow_error"
		ls -l /etc/yum/repos/d/
		fi
		waite_s
		
		;; 
	b)
		bak
		waite_s
		;;
	d)
		rm -rf /etc/yum.repos.d/*.repo
		echo "成功删除所有repo文件"
		waite_s
		;;

	l)
		echo -e "\n\n"	
		ls -l /etc/yum.repos.d/
		echo -e "\n\n"
		;;
	h)
		rm -rf /var/run/yum.pid
		;;
	*)	
		echo "unknown"
		;;
esac

done
