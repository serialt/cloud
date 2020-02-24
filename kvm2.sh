#!/bin/bash
#2020.1.1
#kvm2.0
#serialt  serialt@outlook.com
#kvm-manager
#snapshot need guestfish
#image type is .qcow2



vm_xml_dir=/etc/libvirt/qemu
vm_img_dir=/var/lib/libvirt/images
vm_name=serialt
ftp_server=192.168.122.15

green_col='\E[0;32m' 
red_col="\e[1;31m"
blue_col="\e[1;34m"
reset_col="\e[0m"

###network test
network_ping(){
	if ! ping -c 1 ${ftp_server}  >/dev/null
	then
		echo -e "${red_col} ${ftp_server} unknow !!!"
		echo -e "${red_col} 请检查网络或稍后再试! ${reset_col}"
		echo
		exit
	fi
}

###get the VM xml and image file
download_file(){
	#download image
	if [ ! -f ${vm_img_dir}/${vm_name}.qcow2 ];
	then
		echo "正在下载镜像文件，请稍候......"
		wget -O ${vm_img_dir}/${vm_name}.qcow2 ftp://${ftp_server}/kvm/${vm_name}.qcow2
		
		
	fi	 	
        #download xml
	if [ ! -f ${vm_xml_dir}/${vm_name}.xml ];
	then
		echo "正在下载配置文件，请稍候......"
		wget -O ${vm_xml_dir}/${vm_name}.xml ftp://${ftp_server}/kvm/${vm_name}.xml 		
	fi	 	
}

any_key(){

	echo
    	echo -en "${blue_col}输入任意键继续${reset_col}\n"
	read
	clear
}
	
###create VM
create_vm(){
create_vm_menu(){
cat<<EFO
+++++++++++++++++++++++++++++++++++++
+	      创建虚拟机	    +
+++++++++++++++++++++++++++++++++++++
EFO
}
	create_vm_menu
	network_ping
	download_file
	read -p"please input virtaul machine name:" input_vm_name
	read -p"please input virtaul machine num:" input_vm_num
	echo
	for((i=1;i<=$input_vm_num;i++))
	do
		kvm_name=${input_vm_name}-${i}
		qemu-img create -f qcow2 -b ${vm_img_dir}/${vm_name}.qcow2  ${vm_img_dir}/${kvm_name}.qcow2 &>/dev/null
        	usleep 500000
        	cp -a ${vm_xml_dir}/${vm_name}.xml   ${vm_xml_dir}/${kvm_name}.xml
        	kvm_uuid=$(uuidgen)
        	kvm_mac="52:54:$(dd if=/dev/urandom count=1 2>/dev/null | md5sum | sed -r     's/^(..)(..)(..)(..).*$/\1:\2:\3:\4/')"
        	sed -ri "s/vm_name/${kvm_name}/"                ${vm_xml_dir}/${kvm_name}.xml
        	sed -ri "s/vm_uuid/$kvm_uuid/"                  ${vm_xml_dir}/${kvm_name}.xml
        	sed -ri "s/vm_mac/$kvm_mac/"                    ${vm_xml_dir}/${kvm_name}.xml
        	sed -ri "s#vm_img#${vm_img_dir}/${kvm_name}.qcow2#"       ${vm_xml_dir}/${kvm_name}.xml
        	virsh define ${vm_xml_dir}/${kvm_name}.xml &>/dev/null
        	echo -e "   虚拟机[ ${green_col}${kvm_name}${reset_col} ]创建成功...."
	done
	echo 
}

start_vm(){

	virsh list --all 
	echo -e "${red_col}支持模糊虚拟机名输入，但可能会操作多台虚拟机$reset_col"
        read -p "请输入准备启动虚拟机的名:" name
        for i in `virsh list --all |awk '{print $2}' |grep "$name"`
        do  
        	virsh start $i &>/dev/null
        	echo -e "   虚拟机[ ${green_col}${i}${reset_col} ]已启动...."
        done

}


stop_vm(){
	virsh list
	echo -e "${red_col}支持模糊虚拟机名输入，但可能会操作多台虚拟机$reset_col"
	echo -e "\n${red_col}提示:\n(1)停止部分虚拟机请输入名字!!! \n(2)停止所有虚拟机请回车!!!${reset_col}\n"
        read -p "请输入准备停止虚拟机的名字:" name
        for i in `virsh list --all |awk '{print $2}' |grep "$name"`
        do
        	virsh destroy $i &>/dev/null
        	echo -e "   虚拟机[ ${green_col}${i}${reset_col} ]已停止...."
        done
}

delete_vm(){
		virsh list --all
		echo -e "${red_col}(1)不支持直接删除带有快照的虚拟机\n要想删除请先删除快照"
		echo -e "(2)支持模糊虚拟机名输入，但可能会操作多台虚拟机,\n请注意，以避免删除所有虚拟机!!!"
		echo -e "\n提示:\n(1)删除部分虚拟机请输入名字!!! \n(2)删除所有虚拟机请回车!!!${reset_col}\n"
		read -p "请输入准备删除的虚拟机名:" name
		for i in `virsh list --all |awk '{print $2}' |grep "$name"`
		do
			virsh destroy $i &>/dev/null
			virsh undefine $i &>/dev/null
			rm -rf ${vm_img_dir}/${i}.qcow2 
        		echo -e "   虚拟机[ ${green_col}${i}${reset_col} ]已删除...."
		done
}

qurry_vm(){
	echo -e "$red_col系统中所有虚拟机$reset_col"
	virsh list --all
}


modify_vm(){
modify_vm_menu(){
cat<<EFO
+++++++++++++++++++++++++++++++++++++
+	      配置虚拟机            +
+++++++++++++++++++++++++++++++++++++
+           1.配置虚拟机  	    +
+ 	    2.dhcp配置虚拟机	    +
+ 	    q.返回主菜单   	    +
+			            +
+++++++++++++++++++++++++++++++++++++
EFO
}
	clear
	echo -e "\n$red_col使用本功能需要guestfish!!!\n$reset_col"
	modify_vm_menu
	echo -en "$blue_col请输入选择:${reset_col}" 
	read modify_choose
	case $modify_choose in
	1)
		virsh list --all
	  	read -p "请输入修改虚拟机的名字:" name
                num=`virsh list --all |awk '{print $2}' |grep "$name"|wc -l`
		read -p "请输入主机名:" new_hostname
                read -p "请输入主机的起始ip地址:" new_ip
		x=`echo $new_ip|sed -r "s/(.*)[.](.*)[.](.*)[.](.*)/\4/"`
                echo -e "\n$red_col正在配置虚拟机，需要时间较久，请耐心等待$reset_col"   
	        for ((i=1;i<=$num;i++))
                do
                        final_hostname=`echo $new_hostname|sed -r "s/(.*)/\1$i.com/"`
			guestmount -a ${vm_img_dir}/${name}-${i}.qcow2 -i /mnt/
			sed -ri "/IPADDR/s/(.*)/IPADDR=$new_ip/" /mnt/etc/sysconfig/network-scripts/ifcfg-eth0
                        echo "${final_hostname}" > /mnt/etc/hostname
                        echo "$new_ip ${final_hostname}" >> /mnt/etc/hosts
                        umount -l /mnt
                        virsh define ${vm_xml_dir}/${name}-${i}.xml &>/dev/null
        		echo -e "   虚拟机[ ${green_col}${name}-${i}${reset_col} ]已配置完成...."
			x=$(($x+1))
                        new_ip=`echo $new_ip|sed -r "s/(.*)[.](.*)[.](.*)[.](.*)/\1.\2.\3.$x/"`
                done
	  ;;
	2)
		virsh list --all
	  	read -p "请输入修改虚拟机的名字:" name
                num=`virsh list --all |awk '{print $2}' |grep "$name"|wc -l`
		read -p "请输入主机名:" new_hostname
                echo -e "\n$red_col正在配置虚拟机，需要时间较久，请耐心等待$reset_col"   
	        for ((i=1;i<=$num;i++))
                do
                        final_hostname=`echo $new_hostname|sed -r "s/(.*)/\1$i.com/"`
			guestmount -a ${vm_img_dir}/${name}-${i}.qcow2 -i /mnt/
			sed -ri "/IPADDR/d" /mnt/etc/sysconfig/network-scripts/ifcfg-eth0
			sed -ri "/PREFIX/d" /mnt/etc/sysconfig/network-scripts/ifcfg-eth0
			sed -ri "/NETMASK/d" /mnt/etc/sysconfig/network-scripts/ifcfg-eth0
			sed -ri "/GATEWAY/d" /mnt/etc/sysconfig/network-scripts/ifcfg-eth0
			sed -ri "/DNS/d" /mnt/etc/sysconfig/network-scripts/ifcfg-eth0
			sed -ri "/BOOTPROTO/s/(.*)/BOOTPROTO=dhcp/" /mnt/etc/sysconfig/network-scripts/ifcfg-eth0
                        echo "${final_hostname}" > /mnt/etc/hostname
                        umount -l /mnt
                        virsh define ${vm_xml_dir}/${name}-${i}.xml &>/dev/null
        		echo -e "   虚拟机[ ${green_col}${name}-${i}${reset_col} ]已配置完成...."
                done
	  ;;
	q)
		:      
	  ;;
	*)
		echo -e "$red_col input error! ${reset_col}"
	  ;;

	esac
}


clone_vm(){
	virsh list --all
	read -p "请输入准备克隆虚拟机的名字:" name
	read -p "请输入克隆后的名字[默认vm-clone]:" clone_name
	if [ -z $clone_name ] 
	then
		clone_name=${name}-clone
	fi
	virsh domstate $name
	virt-clone -o $name -n $clone_name -f ${vm_img_dir}/${clone_name}.qcow2 
}

snap_vm(){
# default  use virt
snap_vm_menu(){
cat<<EFO
+++++++++++++++++++++++++++++++++++++
+	      快照管理              +
+++++++++++++++++++++++++++++++++++++
+          1.查看虚拟机快照         +
+          2.创建快照               +
+          3.恢复快照               +
+          4.删除快照		    +
+ 	   q.返回主菜单   	    +
+			            +
+++++++++++++++++++++++++++++++++++++
EFO
}
	while :
	do
	snap_vm_menu
	echo -en "$blue_col 请输入选择:${reset_col}" 
	read snap_choose
	case $snap_choose in
	1)      #list snap
		virsh list --all
		read -p"请输入要查看快照的虚拟机名:" name 
		virsh snapshot-list $name
	;;
	2)	#create snap
		snap_name=
		virsh list --all 
		read -p"请输入要创建快照的虚拟机名:" name  
		read -p "inpu the snapshot name:" snap_name
		if [ -z $snap_name]
		then
			snap_name=${name}-snap
		fi
		virsh snapshot-create-as $name $snap_name		
	;;
	3)	#revert snap	
		name=
		snap_name=
		virsh list --all
		read -p"请输入要恢复快照的虚拟机名:" name  
		read -p"input the revert snapshot name:" snap_name 
		virsh snapshot-revert $name $snap_name
	;;
	4)	#delete snap
		name=
		snap_name=
		virsh list --all
		read -p"请输入要删除快照的虚拟机名:" name  
		read -p"input the delete snapshot name:" snap_name 
		virsh snapshot-delete $name $snap_name
	;;
	q)
		break      
	  ;;
	*)
		echo -e "$red_col input error! ${reset_col}"
	  ;;
	esac
	any_key
	done
}

hadware_vm(){
hadware_vm_menu(){
cat<<EFO
+++++++++++++++++++++++++++++++++++++
+	      硬件管理              +
+++++++++++++++++++++++++++++++++++++
+          1.查看镜像文件信息       +
+     	   2.添加磁盘               +
+          3.移除磁盘               +
+          4.网卡信息查询           +
+          5.添加网卡		    +
+          6.删除网卡	            +
+ 	   q.返回主菜单   	    +
+			            +
+++++++++++++++++++++++++++++++++++++
EFO
}
	while :
	do
	hadware_vm_menu
	echo -en "$blue_col 请输入选择:${reset_col}" 
	read hadware_choose
	case $hadware_choose in
	1)  #qurry image
		virsh list --all
		read -p"input qurry VM name:" name
		virsh domblklist $name		 
	  ;;
	2)   #add image
		virsh list --all
		read -p"请输入要添加磁盘的虚拟机名[默认vm-add]:" name
		read -p"input add image size[默认2G]:" image_size
		if [ -z $image_size ]
		then
			image_size=2G
		fi
		qemu-img create -f qcow2 ${vm_img_dir}/${name}-add.qcow2  $image_size
		virsh attach-disk $name --source ${vm_img_dir}/${name}-add.qcow2 --target vdb --cache writeback --subdriver qcow2 --persistent
	  ;;
	3)   # remove image
		virsh list --all
		read -p"input remove img of VM name:" name	
		virsh domblklist $name		 
		virsh detach-disk $name vdb --persistent
		echo -e "${blue_col}${vm_img_dir}/${name}-add.qcow2 未删除${reset_col}"
		virsh domblklist $name		 
	  ;;
	4)
		virsh list --all
		read -p"input list net-interface VM name:" name	
	  	virsh domiflist $name
	  ;;
	5)
		virsh list --all
		read -p"input add net-interface VM name:" name
	  	virsh attach-interface $name --type bridge --source virbr0 --persistent
		virsh start $name 2>/dev/null
        	sleep 1
                read -p "输入${name}eth0网卡ip:" oip 
		echo "${red_clo}网卡名为ens9 \n网卡默认设置为dhcp ${reset_col}" 
	  	ssh $oip <<EFO
nmcli connection add con-name ens9 ifname ens9 type ethernet autoconnect yes ipv4.method auto
systemctl restart network 2>/dev/null
EFO
	  ;;
	6)	
		virsh list --all
		read -p"input del net-interface VM name:" name
		virsh start $name 2 >/dev/null
		echo -e "${red_col}删除的是非eth0网卡$reset_col"
                read -p "输入${name}eth0网卡ip:" oip 
		sleep 1
	  	ssh ${oip} "ifconfig" | awk -F: '/mtu/{print $1}' | grep -v lo | grep -v eth0
                read -p"input the delete ifconfig name:" ifconfig_name
		
		ifconfig_mac=`ssh $oip "ifconfig $ifconfig_name" |awk '/ether/{print $2}'`
		ssh $oip "rm -rf /etc/sysconfig/network-scripts/ifcfg-${ifconfig_name}"
		virsh detach-interface ${name} --type bridge  --mac ${ifconfig_mac} --persistent
	  ;;
	
	q)
		break      
	  ;;
	*)
		echo -e "$red_col input error ! ${reset_col}"
	  ;;
	esac
	any_key
	done
}

main_menu(){
cat<<EFO
+++++++++++++++++++++++++++++++++++++
+            kvm-manager            +
+++++++++++++++++++++++++++++++++++++
+           1.创建虚拟机	    +
+	    2.启动虚拟机	    +
+	    3.列出所有虚拟机	    +
+	    4.停止虚拟机	    +
+	    5.删除虚拟机	    +
+	    6.修改虚拟机	    +
+	    7.克隆管理		    +
+	    8.快照管理		    +
+	    9.硬件管理		    +
+	    q.退出脚本		    +
+                                   +
+++++++++++++++++++++++++++++++++++++
EFO
}



###main fuction
while :
do
	clear
	main_menu
	echo -en "${blue_col}请输入选择[h 显示菜单]:${reset_col}"
	read main_choose
	case $main_choose in
	1)
		create_vm	
	;;	
	2)
		start_vm	
	;;	
	3)	
		qurry_vm      
	  ;;
	4)
		stop_vm	
	;;	
	5)	
		delete_vm		
	;;	
	6)
		modify_vm	
	;;	
	7)	
		clone_vm      
	  ;;
	8)	
		snap_vm
	  ;;
	9)	
		hadware_vm      
	  ;;
	h)	
		:      
	  ;;
	q)	
		echo -en "\n\n$red_col感谢使用kvm-manager管理虚拟机$reset_col\n\n"
		exit      
	  ;;
	*)
		echo -e "$red_col input error! ${reset_col}"
	  ;;
	esac
	any_key
done

