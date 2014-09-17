########################################################################
# Copyright (c) CEP Research Institude, All rights reserved. Since 2008
#    Kage Park <kagepark@cep.kr>
#$version$:0.1.21
# Description :
# test
########################################################################
KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k

_k_mac_help() {
  echo "
  convert/calculate mac address

  $(basename $0) [<opt> [<input>] ]

  --help : help
  -i2h <int64> : convert <int64> to mac address
  -h2i <mac>   : convert <mac> to <int64>
  -str2mac <string mac>   : convert <string mac> to mac format (aa:bb:cc:dd:ee:ff)
  -mac2pxe <mac>     : convert <mac> to pxeboot style mac (01-xx-xx-xx-xx-xx-xx)
  -a <mac> <int>     : add <int> to the mac
  -d <mac> <int>     : subtract <int> to the mac
  --get <eth dev>    : get mac address of <eth dev>
  "
  exit
}

# base starting sample
_k_mac() {
   local cmd rcmd opt get_val
   echo $1 | grep "^-" >& /dev/null || cmd=$1
   declare -F ${FUNCNAME}_${cmd} >& /dev/null && shift 1

   opt=("$@")

   if _k_opt --help 0 0 "${opt[@]}" >/dev/null; then
       _k_mac_help
       exit 0
   elif get_val=$(_k_opt -i2h 1 0 "${opt[@]}"); then
      _k_mac_int2hex $get_val || return 1
   elif get_val=$(_k_opt -str2mac 1 0 "${opt[@]}"); then
      _k_mac_str2mac $get_val || return 1
   elif get_val=$(_k_opt -mac2pxe 1 0 "${opt[@]}"); then
      _k_mac_mac2pxe $get_val || return 1
   elif get_val=$(_k_opt -h2i 1 0 "${opt[@]}"); then
      _k_mac_hex2int $get_val || return 1
   elif get_val=$(_k_opt -a 2 0 "${opt[@]}"); then
      _k_mac_add $get_val || return 1
   elif get_val=$(_k_opt -d 2 0 "${opt[@]}"); then
      _k_mac_del $get_val || return 1
   elif get_val=$(_k_opt --get 1 0 "${opt[@]}"); then
      _k_mac_get $get_val || return 1
   else
      echo "Unknown option"
      exit 1
   fi
}

_k_mac_str2mac() {
   local input simbol
   input=$1
   simbol=$2
   [ -n "$simbol" ] || simbol=":"
   aa=( $(echo $input | sed "s/$simbol/ /g") )
   ((${#aa[*]} == 1 )) || return 1
   for ((i=0;i<6;i++)); do
       printf "%s" $(echo $input | cut -c $((1+$(($i*2))))-$((2*$(($i+1)) )) )
       (($i<5)) && printf "%s" "$simbol"
   done
}

_k_mac_mac2str() {
   local new_mac
   echo $* | grep "^01-" >& /dev/null && new_mac=$(echo $* | sed "s/^01-//g") || new_mac=$*
   echo $new_mac | sed "s/[:-]//g"
}

_k_mac_mac2pxe() {
   local new_mac
   if echo $* | grep "^01-" >& /dev/null; then
        echo $* | tr '[:upper:]' '[:lower:]'
   else
        echo "01-$(echo $* | sed "s/:/-/g")" | tr '[:upper:]' '[:lower:]'
   fi
}

_k_mac_int2hex() {
    local int64 new_mac
    int64=$1
    new_mac=$(printf "%012X " $int64)
    _k_mac_str2mac $new_mac
}

_k_mac_hex2int() {
    local hex h
    hex=$1
    h='0x'$(echo $hex | sed "s/://g" | tr '[:lower:]' '[:upper:]')
    printf "%d " $h
}

_k_mac_add() {
    local mac num new_num
    mac=$1
    num=$2
    mac_str=$(_k_mac_mac2str $mac) || return 1
    _k_mac_int2hex $(( $(_k_mac_hex2int $mac_str) + $num )) 
}

_k_mac_del() {
    local mac num new_num
    mac=$1
    num=$2
    mac_str=$(_k_mac_mac2str $mac) || return 1
    _k_mac_int2hex $(( $(_k_mac_hex2int $mac_str) - $num )) 
}

_k_mac_get() {
    local dev
    dev=$1
    [ -f /sys/class/net/$dev/address ] && cat /sys/class/net/$dev/address
}

# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "mac.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi
