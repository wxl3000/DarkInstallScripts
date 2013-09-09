#!/bin/bash
#Copyright (C) Tropo 2013
#Gateway Build Automatically
#Name:runtime_build.sh

DEBUG_MODE=false
HOST_TYPE="trial-runtime"
FTP_CLIENT_FILE_NAME="ftp-0.17-38.el5.x86_64.rpm"
FTP_SERVER_TEST_TOOL="nc-1.84-10.fc6.x86_64.rpm"
YUM_PRIORITIES_PACKAGE="yum-priorities-1.1.16-21.el5.centos.noarch.rpm"
MANIFEST_NAME="release-manifest.txt"
SCRIPT_NAME="bootstrap.sh"

usage(){
	echo -e "\e[33m Usage: ${0} [-d <DEBUG_MODE>] [-h <HELP>] JSON_FILE_ADDRESS\e[m"
	echo -e "\e[33m \t-d Turn the debug mode on \e[m"
	echo -e "\e[33m \t-h Help Informatino \e[m"
	echo -e "\e[33m \t<YOUR '.JSON' FILE ADDRESS> \e[m"
	exit 1
}

while getopts i:dh flag
do
	case ${flag} in
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
  ${DEBUG_MODE} && echo -e "\e[36mDEBUG:[${*}]\e[0m"
}

selinux_shutdown(){
  setenforce 0
}

yum_priorities_install(){
    rpm -qa |grep yum-priorities > /dev/null
    if [[ ${?} == 1 ]]
    then
       if [[ -e ${YUM_PRIORITIES_PACKAGE} ]]
       then
           rpm -ivh ${YUM_PRIORITIES_PACKAGE}
       else
           echo -e "\e[31m Couldn't find yum-priorities package, please change to your uncompressed directory\e[0m"
       fi
    fi
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


if [[ -z ${JSON_FILE_ADDRESS} ]]
then
    usage
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

selinux_shutdown
ftp_client_install
yum_priorities_install
file_transfer

if [[ ${DEBUG_MODE} = true ]]
then
    sh ${SCRIPT_NAME} -d -m ${MANIFEST_NAME} ${HOST_TYPE}
    debug sh ${SCRIPT_NAME} -d -m ${MANIFEST_NAME} ${HOST_TYPE}
else
    sh ${SCRIPT_NAME} -m ${MANIFEST_NAME} ${HOST_TYPE}
    debug sh ${SCRIPT_NAME} -m ${MANIFEST_NAME} ${HOST_TYPE}
fi

rm -rf node.json

