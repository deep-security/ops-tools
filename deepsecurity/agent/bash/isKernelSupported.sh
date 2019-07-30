#!/bin/bash

# Description
# This script looks up the current kernel version and check if it is supported by Deep Security. 
# A webservice is called to find the currently support kernel. 
#
# You can call with the Deep Security version on the command line or 
# it will ask the installed DSA directly. 
# 
# Example with DSA version 12.0:
# ./isKernelSupported.sh 12.0
#
# Example autodetecting the currently installed DSA verison:
# ./isKernelSupported.sh 




KERNEL_SITE='https://c3utfermrk.execute-api.us-east-1.amazonaws.com/dev/';
dsaVersion='';
linuxPlatform='';
platform='';
majorVersion='';
latestVersion='';
kernelVersion=`uname -r`
### Main 
main()
{
  if [ -z ${1} ]; then
    getDSAVersion
  else
    dsaVersion=${1}
  fi
  platform_detect
  url="$KERNEL_SITE$linuxPlatform/$dsaVersion/$kernelVersion"
  echo $url
  latestVersion=`curl -f -s --ssl-reqd $url`
  if [ $? -ne 0 ]; then
    echo "Unsupported combination"
    exit -1
  fi
  echo "Supported Kernel"
  #Useful for debugging
  #echo "dsaVersion" $dsaVersion
  #echo "linuxPlatform" $linuxPlatform
  #echo "platform" $platform
  #echo "majorVersion" $majorVersion
}

### Get DSA Version
getDSAVersion()
{
  dsaVersion=`/opt/ds_agent/dsa_query -c GetPluginVersion | grep PluginVersion.core | cut -d ':' -f 2 | cut -d '.' -f 1-2`
  dsaVersion=`echo $dsaVersion | awk '{$1=$1};1'`
}



###PlatformDetection

# Detect Linux platform

platform_detect() {
 if !(type lsb_release &>/dev/null); then
    distribution=$(cat /etc/*-release | grep '^NAME' );
    release=$(cat /etc/*-release | grep '^VERSION_ID');
 else
    distribution=$(lsb_release -i | grep 'ID' | grep -v 'n/a');
    release=$(lsb_release -r | grep 'Release' | grep -v 'n/a');
 fi;
 if [ -z "$distribution" ]; then
    distribution=$(cat /etc/*-release);
    release=$(cat /etc/*-release);
 fi;

 releaseVersion=${release//[!0-9.]};
 case $distribution in
     *"Debian"*)
        platform='debian'; 
        if [[ $releaseVersion =~ ^7.* ]]; then
           majorVersion='7';
        elif [[ $releaseVersion =~ ^8.* ]]; then
           majorVersion='8';
        elif [[ $releaseVersion =~ ^9.* ]]; then
           majorVersion='9';
        fi;
        ;;

     *"Ubuntu"*)
        platform='ubuntu'; 
        if [[ $releaseVersion =~ ^14.* ]]; then
           majorVersion='14';
        elif [[ $releaseVersion =~ ^16.* ]]; then
           majorVersion='16';
        elif [[ $releaseVersion =~ ^18.* ]]; then
           majorVersion='18';
        fi;
        ;;

     *"SUSE"* | *"SLES"*)
        platform='suse';
        if [[ $releaseVersion =~ ^11.* ]]; then
           majorVersion='11';
        elif [[ $releaseVersion =~ ^12.* ]]; then
           majorVersion='12';
        fi;
        ;;

     *"Oracle"* | *"EnterpriseEnterpriseServer"*)
        platform='oracle';
        if [[ $releaseVersion =~ ^5.* ]]; then
           majorVersion='5'
        elif [[ $releaseVersion =~ ^6.* ]]; then
           majorVersion='6';
        elif [[ $releaseVersion =~ ^7.* ]]; then
           majorVersion='7';
        fi;
        ;;

     *"CentOS"*)
        platform='rhel';
        if [[ $releaseVersion =~ ^5.* ]]; then
           majorVersion='5';
        elif [[ $releaseVersion =~ ^6.* ]]; then
           majorVersion='6';
        elif [[ $releaseVersion =~ ^7.* ]]; then
           majorVersion='7';
        fi;
        ;;

     *"CloudLinux"*)
        platform='cloud';
        if [[ $releaseVersion =~ ^6.* ]]; then
           majorVersion='6';
        elif [[ $releaseVersion =~ ^7.* ]]; then
           majorVersion='7';
        fi;
        ;;

     *"Amazon"*)
        platform='amazon';
        if [[ $(uname -r) == *"amzn2"* ]]; then
           majorVersion='2';
        elif [[ $(uname -r) == *"amzn1"* ]]; then
           majorVersion='1';
        fi;
        ;;

     *"RedHat"* | *"Red Hat"*)
        platform='rhel';
        if [[ $releaseVersion =~ ^5.* ]]; then
           majorVersion='5';
        elif [[ $releaseVersion =~ ^6.* ]]; then
           majorVersion='6';
        elif [[ $releaseVersion =~ ^7.* ]]; then
           majorVersion='7';
        elif [[ $releaseVersion =~ ^8.* ]]; then
           majorVersion='8';
        fi;
        ;;

 esac

 if [[ -z "${platform}" ]] || [[ -z "${majorVersion}" ]]; then
    echo Unsupported platform is detected
    logger -t Unsupported platform is detected
    false
 else
    archType='/32'; architecture=$(arch);
    if [[ ${architecture} == *"x86_64"* ]]; then
       archType='/64';
    fi

    linuxPlatform=$platform$majorVersion$archType;
 fi
}

###End PlatformDetection

main "$@"