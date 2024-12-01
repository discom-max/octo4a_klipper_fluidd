#!/bin/bash

serial_port="/dev/ttyOcto4a"
while getopts p: flag
do
    case "${flag}" in
        p) serial_port=${OPTARG};;
    esac
done

echo "Using serial port ${serial_port}"

if [ ! -c "$serial_port" ] 
then
  echo "Please connect your phone to the printer "
  exit 1
fi

### environment
echo "Initializing environment variables"

TTYFIX="/usr/bin/ttyfix"
TTYFIX_START="/etc/init.d/ttyfix"

### packages
echo "Installing required packages"

apk add inotify-tools iw openrc

### Configuration for ttyOcto4a
tee "$TTYFIX" <<EOF
#!/bin/bash

inotifywait -m /dev -e create |
  while read dir action file
  do
    [ "\$file" = "ttyOcto4a" ] && chmod 777 $serial_port
  done
EOF
chmod +x "$TTYFIX"

tee "$TTYFIX_START" <<EOF
#!/bin/sh
### BEGIN INIT INFO
# Provides:          ttyfix
# Default-Start:        2 3 4 5
# Default-Stop:
# Required-Start:    \$local_fs \$remote_fs
# Short-Description: ttyfix
# Description: ttyfix
### END INIT INFO

. /lib/lsb/init-functions

N="$TTYFIX_START"
PIDFILE=/run/ttyfix.pid
EXEC="$TTYFIX"

set -e

f_start ()
{
  start-stop-daemon --start --background --make-pidfile --pidfile \$PIDFILE --exec \$EXEC
}

f_stop ()
{
  start-stop-daemon --stop --pidfile \$PIDFILE
}

case "\$1" in
  start)
        f_start
        ;;
  stop)
        f_stop
        ;;
  restart)
        f_stop
        sleep 1
        f_start
        ;;
  reload|force-reload|status)
        ;;
  *)
        echo "Usage: \$N {start|stop|restart|force-reload|status}" >&2
        exit 1
        ;;
esac

exit 0
EOF
chmod +x "$TTYFIX_START"

### Configure autostart service
rc-update add ttyfix default

### complete
echo "Configuration complete , Please restart Octo4a"
