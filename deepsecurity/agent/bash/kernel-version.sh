#!/bin/bash

# Prerequisite
#
# Deep Security Manager must be downloading the latest agent packages.
# This is when the latest kernel package support the kernel, the 
# latest kernel package is avaliable in the DSM for download.  
#

# Description
# This script detects which version of the Deep Security agent is installed, 
# which OS and makes a call to a webservice to find the current highest support kernel. 
# It then updates either yum or apt to prevent installing a kernel newer than DSA 
# currently support for that platform. 
#
# You can run this script daily or weekly to keep the kernel limit up to date. 
# It can be run from cron, manually, or any other automated process.
#


KERNEL_SITE='https://c3utfermrk.execute-api.us-east-1.amazonaws.com/dev/';
dsaVersion='';
linuxPlatform='';
isRPM='';
platform='';
majorVersion='';
latestVersion='';
subKernel='';

### Main 
main()
{
  platform_detect
  getDSAVersion
  getSubKernelType
  getLatestKernel
  updatelock $latestVersion
  #Useful for debugging
  #echo "dsaVersion" $dsaVersion
  #echo "linuxPlatform" $linuxPlatform
  #echo "isRPM" $isRPM
  #echo "platform" $platform
  #echo "majorVersion" $majorVersion
  #echo "latestVersion" $latestVersion
}
### Find a kernel subtype if there is one
getSubKernelType()
{
  aws=`uname -r | grep aws`
  gcp=`uname -r | grep gcp`
  azure=`uname -r | grep azure`
  k8s=`uname -r | grep k8s`
  if [ -z ${aws+x} ]; then
    if [ -z ${gcp+x} ]; then
      if [ -z ${azure+x} ]; then
        if [ -z ${k8s+x} ]; then
          subKernel=""
        else
          subKernel="k8s"
        fi
      else
        subKernel="azure"
      fi
    else
      subKernel="gcp"
    fi
  else
    subKernel="aws"
  fi

}

### Get DSA Version
getDSAVersion()
{
  dsaVersion=`/opt/ds_agent/dsa_query -c GetPluginVersion | grep PluginVersion.core | cut -d ':' -f 2 | cut -d '.' -f 1-2`
  dsaVersion=`echo $dsaVersion | awk '{$1=$1};1'`
}

### Get updated kernel version
getLatestKernel()
{
  if [ -z ${subKernel+x} ]; then
    url="$KERNEL_SITE$linuxPlatform/$dsaVersion"
  else
    url="$KERNEL_SITE$linuxPlatform/$dsaVersion?subtype=$subKernel"
  fi
  echo $url
  latestVersion=`curl -s --ssl-reqd $url | sed -e 's/^"//' -e 's/"$//'`

}

### locking functions
installVersionLock(){  
  if [[ $isRPM == 1 ]]; then 
    yum install -y yum-plugin-versionlock
  else 
    FILE=/etc/apt/preferences
    if [ ! -f $FILE ]; then 
      echo "# Deep Security Agent Pinning camptable kernel version" >> $FILE
      echo "# End Deep Security Pin" >> $FILE
    fi 
  fi
}

lockVersion(){
  if [[ $isRPM == 1 ]]; then 
    yum versionlock kernel-$1 
  
  fi
}

updatelock()
{
  echo "updating lock to $1"
  if [[ $isRPM == 1 ]]; then 
    FILE=/etc/yum/pluginconf.d/versionlock.list
    if [ -f "$FILE" ]; then
        sed -i 's/kernel-*/kernel-$1/' $FILE 
    else 
        installVersionLock
        lockVersion $1
    fi
  else
    FILE=/etc/apt/preferences
    installVersionLock $FILE
    KernelVersion_1=`echo $latestVersion | cut -d '-' -f 1`
    KernelVersion_2=`echo $latestVersion | cut -d '-' -f 2`
    KernelVersion=$KernelVersion_1.$KernelVersion_2
    if [ -z ${subKernel+x} ]; then
      KernelType="linux-generic"
    else
      KernelType="linux-$subKernel"
    fi
    
    awk "/# Deep Security Agent Pinning camptable kernel version/{p=1;print;print \"Package: $KernelType\nPin: version  $KernelVersion*\nPin-Priority: 1100\"}/# End Deep Security Pin/{p=0}!p" /etc/apt/preferences > /tmp/preferences.tmp
    mv /tmp/preferences.tmp /etc/apt/preferences
  fi
}
### end locking functions 




###PlatformDetection

# Detect Linux platform

platform_detect() {
 isRPM=1
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
        platform='debian'; isRPM=0;
        if [[ $releaseVersion =~ ^7.* ]]; then
           majorVersion='7';
        elif [[ $releaseVersion =~ ^8.* ]]; then
           majorVersion='8';
        elif [[ $releaseVersion =~ ^9.* ]]; then
           majorVersion='9';
        fi;
        ;;

     *"Ubuntu"*)
        platform='ubuntu'; isRPM=0;
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