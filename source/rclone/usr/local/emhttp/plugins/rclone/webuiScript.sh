#!/bin/bash
if [ "${1}" == "true" ]; then
  echo "Enabling rclone WebUI, please wait..."
  sed -i "/WEBUI_ENABLED=/c\WEBUI_ENABLED=${1}" "/boot/config/plugins/rclone/settings.cfg"
  if pgrep -f "rcloneorig.*--rc-web-gui" > /dev/null 2>&1 ; then
    echo
    echo "rclone WebUI already started!"
    exit 0
  fi
elif [ "${1}" == "false" ]; then
  KILL_PID="$(pgrep -f "rcloneorig.*--rc-web-gui")"
  echo "Disabling rclone WebUI, please wait..."
  kill -SIGINT $KILL_PID
  sed -i "/WEBUI_ENABLED=/c\WEBUI_ENABLED=${1}" "/boot/config/plugins/rclone/settings.cfg"
  echo "rclone WebUI disabled"
  exit 0
elif [ "${1}" == "VERSION" ]; then
  if [ ! -d /boot/config/plugins/rclone/webui ]; then
    mkdir -p /boot/config/plugins/rclone/webui
  fi
  if [ -f /boot/config/plugins/rclone/webui/latest ]; then
    rm -f /boot/config/plugins/rclone/webui/latest
  fi
  API_RESULT="$(wget -qO- https://api.github.com/repos/rclone/rclone-webui-react/releases/latest)"
  echo "${API_RESULT}" | jq -r '.tag_name' | sed 's/^v//' > /boot/config/plugins/rclone/webui/latest
  echo "${API_RESULT}" | jq -r '.assets[].browser_download_url' >> /boot/config/plugins/rclone/webui/latest
  LAT_V="$(cat /boot/config/plugins/rclone/webui/latest | head -1)"
  if [ -z "${LAT_V}" ] || [ "${LAT_V}" == "null" ]; then
    rm -f /boot/config/plugins/rclone/webui/latest
  else
    exit 0
  fi
else
  echo "Error"
  exit 1
fi

echo "Executing version check"
if [ ! -f /boot/config/plugins/rclone/webui/latest ]; then
  API_RESULT="$(wget -qO- https://api.github.com/repos/rclone/rclone-webui-react/releases/latest)"
  echo "${API_RESULT}" | jq -r '.tag_name' | sed 's/^v//' > /boot/config/plugins/rclone/webui/latest
  echo "${API_RESULT}" | jq -r '.assets[].browser_download_url' >> /boot/config/plugins/rclone/webui/latest
  LAT_V="$(cat /boot/config/plugins/rclone/webui/latest | head -1)"
  DL_URL="$(cat /boot/config/plugins/rclone/webui/latest | head -2 | tail -1)"
  if [ -z "${LAT_V}" ] || [ "${LAT_V}" == "null" ]; then
    rm -f /boot/config/plugins/rclone/webui/latest
    if [ -z "${CUR_V}" ]; then
      echo "ERROR: Can't get latest version and no current version from rclone webgui installed"
      exit 1
    else
      echo "Can't get latest version from rclone webgui, falling back to installed version: ${CUR_V}"
      LAT_V="${CUR_V}"
    fi
  fi
else
  LAT_V="$(cat /boot/config/plugins/rclone/webui/latest | head -1)"
  DL_URL="$(cat /boot/config/plugins/rclone/webui/latest | head -2 | tail -1)"
fi

CUR_V="$(ls -1 /boot/config/plugins/rclone/webui/*.zip 2>/dev/null | rev | cut -d '/' -f1 | cut -d '.' -f2- | rev | sort -V | head -1 | sed 's/^v//')"

if [ ! -d /root/.cache/rclone/webui ]; then
  mkdir -p /root/.cache/rclone/webui
fi

if [ -z "$CUR_V" ]; then
  echo "rclone WebUI not installed, downloading..."
  if ! wget -q -O /boot/config/plugins/rclone/webui/${LAT_V}.zip "${DL_URL}" ; then
    echo "Download failed!"
    rm -f /boot/config/plugins/rclone/webui/${LAT_V}.zip
    exit 1
  fi
  unzip -qq /boot/config/plugins/rclone/webui/${LAT_V}.zip -d /root/.cache/rclone/webui
elif [ "$CUR_V" != "$LAT_V" ]; then
  echo "Newer rclone WebUI version found, downloading..."
  if [ -d /root/.cache/rclone/webui/build ]; then
    rm -rf /root/.cache/rclone/webui/build
  fi
  if ! wget -q -O /boot/config/plugins/rclone/webui/${LAT_V}.zip "${DL_URL}" ; then
    echo "rclone WebUI ownload failed!"
    LAT_V="${CUR_V}"
    rm -f /boot/config/plugins/rclone/webui/${LAT_V}.zip
    EXIT_STATUS=1
  fi
  if [ "${EXIT_STATUS}" != 1 ]; then
    unzip -qq /boot/config/plugins/rclone/webui/${LAT_V}.zip -d /root/.cache/rclone/webui
  fi
fi

if [ ! -d /root/.cache/rclone/webui/build ]; then
  unzip -qq /boot/config/plugins/rclone/webui/${LAT_V}.zip -d /root/.cache/rclone/webui
fi

# Remove old versions
rm -f $(ls -1 /boot/config/plugins/rclone/webui/*.zip 2>/dev/null|grep -v "${LAT_V}")

START_PARAMS="$(cat /boot/config/plugins/rclone/settings.cfg | grep -n "^WEBUI_START_PARAMS=" | cut -d '=' -f2- | sed 's/\"//g')"
PORT="$(cat /boot/config/plugins/rclone/settings.cfg | grep -n "^WEBUI_PORT=" | cut -d '=' -f2- | sed 's/\"//g')"

echo "Starting rclone WebUI"
echo "rclone rcd --rc-web-gui --rc-web-gui-no-open-browser --rc-addr=0.0.0.0:${PORT} --rc-files /root/.cache/rclone/webui/build ${START_PARAMS}" | at now -M > /dev/null 2>&1

if pgrep -f "rcloneorig.*--rc-web-gui" > /dev/null 2>&1 ; then
  echo
  echo "rclone WebUI started, you can now connect to the WebUI through Port: ${PORT}"
else
  echo
  echo "rclone WebUI start failed, please check your settings and your logs what went wrong."
fi
