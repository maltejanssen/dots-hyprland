#!/bin/sh
set -eu

PID="$(pidof Hyprland | awk '{print $1}')"
XLINE="$(tr '\0' '\n' < /proc/"$PID"/environ | grep '^XDG_DATA_DIRS=' | head -n1)"
VAL="${XLINE#XDG_DATA_DIRS=}"

  echo "PID=$PID"
  echo "XLINE=$XLINE"
  /run/current-system/systemd/bin/systemctl --user set-environment "XDG_DATA_DIRS=$VAL"
  export XDG_DATA_DIRS="$VAL"
  /run/current-system/sw/bin/dbus-update-activation-environment --systemd XDG_DATA_DIRS
  echo "systemd:"
  /run/current-system/systemd/bin/systemctl --user show-environment | grep '^XDG_DATA_DIRS='

