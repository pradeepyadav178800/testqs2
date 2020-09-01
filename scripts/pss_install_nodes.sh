#!/bin/bash
set -x
echo "*** Phase 2-PSS installation Script Started at `date +'%Y-%m-%d_%H-%M-%S'` ***"

## Function for error handling
fail_if_error() {
  [ $1 != 0 ] && {
    echo $2
    exit 10
  }
}

### Lustre client installation 
echo "Installing kernel package"
VER="3.10.0-1062.9.1.el7"
yum install kernel-$VER kernel-devel-$VER kernel-headers-$VER kernel-abi-whitelists-$VER kernel-tools-$VER kernel-tools-libs-$VER kernel-tools-libs-devel-$VER -y
fail_if_error $? "ERROR: kernel package installation failed."

echo "Downloading and installing lustre packages "
mkdir -p /package
cd /package
wget https://downloads.whamcloud.com/public/lustre/lustre-2.12.4/el7.7.1908/client/RPMS/x86_64/lustre-client-2.12.4-1.el7.x86_64.rpm
wget https://downloads.whamcloud.com/public/lustre/lustre-2.12.4/el7.7.1908/client/RPMS/x86_64/kmod-lustre-client-2.12.4-1.el7.x86_64.rpm
yum localinstall *.rpm -y
fail_if_error $? "ERROR: Client installation failed."

yum install xorg-x11-xauth.x86_64 xorg-x11-server-utils.x86_64 dbus-x11.x86_64 -y
modprobe -v lustre
echo "Lustre client installed successfully, Now mouning the file system"

mkdir -p /opt/sas
mount -t lustre -o flock mgt@tcp:/lustre /opt/sas/
fail_if_error $? "ERROR: failed to mount lustre file system."

#/ect/fstab entry
echo "mgt@tcp:/lustre /opt/sas/ lustre flock,_netdev 0 0" >> /etc/fstab
lfs setstripe -S 64K -i -1 -c -1 /opt/sas
lctl set_param osc.\*.max_dirty_mb=256
lctl set_param osc.\*.max_rpcs_in_flight=16
chmod 777 /opt/sas

### Lustre client installation completed

SASInstallLoc="/opt/sas"
LSFInstallLoc="$SASInstallLoc/platform/lsf"
LSFBinDir=`ls -l $LSFInstallLoc | sed '2q;d' |  awk '{print $NF}'`

cd $LSFInstallLoc/$LSFBinDir/install ; ./hostsetup --top="$LSFInstallLoc" --boot="y" --profile="y"  --start="y"
fail_if_error $? "Error: LSF hostsetup utility failed"

if [ ! -f /etc/lsf.sudoers ]; then
   echo "LSF_STARTUP_PATH=$LSFInstallLoc/$LSFBinDir/linux2.6-glibc2.3-x86_64/etc" >> /etc/lsf.sudoers
   echo 'LSF_STARTUP_USERS="sasinst lsfadmin"' >> /etc/lsf.sudoers
fi

echo "*** Phase 2 - PSS installation Script Ended at `date +'%Y-%m-%d_%H-%M-%S'` ***"