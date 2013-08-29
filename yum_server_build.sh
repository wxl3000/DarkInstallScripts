#Copyright (C) Tropo 2013
#Yum Server Build Automatically
#Name:yum_server_build.sh

#!/bin/bash

VSFTP_FILE_NAME="vsftpd-2.0.5-28.el5.x86_64.rpm"
FTP_SERVER_DIR="/var/ftp/pub"

have(){
    type ${1} >/dev/null 2>&1
}

selinux_shutdown(){
  setenforce 0
}

#Install vsftp server
vsftp_install(){
    if ! have /usr/sbin/vsftpd	
    then
	if [[ -f ${VSFTP_FILE_NAME} ]]
	then
	    rpm -ivh ${VSFTP_FILE_NAME}
	    /sbin/service vsftpd start
	    /sbin/chkconfig --level 345 vsftpd on 
	else
	    echo -e "\e[33m Vsftpd package doesn't exist, please change to your uncompressed directory and run it again \e[m"
	    exit 1
	fi
    else
	if [[ $(/sbin/service vsftpd status |cut -d " " -f3) =~ stopped ]]
	then
	    /sbin/service vsftpd start
	fi
    fi
}


#File transfer
file_transfer(){
    if [[ -e ./yum ]]
    then
	if [[ -e ${FTP_SERVER_DIR} ]]
	then
            ls ./yum | while read line 
            do
                mv ./yum/$line ${FTP_SERVER_DIR}
            done
            rm -rf ./yum
	else
	   echo -e "\e[33m Your ftp server public directory <${FTP_SERVER_DIR}> doesn't exist, please create it for anonymous account and run it again \e[m" 
	   exit 2
	fi
    else
	echo -e "\e[33m Directory 'yum' doesn't exist, please change to your uncompressed directroy and run it again \e[m"
	exit 3
    fi
}

selinux_shutdown
vsftp_install
file_transfer

