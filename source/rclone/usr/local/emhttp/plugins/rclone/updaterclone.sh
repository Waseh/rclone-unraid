#!/bin/bash

if [ "$1" = "2" ]; then
   rcloneurl="https://beta.rclone.org/rclone-beta-latest-linux-amd64.zip"
else
   rcloneurl="https://downloads.rclone.org/rclone-current-linux-amd64.zip"
fi;

version=`rcloneorig --version | head -n 1`
  echo "-------------------------------------------------------------------"
  echo "Validating connection to internet"
  echo "-------------------------------------------------------------------"
ping -q -c3 downloads.rclone.org >/dev/null
if [ $? -eq 0 ]
then
  echo "-------------------------------------------------------------------"
  echo "Updating rclone"
  echo "-------------------------------------------------------------------"
  curl --connect-timeout 15 --retry 3 --retry-delay 2 --retry-max-time 30 -o /boot/config/plugins/rclone/install/rclone.zip $rcloneurl
  unzip -o -j "/boot/config/plugins/rclone/install/rclone.zip" "*/rclone" -d "/boot/config/plugins/rclone/install"
  rm -f /boot/config/plugins/rclone/install/*.zip
  cp /boot/config/plugins/rclone/install/rclone /usr/sbin/rcloneorig.new
  mv /usr/sbin/rcloneorig.new /usr/sbin/rcloneorig
  chown root:root /usr/sbin/rcloneorig
  chmod 755 /usr/sbin/rcloneorig
else
  echo ""
  echo "-------------------------------------------------------------------"
  echo "<font color='red'> Connection error - Can't fetch new version </font>"
  echo "-------------------------------------------------------------------"
  echo ""
  exit 1
fi;

current_version=`rcloneorig --version | head -n 1`

if [[ $version = $current_version ]]; then
  echo ""
  echo "-------------------------------------------------------------------"
  echo "<font color='red'> Update failed - Please try again </font>"
  echo "-------------------------------------------------------------------"
  echo ""
  exit 1
fi;

echo ""
echo "-------------------------------------------------------------------"
echo " rclone has been successfully updated "
echo "-------------------------------------------------------------------"
echo ""