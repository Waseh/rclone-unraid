#!/bin/bash

if [ "$1" = "2" ]; then
   rcloneurl="https://beta.rclone.org/rclone-beta-latest-linux-amd64.zip"
else
   rcloneurl="https://downloads.rclone.org/rclone-current-linux-amd64.zip"
fi;

ping -q -c2 8.8.8.8 >/dev/null
if [ $? -eq 0 ]
then
  echo "Downloading rclone"
  curl --connect-timeout 8 --retry 3 --retry-delay 2 --retry-max-time 30 -o /boot/config/plugins/rclone/install/rclone-current.zip $rcloneurl

  echo "Downloading certs"
  curl --connect-timeout 8 --retry 3 --retry-delay 2 --retry-max-time 30 -o /boot/config/plugins/rclone/install/ca-certificates.new.crt https://raw.githubusercontent.com/bagder/ca-bundle/master/ca-bundle.crt
else
  ping -q -c2 1.1.1.1 >/dev/null
  if [ $? -eq 0 ]
  then
    echo "Downloading rclone"
    curl --connect-timeout 15 --retry 3 --retry-delay 2 --retry-max-time 30 -o /boot/config/plugins/rclone/install/rclone-current.zip $rcloneurl

    echo "Downloading certs"
    curl --connect-timeout 15 --retry 3 --retry-delay 2 --retry-max-time 30 -o /boot/config/plugins/rclone/install/ca-certificates.new.crt https://raw.githubusercontent.com/bagder/ca-bundle/master/ca-bundle.crt
  else
    echo "No internet - Could not fetch new version"
    exit 1
  fi
fi;

if [ -f /boot/config/plugins/rclone/install/ca-certificates.new.crt ]; then
  rm -f $(ls /boot/config/plugins/rclone/install/ca-certificates.crt 2>/dev/null)
  mv /boot/config/plugins/rclone/install/ca-certificates.new.crt /boot/config/plugins/rclone/install/ca-certificates.crt
fi;

if [ -f /boot/config/plugins/rclone/install/rclone-current.zip ]; then
  unzip /boot/config/plugins/rclone/install/rclone-current.zip -d /boot/config/plugins/rclone/install/
  rm -f $(ls /boot/config/plugins/rclone/install/rclone-current.old.zip 2>/dev/null)
  mv /boot/config/plugins/rclone/install/rclone-current.zip /boot/config/plugins/rclone/install/rclone-current.old.zip
fi;

if [ -f /boot/config/plugins/rclone/install/rclone-v*/rclone ]; then
  cp /boot/config/plugins/rclone/install/rclone-v*/rclone  /usr/sbin/rcloneorig
  if [ "$?" -ne "0" ]; then
	echo ""
	echo "-----------------------------------------------------------"
	echo "<font color='red'> Copy failed. Is rclone running? </font>"
	echo "-----------------------------------------------------------"
	echo ""
    if [ -d /boot/config/plugins/rclone/install/rclone-v*/ ]; then
      rm -rf /boot/config/plugins/rclone/install/rclone-v*/
    fi;
    rm -f $(ls /boot/config/plugins/rclone/install/rclone*.txz 2>/dev/null | grep -v '&bundleversion;')
    exit 1
  fi;
else
  echo "Unpack failed - Please try installing/updating the plugin again"
  rm -f $(ls /boot/config/plugins/rclone/install/rclone-current.old.zip 2>/dev/null)
  exit 1
fi;

if [ -d /boot/config/plugins/rclone/install/rclone-v*/ ]; then
  rm -rf /boot/config/plugins/rclone/install/rclone-v*/
fi;

chown root:root /usr/sbin/rcloneorig
chmod 755 /usr/sbin/rcloneorig

mkdir -p /etc/ssl/certs/
cp /boot/config/plugins/rclone/install/ca-certificates.crt /etc/ssl/certs/

echo ""
echo "-----------------------------------------------------------"
echo " rclone has been successfully updated "
echo "-----------------------------------------------------------"
echo ""