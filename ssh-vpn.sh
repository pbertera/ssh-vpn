#!/bin/bash

function bailout {
    echo ERROR: $@
    exit -1
}

function clean_bailout {
	logger Shutting down SSH-VPN  $1
	eval $BAILOUT_REMOTE_COMMAND
}

[ -z $1 ] && bailout No configuration file defined
[ -z $2 ] && bailout No action defined

ACTION=$2

# optionals configurations
SSH=/usr/bin/ssh
LOCAL_IP=/sbin/ip
REMOTE_IP=/sbin/ip

if [ -f $1 ]; then . $1 else bailout Configuration file $1 not exist; fi

[ -z $RUSER ] && bailout No remote user defined
[ -z $PEER ] && bailout No remote host defined
[ -z $RTUNADDR ] && bailout No remote tunnel address defined
[ -z $LTUNADDR ] && bailout No local tunnel address defined
[ -z $REMOTE_NET ] && bailout No remote network defined
[ -z "$POST_TUN_PEER_COMMAND" ] && POST_TUN_PEER_COMMAND=true
[ -z "$POST_TUN_LOCAL_COMMAND" ] && POST_TUN_LOCAL_COMMAND=true

function discover_remote_tun {
    # Find first tun device free on remote peer
    local MAX_RTUN=`$SSH $SSH_OPTS $RUSER@$PEER $RDISCOVER_COMMAND`
    [ -z $MAX_RTUN ] && echo 0 && return
    local FIRST_FREE_RTUN=$(($MAX_RTUN + 1)) # First free remote tun device
    echo $FIRST_FREE_RTUN
}

function discover_local_tun {
    # Find first tun device free on local
    local MAX_LTUN=`eval $LDISCOVER_COMMAND`
    [ -z $MAX_LTUN ] && echo 0 && return
    local FIRST_FREE_LTUN=$(($MAX_LTUN + 1)) # First free remote tun device
    echo $FIRST_FREE_LTUN
}

function discover_tun_device {
	LDISCOVER_COMMAND="$LOCAL_IP -o link show | grep tun | cut -d: -f2 | sed 's/^[ ]tun*//' | sort -n| tail -n1"
	RDISCOVER_COMMAND="$REMOTE_IP -o link show | grep tun | cut -d: -f2 | sed 's/^[ ]tun*//' | sort -n| tail -n1"

	if [ -z $REMOTE_TUN ]; then 
        echo "Discovering remote tun device ... "
		REMOTE_TUN_NUM=$(discover_remote_tun)
		REMOTE_TUN=tun$REMOTE_TUN_NUM
        echo "Remote tun is: $REMOTE_TUN"
	else
		REMOTE_TUN_NUM=`echo $REMOTE_TUN | cut -b4`
	fi

	if [ -z $LOCAL_TUN ]; then
        echo "Discovering local tun device ... "
		LOCAL_TUN_NUM=$(discover_local_tun) 
		LOCAL_TUN=tun$LOCAL_TUN_NUM
        echo "Local tun is: $LOCAL_TUN"
	else
		LOCAL_TUN_NUM=`echo $LOCAL_TUN | cut -b4`
	fi

	SSH_COMMAND=`echo "$SSH $SSH_OPTS -f -w $LOCAL_TUN_NUM:$REMOTE_TUN_NUM $RUSER@$PEER" |  sed  's/[[:blank:]][[:blank:]]/ /g'`
	POST_PEER_CMD=`eval echo $POST_TUN_PEER_COMMAND`
	POST_LOCAL_CMD=`eval echo $POST_TUN_LOCAL_COMMAND`

	REMOTE_COMMAND="$REMOTE_IP link set up dev $REMOTE_TUN ; \
$REMOTE_IP addr add $RTUNADDR dev $REMOTE_TUN peer $LTUNADDR ; \
$ENABLE_PEER_IP_FORWARD && echo 1 > /proc/sys/net/ipv4/ip_forward ; \
$TRY_LOAD_PEER_TUN_MOD && modprobe tun ; \
$POST_PEER_CMD"

	LOCAL_COMMAND="$LOCAL_IP link set up dev $LOCAL_TUN ; \
$LOCAL_IP addr add $LTUNADDR dev $LOCAL_TUN peer $RTUNADDR ; \
$LOCAL_IP route add $REMOTE_NET via $RTUNADDR dev $LOCAL_TUN ; \
$POST_LOCAL_CMD"

}

function get_pid {
	echo `ps x | grep -e .*$SSH.*$@$RUSER@$PEER.*ip[[:blank:]]addr[[:blank:]]add[[:blank:]]$RTUNADDR | awk '{ print $1 }'`
}

case "$ACTION" in

	start)	
		discover_tun_device
		$SSH_COMMAND "$REMOTE_COMMAND"
		PID=$(get_pid)
		echo SSH PID: $PID
		eval $LOCAL_COMMAND
		;;

	stop)
		PID=$(get_pid)
		[ -z $PID ] && bailout No VPN found
		clean_bailout
		kill $PID
		;;

	dry-run)
		echo "Dry run mode, not executing"
		discover_tun_device
		echo "$SSH_COMMAND $REMOTE_COMMAND"
		echo $LOCAL_COMMAND
		;;

	restart)
		$0 $1 stop
		$0 $1 start
		;;

	status)
		PID=$(get_pid)
		[ -n $PID ] && echo VPN running with PID: $PID
		[ -z $PID ] && echo VPN not running
		;;

	*)
		bailout "Usage: $0 {dry-run|start|stop|restart|status}"
		;;
esac
