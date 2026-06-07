#!/bin/bash

###parse command line arguments
PASSWORD="qaz123.."
ROSACCOUNT="123"
ROSPASSWD="123"
ROS_VER=""
IMAGE_SOURCE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--password)
            PASSWORD="$2"
            shift 2
            ;;
        -a|--ros-account)
            ROSACCOUNT="$2"
            shift 2
            ;;
        -r|--ros-password)
            ROSPASSWD="$2"
            shift 2
            ;;
        -v|--version)
            ROS_VER="$2"
            shift 2
            ;;
        -i|--image)
            IMAGE_SOURCE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -p, --password PASSWORD       Set ROS admin password (default: qaz123..)"
            echo "  -a, --ros-account ACCOUNT     Set ROS license account (default: 123)"
            echo "  -r, --ros-password PASSWORD   Set ROS license password (default: 123)"
            echo "  -v, --version VERSION         Set ROS version (default: latest stable)"
            echo "  -i, --image SOURCE            Use local image file or image URL instead of default download"
            echo "  -h, --help                    Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

###install needed command
echo '---install curl wget gzip---'
INSTALL_STATUS=0
if [ -f /etc/os-release ]; then
    distro=`awk -F '=|"' '/^NAME=/{print $3}' /etc/os-release`
    case $distro in
        'CentOS Linux' | 'Oracle Linux' | 'Amazon Linux' )
            echo 'yum -y -q install curl wget gzip rsync gdisk dosfstools'
            yum check-update
            yum -y -q install curl wget gzip rsync gdisk dosfstools
            INSTALL_STATUS=$?
            ;;
        'Ubuntu' | 'Debian GNU/Linux')
            echo 'apt-get -y -q install curl wget gzip rsync gdisk dosfstools'
            #apt-get --allow-releaseinfo-change update
            apt-get update
            apt-get -y -q install curl wget gzip rsync gdisk dosfstools
            INSTALL_STATUS=$?
            ;;
        'Fedora' | 'Rocky Linux')
            echo 'dnf -y -q install curl wget gzip rsync gdisk dosfstools'
            dnf check-update
            dnf -y -q install curl wget gzip rsync gdisk dosfstools
            INSTALL_STATUS=$?
            ;;
        *)
            echo 'Unsupported distribution, skip tools installation and continue.'
            INSTALL_STATUS=1
            ;;
    esac
    [ $INSTALL_STATUS -ne 0 ] && echo 'Tools installation failed or skipped, continue best-effort. Critical commands will stop the script if required tools are missing.'
else
    echo '/etc/os-release does not exist, skip tools installation and continue.'
fi

###check vps basic infomation
echo '---vps basic information---'
#ethernet interface
ETHERS=(`ls /sys/class/net/ | grep -v "\`ls /sys/devices/virtual/net/\`"`)
echo "ethernet interface : ${ETHERS[*]}"

#ip addresses
#caution: not support that one interface has more than one address
MAC=()
ADDR=()
ADDR6=()
for (( i=0; i<${#ETHERS[@]}; i++ ))
do 
    MAC[$i]=`ip link show ${ETHERS[$i]} | awk '/link\/ether/ {print toupper($2)}'`
    ADDR[$i]=`ip address show ${ETHERS[$i]} | awk '$0 ~ "inet .*global" {print$2}'`
    ADDR6[$i]=`ip address show ${ETHERS[$i]} | awk '$0 ~ "inet6 .*global" {print$2}'`
    echo "    ${ETHERS[$i]} : mac=${MAC[$i]}; ipv4=${ADDR[$i]}; ipv6=${ADDR6[$i]}"
done

#gateway
GATEWAY=`ip route list | grep "^default via" | grep -v "\`ls /sys/devices/virtual/net\`" | awk '{print $3}'`
echo "gateway : $GATEWAY"

#gateway ipv6
GATE6=()
GATE6DEV=()
ROUTE6=(`ip -6 route list | awk '/^default via/ {print $3","$5}'`)
for (( i=0; i<${#ROUTE6[@]}; i++ ))
do 
    GATE6[$i]=${ROUTE6[$i]%,*}
    TMPDEV=${ROUTE6[$i]#*,}
    for (( j=0; j<${#ETHERS[@]}; j++ ))
    do 
        if [ "$TMPDEV" = ${ETHERS[$j]} ]; then
            GATE6DEV[$i]=$j
            break
        fi
    done
    echo "gateway6 : ${GATE6[$i]} dev $TMPDEV interface index ${GATE6DEV[$i]}"
done

#disk
DSTDISK=`lsblk -o PKNAME,MOUNTPOINT | awk '$2 == "/" {print $1}'`
echo "disk : $DSTDISK"
echo '---'

#read -r -p "VPS basic information above is correct? [Y/n]:" input
#case $input in
#  [yY][eE][sS]|[yY])  
#    ;;
#  *) 
#    echo 'Exit for wrong vps information!'; 
#    exit 1
#    ;;
#esac

###check ros config data
echo '---ROS private config data---'

#ros license account
#ROSACCOUNT and ROSPASSWD are now set via command line parameters (-a/-r or --ros-account/--ros-password)
#Default value is "123" if not provided
#[ -z "$ROSACCOUNT" ] && read -r -p "Input ROS license account:" ROSACCOUNT
#[ -z "$ROSPASSWD" ] && read -r -p "Input ROS license password:" ROSPASSWD

#access config
#PASSWORD is now set via command line parameter (-p or --password)
#[ -z "$PASSWORD" ] && read -r -p "Input ROS admin password:" PASSWORD

SSHPORT="22"
WINBOXPORT="8291"
#[ -z "$SSHPORT" ] && read -r -p "Input ROS ssh port:" SSHPORT
#[ -z "$WINBOXPORT" ] && read -r -p "Input ROS winbox port:" WINBOXPORT

DNSSVR="1.1.1.1,1.0.0.1"
#[ -z "$DNSSVR" ] && read -r -p "Input ROS dns server:" DNSSVR

#echo '---'
#echo "ROS license user: $ROSACCOUNT ; pass: $ROSPASSWD"
#echo "ROS admin password: $PASSWORD"
#echo "ROS ssh port: $SSHPORT ; winbox port: $WINBOXPORT"
#echo "ROS dns server: $DNSSVR"
#echo '---End of ROS private config data---'
#read -r -p "ROS config data above is correct? [Y/n]:" input
#case $input in
#  [yY][eE][sS]|[yY])  
#    ;;
#  *) 
#    echo 'Exit for wrong ROS config data!'; 
#    exit 1
#    ;;
#esac

#######download and extract ROS image zip file
#ros version
get_latest_ros_version() {
    local rss_url
    local rss_content
    local latest_version
    local rss_urls=(
        "https://cdn.mikrotik.com/routeros/latest-stable.rss"
        "https://download.mikrotik.com/routeros/latest-stable.rss"
        "https://cdn.mikrotik.com/routeros/latest-stable-and-long-term.rss"
        "https://download.mikrotik.com/routeros/latest-stable-and-long-term.rss"
    )

    for rss_url in "${rss_urls[@]}"; do
        rss_content=`curl -fsSL "$rss_url" 2>/dev/null`
        [ $? -ne 0 -o -z "$rss_content" ] && continue

        latest_version=`printf '%s\n' "$rss_content" \
            | grep -Eoi 'RouterOS v?[0-9]+(\.[0-9]+){1,2}([[:alpha:]]+[0-9]+)?[[:space:]]*\[stable\]' \
            | head -n 1 \
            | grep -Eo '[0-9]+(\.[0-9]+){1,2}([[:alpha:]]+[0-9]+)?' \
            | head -n 1`

        [ -n "$latest_version" ] && echo "$latest_version" && return 0
    done

    return 1
}

is_url() {
    echo "$1" | grep -Eq '^[a-zA-Z][a-zA-Z0-9+.-]*://'
}

detect_ros_version_from_source() {
    local source_name
    source_name="${1%%\?*}"
    source_name="${source_name##*/}"
    echo "$source_name" \
        | grep -Eo '[0-9]+(\.[0-9]+){1,2}([[:alpha:]]+[0-9]+)?' \
        | head -n 1
}

extract_or_copy_ros_image() {
    local source_file="$1"
    local lower_source_file

    if gzip -t "$source_file" >/dev/null 2>&1; then
        gunzip -c "$source_file" > /mnt/img/chr.img
        return $?
    fi

    lower_source_file=`printf '%s' "$source_file" | tr '[:upper:]' '[:lower:]'`
    case "$lower_source_file" in
        *.zip|*.gz|*.gzip)
            return 1
            ;;
    esac

    cp "$source_file" /mnt/img/chr.img
    return $?
}

if [ -n "$IMAGE_SOURCE" ]; then
    if [ -z "$ROS_VER" ]; then
        ROS_VER=`detect_ros_version_from_source "$IMAGE_SOURCE"`
    fi

    if [ -n "$ROS_VER" ]; then
        echo "ROS image version (custom image): $ROS_VER"
    else
        echo "ROS image version (custom image): unknown, assuming RouterOS 7+ config behavior"
    fi
elif [ -z "$ROS_VER" ]; then
    ROS_VER=`get_latest_ros_version`
    [ $? -ne 0 -o -z "$ROS_VER" ] && echo 'Failed to get latest stable RouterOS version!' && exit 1
    echo "ROS image version (latest): $ROS_VER"
else
    echo "ROS image version (specified): $ROS_VER"
fi

#prepare image file in ramfs
mkdir -p /mnt/img
mount -t ramfs rampart /mnt/img
[ $? -ne 0 ] && echo 'Mount ramfs failed!' && exit 1

if [ -n "$IMAGE_SOURCE" ]; then
    if is_url "$IMAGE_SOURCE"; then
        echo "Downloading ROS image from URL: $IMAGE_SOURCE"
        SOURCE_IMAGE_FILE="${IMAGE_SOURCE%%\?*}"
        SOURCE_IMAGE_FILE="${SOURCE_IMAGE_FILE##*/}"
        [ -z "$SOURCE_IMAGE_FILE" ] && SOURCE_IMAGE_FILE="routeros.img"
        SOURCE_IMAGE_FILE="chr-source-$SOURCE_IMAGE_FILE"
        wget "$IMAGE_SOURCE" -O "$SOURCE_IMAGE_FILE"
        [ $? -ne 0 ] && echo 'ROS image URL download failed!' && exit 1
    else
        [ ! -r "$IMAGE_SOURCE" ] && echo "Local ROS image file is not readable: $IMAGE_SOURCE" && exit 1
        SOURCE_IMAGE_FILE="$IMAGE_SOURCE"
    fi
else
    SOURCE_IMAGE_FILE="chr.img.zip"
    wget https://download.mikrotik.com/routeros/${ROS_VER}/chr-${ROS_VER}.img.zip -O "$SOURCE_IMAGE_FILE"
    [ $? -ne 0 ] && echo 'ROS image zip file download failed!' && exit 1
fi

extract_or_copy_ros_image "$SOURCE_IMAGE_FILE"
[ $? -ne 0 ] && echo 'Error on prepare image file!' && exit 1

########modify image
###losetup loop device
LOOPDEV=`losetup --show -f -P /mnt/img/chr.img 2>/dev/null`
[ $? -ne 0 -o -z "$LOOPDEV" ] && echo 'losetup failed!' && exit 1
mkdir -p /mnt/ros

###uefi boot partition,convert to Hybrid MBR,format to FAT16 
if [ -d /sys/firmware/efi ]; then
    BOOTPART=`ls $LOOPDEV?* 2>/dev/null | awk 'NR == 1 {print $1}'`
    [ -z "$BOOTPART" ] && echo 'boot partition is null!' && exit 1
    
    mount $BOOTPART /mnt/ros
    [ $? -ne 0 ] && echo "Boot partition mount failed!" && exit 1

    [ -d ./efidata ] && rm -rf ./efidata/*
    mkdir -p ./efidata
    rsync -a /mnt/ros/ ./efidata/
    umount /mnt/ros
    
    #convert to uefi FAT16
    #from https://github.com/tikoci/fat-chr/blob/main/build.bash It works, but it is wired to change efi partition to linux file system
    #echo -e "2\nt\n1\n8300\nr\nh\n1 2\nn\n\ny\n\nn\nn\nw\ny\n" | gdisk $LOOPDEV
    #keep efi partition and make hybrid MBR in which the first partition is linux file system
    echo -e "2\nr\nh\n1 2\nn\n83\ny\n\nn\nn\nw\ny\n" | gdisk $LOOPDEV
    mkfs.fat -F 16 $BOOTPART
    
    mount $BOOTPART /mnt/ros
    rsync -a ./efidata/ /mnt/ros/ 
    umount /mnt/ros
fi

###write to config file
#mount img
LOOPPART=`ls $LOOPDEV?* 2>/dev/null | awk 'END {print $1}'`
[ -z "$LOOPPART" ] && echo 'Partition is null!' && exit 1
mount $LOOPPART /mnt/ros
[ $? -ne 0 ] && echo "Mount failed!" && exit 1

echo 'Writing to autorun.scr...'

VER_6=`echo $ROS_VER | grep "^6"`

#writing to auto config script
cat > /mnt/ros/rw/autorun.scr <<EOF
/ip service disable telnet,ftp,www,api,api-ssl
/tool mac-server set allowed-interface-list=none
/ip neighbor discovery-settings set discover-interface-list=none
/ip dhcp-client disable [find]
EOF

#password
[ -n "$PASSWORD" ] && echo "/user set 0 name=admin password=$PASSWORD" >> /mnt/ros/rw/autorun.scr

#access port
[ -n "$SSHPORT" ] && echo "/ip service set ssh port=$SSHPORT" >> /mnt/ros/rw/autorun.scr
[ -n "$WINBOXPORT" ] && echo "/ip service set winbox port=$WINBOXPORT" >> /mnt/ros/rw/autorun.scr

#config dns
[ -n "$DNSSVR" ] && echo "/ip dns set servers=$DNSSVR" >> /mnt/ros/rw/autorun.scr

#echo "/ip dns set servers=223.5.5.5,119.29.29.29" >> /mnt/ros/rw/autorun.scr
#echo "/ip dns static add cname=upgrade.mikrotik.app name=upgrade.mikrotik.com type=CNAME" >> /mnt/ros/rw/autorun.scr
#echo "/ip dns static add cname=licence.mikrotik.app name=licence.mikrotik.com type=CNAME" >> /mnt/ros/rw/autorun.scr

#ip address
echo ":local intfName" >> /mnt/ros/rw/autorun.scr
for (( i=0; i<${#ETHERS[@]}; i++ ))
do 
    echo ":set intfName [ /interface get value-name=name number=[ find where mac-address=${MAC[$i]} ] ] " >> /mnt/ros/rw/autorun.scr
    [ -n "${ADDR[$i]}" ] && echo "/ip address add address=${ADDR[$i]} interface=\$intfName" >> /mnt/ros/rw/autorun.scr
    [ -n "${ADDR6[$i]}" -a -z "$VER_6" ] && echo "/ipv6 address add address=${ADDR6[$i]} interface=\$intfName" >> /mnt/ros/rw/autorun.scr
done

#gateway
[ -n "$GATEWAY" ] && echo "/ip route add gateway=$GATEWAY" >> /mnt/ros/rw/autorun.scr

#gateway ipv6
if [ -z "$VER_6" ]; then
    for (( i=0; i<${#GATE6[@]}; i++ ))
    do 
        macaddr=${MAC[${GATE6DEV[$i]}]}
        echo ":set intfName [ /interface get value-name=name number=[ find where mac-address=$macaddr ] ] " >> /mnt/ros/rw/autorun.scr
        echo "/ipv6 route add gateway=\"${GATE6[$i]}%\$intfName\" " >> /mnt/ros/rw/autorun.scr
    done
fi

#license
if [ -n "$ROSACCOUNT" -a -n "$ROSPASSWD" ]; then
cat >> /mnt/ros/rw/autorun.scr <<EOF
#renew license
/delay 3s
/system license renew account=$ROSACCOUNT password=$ROSPASSWD level=p-unlimited
EOF
fi

if [ -n "$VER_6" ]; then
cat >> /mnt/ros/rw/autorun.scr <<EOF
#upgrade
/system package update set channel=upgrade
/system package update check-for-updates once
:delay 3s;
:if ( [/system package update get status] = "New version is available") do={ /system package update install }
EOF
fi

sync
umount /mnt/ros

###release loop device
losetup -d $LOOPDEV
sync

########dd
echo 'dd starting'
echo u > /proc/sysrq-trigger
dd if=/mnt/img/chr.img of=/dev/$DSTDISK bs=1M oflag=sync
echo '---'
echo 'Installation completed!'
echo "Username: admin"
echo "Password: $PASSWORD"
echo '---'
echo 'Please reboot your device.'
echo b > /proc/sysrq-trigger
