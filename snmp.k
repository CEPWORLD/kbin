########################################################################
# Copyright (c) CEP Research Institude, All rights reserved. Since 2008
#    Kage Park <kagepark@cep.kr>
#$version$:0.0.29
# Created at Mon Nov 17 10:05:59 CST 2014
# Description : shmp
########################################################################
KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k
#include kmisc.ko

_k_snmp_help() {
  echo "snmp - v$(grep "^#\$version\$:" $0 | awk -F: '{print $2}')

$(basename $0) [<opt> [<input>] ]

  --help : help
  --get_mac <ip> : get mac address of ports
  --find_mac <mac> <ip> : find  mac address 
  --get_port <dev> <ip> : get port for matched <dev:ex) eth0> 
  --get_port_status <ip>: get port status 
  --get_sw_port <ip>    : sw ports
   "
   exit 1
}

# base starting sample
# _k_opt <find> <num> <ro> <input options>

# <num>
#   all      : get whole value between option (start -)
#   #        : get values of # after finded option (default 1)

# <ro>
#  ro=0      : return <value> (default)
#  ro=1      : return <remained opt>
#  ro=2      : return <value>|<remained opt>

_k_snmp() {
   local cmd rcmd opt get_val
   echo $1 | grep "^-" >& /dev/null || cmd=$1
   declare -F ${FUNCNAME}_${cmd} >& /dev/null && shift 1
   opt=("$@")
   if _k_opt --help 0 0 "${opt[@]}" >/dev/null; then
       _k_snmp_help
#   elif _k_opt --list 0 0 "${opt[@]}" >& /dev/null; then
#       _k_snmp_list
   elif get_val=$(_k_opt --get_mac 1 0 "${opt[@]}"); then
       _k_snmp_get_macs_readable $get_val
   elif get_val=$(_k_opt --find_mac 2 0 "${opt[@]}"); then
       _k_snmp_find_readable_mac_from_id $get_val
   elif get_val=$(_k_opt --get_port 2 0 "${opt[@]}"); then
       _k_snmp_get_port $get_val
   elif get_val=$(_k_opt --get_port_status 1 0 "${opt[@]}"); then
       _k_snmp_port_status $get_val
   elif get_val=$(_k_opt --get_sw_port 1 0 "${opt[@]}"); then
       _k_snmp_get_sw_port $get_val
   fi
}


_k_snmp_dbg() {
  [ "$dbg" ==  "1" ] && echo $*
}

_k_snmp_open() {
    local media target snmp_bin
    target=$1
    media=$2
    if ! snmp_bin=$(which snmpwalk 2>/dev/null) ; then
         snmp_bin=./snmpwalk
    fi
    [ -f $snmp_bin ] || return 1 
    $snmp_bin -O n -v2c -c public $target $media
}
     
# func get_port
_k_snmp_get_port_from_id() {
  local id target
  id=$1
  target=$2
  _k_snmp_open $target .1.3.6.1.2.1.17.4.3.1.2$id | awk '{ print $4}'
}

_k_snmp_get_macs() {
  local target mac mac_readable
  target=$1
  _k_snmp_open $target .1.3.6.1.2.1.17.4.3.1.1
}

_k_snmp_get_macs_readable_v1() {
  local target mac mac_readable
  target=$1
  _k_snmp_get_macs $target | while read line ; do
      mac=$(echo $line | cut -d= -f2 | cut -d: -f2)
      mac_readable=$(echo $mac | tr " " : | cut -d: -f1-6)
      line_tmp=($line)
      line_tmp_g=$(echo ${line_tmp[0]} | sed "s/\.1\.3\.6\.1\.2\.1\.17\.4\.3\.1\.1//g")
      new_line=$(echo ${line_tmp[0]} | sed "s#$line_tmp_g#$mac_readable#g")
      line_tmp[0]=$new_line
      echo "${line_tmp[*]}"
  done
}

_k_snmp_get_macs_readable() {
  local target mac mac_readable
  target=$1
  _k_snmp_get_macs $target | while read line ; do
      line_mac=$(echo $line | awk -F: '{print $2}' | cut -c 2- | sed "s/ /:/g")
      echo $line | awk -F: -v line_mac=$line_mac '{printf "%s: %s\n",$1,line_mac}'
  done
}

# func get_mac
_k_snmp_find_mac_v1() {
  local mac target
  mac="$1"
  target=$2
  _k_snmp_open $target .1.3.6.1.2.1.17.4.3.1.1.$mac | awk -F: '{print $2}' | awk '{printf "%s:%s:%s:%s:%s:%s\n",$1,$2,$3,$4,$5,$6}'
}

_k_snmp_find_id_from_mac() {
  local mac target
  mac="$1"
  target=$2
  _k_snmp_get_macs $target | while read line; do
    if echo $line | grep "$mac" >& /dev/null ; then
      echo $line | awk '{print $1}' | cut -c 24-
    fi
  done
}

_k_snmp_find_readable_mac_from_id() {
  local mac target
  mac="$1"
  target=$2
  _k_snmp_get_macs $target | while read line; do
    if echo $line | grep "$mac" >& /dev/null ; then
      echo $line | awk -F: '{print $2}' | cut -c 2- | sed "s/ /:/g"
    fi
  done
}

_k_snmp_find_id_from_readable_mac() {
  local mac target
  mac="$(k misc_upper $1)"
  target=$2
  _k_snmp_get_macs_readable $target | while read line; do
    line_arr=( $(k misc_upper $line) )
    if [ "${line_arr[${#line_arr[*]}-1]}" == "$mac" ]; then
          #echo ${line_arr[${#line_arr[*]}-1]}
          echo ${line_arr[0]} | sed "s#.1.3.6.1.2.1.17.4.3.1.1##g"
          return 0
    fi
  done
  return 1
}

# func get_sw_port
_k_snmp_get_sw_port() {
  local map target
  map=$1
  target=$2
  _k_snmp_open $target .1.3.6.1.2.1.31.1.1.1.1.$map | awk '{print $4}'
}

_k_snmp_get_sw_port_status() {
  local target
  target=$1
   _k_snmp_open $target .1.3.6.1.2.1.2.2.1.8 | while read line; do
        if echo $line | grep down >& /dev/null ; then
            echo $line | awk '{print $1}' | cut -c 22- | awk '{printf "d.%s ",$1}'
        else
            echo $line | awk '{print $1}' | cut -c 22- | awk '{printf "u.%s ",$1}'
        fi
   done
}

_k_snmp_get_id_from_map() {
   local map
   map=$1
   target=$2
   _k_snmp_open $target .1.3.6.1.2.1.17.4.3.1.2 | while read line; do
       id=$(echo $line | awk -v map=$map '{if($4==map) print $1}')
       if [ -n "$id" ]; then
           echo $id
           return 0
       fi
   done
   return 1
}

_k_snmp_get_map() {
  local port
  port=$1
  target=$2
  _k_snmp_open $target .1.3.6.1.2.1.17.1.4.1.2.$port | awk '{print $4}'

  #$snmpwalk -O n -v2c -c public $target .1.3.6.1.2.1.17.1.4.1.2 | while read line ; do
  #   echo $line | awk -v id=".1.3.6.1.2.1.17.1.4.1.2.$port" '{if($1==id) print $4}'
  #done
}

_k_snmp_get_ports_mac() {
  local ip
  ip=$1
  for maps in $(_k_snmp_get_sw_port_status $ip); do
    map=$(echo $maps | cut -c 3-)
    get_sw_port_num=$(_k_snmp_get_sw_port "$map" $ip) || continue
    echo -n "$get_sw_port_num <==> "

    if echo $maps | grep "d." >&/dev/null; then
      echo "down"
    else
      id=$(_k_snmp_get_id_from_map $map $ip | cut -c 25-) 
      [ -n "$id" ] && _k_snmp_find_readable_mac_from_id $id $ip || echo "?"
    fi
  done
}

# "find mac for $ifcfg"
_k_snmp_get_local_mac() {
  local dev help
  help="_k_snmp_get_local_mac <net dev name>"
  dev=$1
  [ -n "$dev" ] || error_return $help || return 1
  ifconfig $dev |grep  HWaddr | awk '{print $5}'
}

_k_snmp_port_status() {
    local ip mac get_mac_add get_port_num get_map_num get_sw_port_num
    ip=$1
    _k_snmp_open $ip interfaces.ifTable.ifEntry.ifOperStatus
}

_k_snmp_get_port() {
    local ip mac get_mac_add get_port_num get_map_num get_sw_port_num dev
    dev=$2
    ip=$1
    [ -n "$dev" ] || dev=eth0
    _k_snmp_dbg "find switch port of connected device $dev"
    mac=$( _k_snmp_get_local_mac $dev| sed -e 's/:/ /g')
    _k_snmp_dbg "input mac: $mac"

    get_id=$(_k_snmp_find_id_from_mac "$mac" $ip)
    _k_snmp_dbg "get id: $get_id"

    get_port_num=$(_k_snmp_get_port_from_id "$get_id" $ip)
    _k_snmp_dbg "get port num: $get_port_num"

    get_map_num=$(_k_snmp_get_map "$get_port_num" $ip) 
    _k_snmp_dbg "get map num: $get_map_num"

    get_sw_port_num=$(_k_snmp_get_sw_port "$get_map_num" $ip)
    _k_snmp_dbg "get sw port num: $get_sw_port_num"

    #echo $get_sw_port_num | awk -F/ '{printf "Vlan: %s, Port: %s\n", $2,$3}'
}

# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "snmp.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi
