#!/bin/bash
#Copyright (C) Tropo 2013
#Gateway Build Automatically
#Name:gateway_build.sh

DEBUG_MODE=false
HOST_TYPE="trial-gateway"
FTP_CLIENT_FILE_NAME="ftp-0.17-38.el5.x86_64.rpm"
FTP_SERVER_TEST_TOOL="nc-1.84-10.fc6.x86_64.rpm"
MANIFEST_NAME="manifest"
SCRIPT_NAME="bootstrap.sh"

usage(){
	echo -e "\e[33m Usage: ${0} [-i <YUM_SERVER_IPADDRESS>] [-d <DEBUG_MODE>] [-h <HELP>] JSON_FILE_ADDRESS\e[m"
	echo -e "\e[33m \t-i Your YUM Server ip address \e[m"
	echo -e "\e[33m \t-d Turn the debug mode on \e[m"
	echo -e "\e[33m \t-h Help Information \e[m"
	echo -e "\e[33m \t<YOUR '.JSON' FILE ADDRESS> \e[m"
	exit 1
}

while getopts i:dh flag
do
	case ${flag} in
	i)
	    FTP_SERVER_IP=${OPTARG}
	    ;;
	d)
	    DEBUG_MODE=true
	    ;;
	h)
	    usage
	    exit 0 
	    ;;
	esac
done

shift $((OPTIND-1))
JSON_FILE_ADDRESS=${1}

have(){
    type $1 > /dev/null 2>&1
}

debug(){
  ${DEBUG_MODE} && echo -e ${*}
}

ftp_client_install(){
    if ! have /usr/bin/ftp
    then
	if [[ -e ${FTP_CLIENT_FILE_NAME} ]] 
	then
            rpm -ivh ${FTP_CLIENT_FILE_NAME}
	    debug rpm -ivh ${FTP_CLIENT_FILE_NAME}
	else
	    echo -e "\e[31m Ftp client file doesn't exist, please change to your uncompressed directory \e[m"
	    exit 2
	fi
    fi
}

ftp_server_test(){
    if ! have /usr/bin/nc
    then
        if [[ ! -e ${FTP_SERVER_TEST_TOOL} ]]
        then
       	    echo -e "\e[31m Ftp server test tool can not be found, please change to your uncompressed directory \e[m"	
	    exit 3
        fi
        rpm -ivh ${FTP_SERVER_TEST_TOOL}
	if [[ ! $(/usr/bin/nc -v -w1 ${FTP_SERVER_IP} -z 21 2>/dev/null |cut -d " " -f 7) =~ "succeeded!" ]]
        then
	    echo -e "\e[31m Ftp server connect failed, please make sure your Ftp server is working correctly \e[m"
	    exit 4
        fi
    else
        if [[ ! $(/usr/bin/nc -v -w1 ${FTP_SERVER_IP} -z 21 2>/dev/null |cut -d " " -f 7) =~ "succeeded!" ]]
        then
	    echo -e "\e[31m Ftp server connect failed, please make sure your Ftp server is working correctly \e[m"
	    exit 4
        fi
    fi
}

file_transfer(){
    if [[ -e ./chef ]]
    then
        if [[ ! -e /var/chef/ ]]
        then
	    echo -e "\e[32m File transfering... This will take a while \e[m"
	    cp -r ./chef /var/
	    debug cp -r ./chef /var/
        elif [[ -e /var/chef.bak-$(date +"%Y-%m-%d_%H") ]]
        then
            rm -rf /var/chef.bak-$(date +"%Y-%m-%d_%H")
            debug rm -rf /var/chef.bak-$(date +"%Y-%m-%d_%H")
            mv /var/chef /var/chef.bak-$(date +"%Y-%m-%d_%H")
            debug mv /var/chef /var/chef.bak-$(date +"%Y-%m-%d_%H")
            echo -e "\e[32m File transfering... This will take a while \e[m"
            cp -r ./chef /var/
            debug cp -r ./chef /var/
	else
            mv /var/chef /var/chef.bak-$(date +"%Y-%m-%d_%H")
	    debug mv /var/chef /var/chef.bak-$(date +"%Y-%m-%d_%H")
            echo -e "\e[32m File transfering... This will take a while \e[m"
	    cp -r ./chef /var/
	    debug cp -r ./chef /var/
	fi
    else
       echo -e "\e[31m Folder 'chef' doesn't exist, please change to your uncompressed directory \e[m" 
       exit 5
    fi
}

repo_file_create(){
	touch /etc/yum.repos.d/local.repo
    	debug touch /etc/yum.repos.d/local.repo
	cat <<EOF > /etc/yum.repos.d/local.repo
[local_base]
name=local_base
#fill with your own yum_server ip_address in the following line
baseurl=ftp://${FTP_SERVER_IP}/pub/base                  
gpgcheck=0
[local_updates]
name=local_updates
#fill with your own yum_server ip_address in the following line
baseurl=ftp://${FTP_SERVER_IP}/pub/updates                 
gpgcheck=0
[local_epel]
name=local_epel
#fill with your own yum_server ip_address in the following line
baseurl=ftp://${FTP_SERVER_IP}/pub/epel                   
gpgcheck=0
[local_vlabs]
name=local_voxeo-labs
#fill with your own yum_server ip_address in the following line
baseurl=ftp://${FTP_SERVER_IP}/pub/voxeo-labs            
gpgcheck=0 
EOF
	debug cat 
}

local_repo_file_build(){
	if [[ ! -e /etc/yum.repos.d/local.repo ]]
	then
		ls /etc/yum.repos.d/ | while read line
		do
			mv /etc/yum.repos.d/${line} /etc/yum.repos.d/${line}.bak
	    		debug mv /etc/yum.repos.d/${line} /etc/yum.repos.d/${line}.bak
		done
		repo_file_create
        else
		repo_file_create
	fi
}

chef_detect(){
  if have /usr/bin/chef-solo || have /opt/chef/bin/chef-solo
  then
    rpm -e chef
  fi
}

if [[ -z ${FTP_SERVER_IP} || -z ${JSON_FILE_ADDRESS} ]]
then
    usage
else
   if [[ ! ${FTP_SERVER_IP} =~ [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3} ]] 
   then
        echo -e "\e[31m Please enter a invalid ip address \e[m" 
        exit 6
   fi
fi

if [[ -f ${JSON_FILE_ADDRESS} ]]
then
    cp ${JSON_FILE_ADDRESS} ./node.json
    debug cp ${JSON_FILE_ADDRESS} ./node.json
else
    echo -e "\e[31m Your '.json' file doesn't exist, please check the file location and run it again  \e[m" 
    exit 7
fi

if [[ ! -e ${MANIFEST_NAME} ]]
then
    echo -e "\e[31m Your 'manifest' file doesn't exist in your current directory, please make sure it is in the same directory with your server_build script \e[m"
    exit 8
fi

ftp_client_install
ftp_server_test
local_repo_file_build 
file_transfer
chef_detect

if [[ ${DEBUG_MODE} = true ]]
then
    sh ${SCRIPT_NAME} -d -m ${MANIFEST_NAME} ${HOST_TYPE}
    debug sh ${SCRIPT_NAME} -d -m ${MANIFEST_NAME} ${HOST_TYPE}
else
    sh ${SCRIPT_NAME} -m ${MANIFEST_NAME} ${HOST_TYPE}
    debug sh ${SCRIPT_NAME} -m ${MANIFEST_NAME} ${HOST_TYPE}
fi
