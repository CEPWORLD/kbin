########################################################################
# Copyright (c) CEP Research Institude, All rights reserved. Since 2008
#    Kage Park <kagepark@cep.kr>
#$version$:0.1.2
# Created at Mon Nov 17 15:56:05 CST 2014
# Description : 
########################################################################
KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k

_k_dhcp_help() {
  echo "dhcp - v$(grep "^#\$version\$:" $0 | awk -F: '{print $2}')

$(basename $0) [<opt> [<input>] ]

  --help : help
  --find_ip <mac> : find IP, used by <mac>
  --leases_file <dhcpd.leases file> : define dhcpd.leases file
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

# example for cmd is sample
_k_dhcp() {
   local cmd rcmd opt get_val
   echo $1 | grep "^-" >& /dev/null || cmd=$1
   declare -F ${FUNCNAME}_${cmd} >& /dev/null && shift 1

   opt=("$@")
   
   dhcp_leases=$(_k_opt --leases_file 1 0 "${opt[@]}")
   [ -n "$dhcp_leases" ] || dhcp_leases=/var/lib/dhcpd/dhcpd.leases

   if _k_opt --help 0 0 "${opt[@]}" >/dev/null; then
       _k_dhcp_help
   elif get_val=$(_k_opt --find_ip 1 0 "${opt[@]}"); then
      _k_dhcp_get_ip $get_val || return 1
#or
#   elif _k_opt -t 2 0 "${opt[@]}" >& /dev/null; then
#      _k_dhcp_sample "${opt_out[@]}" || return 1
   else
      # <command> "${opt[@]}"
      # or
      echo "Unknown option"
      exit 1
   fi
}

#_k_dhcp_sample () {
#  local opts
#  opts=("$@")
#  example  for "k dhcp sample"
#}

_k_dhcp_get_ip() {
   local mac
   mac=$1
   [ -n "$mac" ] || error_return "mac not found" || return 1
   dhcp_line=$(cat $dhcp_leases | grep -n $mac | tail -n 1 | awk -F: '{print $1}')
   cat $dhcp_leases | sed -n "$(($dhcp_line-6)) p" | awk '{print $2}'
}

# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "dhcp.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi
