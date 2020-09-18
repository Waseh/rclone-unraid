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
  curl --connect-timeout 15 --retry 3 --retry-delay 2 --retry-max-time 30 -o /boot/config/plugins/rclone/install/rclone-current.zip $rcloneurl
else
  ping -q -c2 1.1.1.1 >/dev/null
  if [ $? -eq 0 ]
  then
    echo "Downloading rclone"
    curl --connect-timeout 15 --retry 3 --retry-delay 2 --retry-max-time 30 -o /boot/config/plugins/rclone/install/rclone-current.zip $rcloneurl
  else
    echo "No internet - Could not fetch new version"
    exit 1
  fi
fi;

if [ -f /boot/config/plugins/rclone/install/rclone-current.zip ]; then
  unzip /boot/config/plugins/rclone/install/rclone-current.zip -d /boot/config/plugins/rclone/install/
  rm -f $(ls /boot/config/plugins/rclone/install/rclone-current.old.zip 2>/dev/null)
  mv /boot/config/plugins/rclone/install/rclone-current.zip /boot/config/plugins/rclone/install/rclone-current.old.zip
fi;

if [ -f /boot/config/plugins/rclone/install/rclone-v*/rclone ]; then
  rm -f $(ls /usr/sbin/rcloneorig 2>/dev/null)
  cp /boot/config/plugins/rclone/install/rclone-v*/rclone  /usr/sbin/rcloneorig
  if [ "$?" -ne "0" ]; then
	echo ""
	echo "-------------------------------------------------------------------"
	echo "<font color='red'> Update failed, rclone binary couldn't be replaced. Please try again</font>"
	echo "-------------------------------------------------------------------"
	echo ""
    if [ -d /boot/config/plugins/rclone/install/rclone-v*/ ]; then
      rm -rf /boot/config/plugins/rclone/install/rclone-v*/
    fi;
    exit 1
  fi;
else
	echo ""
	echo "-------------------------------------------------------------------"
	echo "<font color='red'> Unpack failed. Please try again</font>"
	echo "-------------------------------------------------------------------"
	echo ""
  rm -f $(ls /boot/config/plugins/rclone/install/rclone-current.old.zip 2>/dev/null)
  exit 1
fi;

if [ -d /boot/config/plugins/rclone/install/rclone-v*/ ]; then
  rm -rf /boot/config/plugins/rclone/install/rclone-v*/
fi;

chown root:root /usr/sbin/rcloneorig
chmod 755 /usr/sbin/rcloneorig

echo ""
echo "-----------------------------------------------------------"
echo " rclone has been successfully updated "
echo "-----------------------------------------------------------"
echo ""