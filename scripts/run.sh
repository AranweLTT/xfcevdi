#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

if [ ! -f /app/.setup_done ]; then
  # Do initial setup
  sudo USERNAME=$USERNAME USER_ID=$USER_ID PASS=$PASS /app/setup.sh
fi

# For safety reasons we unset all custom env vars
unset USERNAME
unset USER_ID
unset ALLOW_APT
unset ENTER_PASS
unset PASS

## Start-up our services manually (since Docker container will not invoke all init scripts).
## However, some service do start automatically, when placed and NOT-hidden in: /etc/xdg/autostart folder.

# Start dbus system daemon
sudo service dbus start
# Start cron daemon
sudo service cron start

# Ensure host keys exist and /run/sshd is present
sudo ssh-keygen -A

# Run sshd in the foreground
exec sudo /usr/sbin/sshd -D -e
