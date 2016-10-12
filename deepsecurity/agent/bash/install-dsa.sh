##one line DSA Linux install script

managerfqdn="$1"
managerconsoleport="$2"
policyid="$3"
tenantid="$5"
tenantpassword="$5"
distro=""
majversion=""
agentidstring=""
arch=$(uname -m)
if [ $arch == i686 ]
  then
    arch=i386
fi

##detect distros with systemd

if [ -f /etc/os-release ]
then
  . /etc/os-release
  distro=$ID
  majversion=${VERSION_ID:0:1}

  case $distro in
    rhel)
      echo "Redhat 7 detected"
      agentidstring="RedHat_EL7"
    ;;
    centos)
      echo "Centos 7 detected"
      agentidstring="RedHat_EL7"
    ;;
    amzn)
      echo "amazon detected"
      agentidstring="amzn1"
    ;;
    ol)
      echo "Oracle Linux detected"
      agentidstring="Oracle_OL7"
    ;;
    sles)
      majversion=${VERSION_ID:0:2}
        case $majversion in
	  11)
	    echo "SUSE 11 detected"
	    agentidstring="SuSE_11"
	    ;;
	  12)
	    echo "SUSE 12 detected"
	    agentidstring="SuSE_12"
	  ;;
	esac
	;;
    ubuntu)
      majversion=${VERSION_ID:0:2}
        case $majversion in
	  12)
	    echo "Ubuntu 12 detected"
	    agentidstring="Ubuntu_12.04"
	  ;;
	  14)
	    echo "Ubuntu 14 detected"
	    agentidstring="Ubuntu_14.04"
	  ;;
	esac
	;;
 
    *)
      echo "os-release detected but OS not implemented"
      exit 1
  esac
else
  #older than systemd
  #Oracle Linux
  if [ -f /etc/oracle-release ]
    then
      distro="ol"
      VERSION_ID=$(lsb_release -sr)
      majorversion=${VERSION_ID:0:1}
      case $majorversion in
        5)
          echo "Oracle Linux 5 Detected"
          agentidstring="Oracle_OL5"
        ;;
        6)
          echo "Oracle Linux 6 Detected"
	      agentidstring="Oracle_OL6"
	    ;;
      esac
    else
    #rhel and CentOS
    if [ -f /etc/redhat-release ]
      then
        distro="rhel"
        VERSION_ID=$(lsb_release -sr)
        majorversion=${VERSION_ID:0:1}
        case $majorversion in
	      5)
	        echo "RedHat 5 Detected"
	        agentidstring="RedHat_EL5"
	      ;;
	      6)
	        echo "RedHat 6 Detected"
	        agentidstring="RedHat_EL6"
	      ;;
        esac
      else
        #SUSE 10
        if [ -f /etc/SuSE-release ]
          then
	    distro="SuSE"
	    VERSION_ID=$(lsb_release -sr)
            majorversion=${VERSION_ID:0:2}
            echo "SuSE 10 Decteted"
	    agentidstring="SuSE_10"
	      else
	        echo "Failed to determine OS"
	        exit 1
	    fi
    fi
  fi
fi





#build deployment script
if [ ! -z $tenantid ]
  then
    $tenantid="\"tenantID:${tenantid}\""
    $tenantpassword="\"tenantPassword:${tenantpassword}\""
fi
if [ ! -z $policyid ]
  then
    $policyid="\"policyid:${policyid}\""
fi
echo "Downloading Agent from: "
echo "https://${managerfqdn}:${managerconsoleport}/software/agent/${agentidstring}/${arch}/ "
curl -k https://${managerfqdn}:${managerconsoleport}/software/agent/${agentidstring}/${arch}/ -o /tmp/agent.rpm
echo "Installing Agent"
if [ $distro == ubuntu ]
  then
    dpkg -i /tmp/agent.deb
  else
    rpm -ivh /tmp/agent.rpm
fi
sleep 15
/opt/ds_agent/dsa_control -r
echo "Activating Agent"
/opt/ds_agent/dsa_control -a dsm://${managerfqdn}:4120/ ${policyid} ${tenantid} ${tenantpassword}


