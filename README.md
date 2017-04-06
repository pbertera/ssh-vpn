# ssh-vpn

ssh-vpn is a bash script helper for setting-up SSH based VPN profiting the -w option.

Using the -w command line swithc OpenSSH creates tun devices tunneling VPN traffic, see ssh_config(5) **Tunnel** and **TunnelDevice** sections.

ssh-vpn automatically discovers the first free (remote and local) tun device.

Via the config file you can define addressing, peer and commands to be executed locally and on the remote host.

Example:

    SSH_OPTS="-i /home/pietro/.ssh/id_dsa" # options used for the ssh command
    RUSER=root                             # remote use
    PEER=foo.bar.com                       # remote peer
    RTUNADDR=10.10.101.2                   # remte tunnel device ip address
    LTUNADDR=10.10.101.1                   # local tunnel device ip address
    REMOTE_NET=192.168.2.0/24              # remote subnet
    ENABLE_PEER_IP_FORWARD=false           # enable the IP forwarding on the remote device
    TRY_LOAD_PEER_TUN_MOD=true             # execute "modprobe tun" on the remote side
    # $LOCAL_TUN is local tun device
    # $REMOTE_TUN is remote tun device
    # in POST_TUN_PEER_COMMAND use ' instead " !!!
    POST_TUN_PEER_COMMAND='iptables -I FORWARD -i $REMOTE_TUN -j ACCEPT' # post-connection remote command
    # in POST_TUN_LOCAL_COMMAND use ' instead " !!!
    POST_TUN_LOCAL_COMMAND='ip route add 192.168.6.0/24 via $RTUNADDR dev $LOCAL_TUN' # post-connection local command
