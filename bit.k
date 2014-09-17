########################################################################
# Copyright (c) CEP Research Institude, All rights reserved. Since 2008
#    Kage Park <kagepark@cep.kr>
#$version$:0.1.9
# Created at Wed Sep 17 12:55:44 CDT 2014
# Description : 
########################################################################
KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k

_k_bit_help() {
  echo "bit - v$(grep "^#\$version\$:" $0 | awk -F: '{print $2}')

$(basename $0) [<opt> [<input>] ] <input value>

  --help : help
  -i <bit> : input bit type (default 10)
  -o <bit> : output bit type (default 10)
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
_k_bit() {
   local cmd rcmd opt get_val
   echo $1 | grep "^-" >& /dev/null || cmd=$1
   declare -F ${FUNCNAME}_${cmd} >& /dev/null && shift 1

   opt=("$@")
   if _k_opt --help 0 0 "${opt[@]}" >/dev/null; then
       _k_bit_help
   fi
   ibase=$(_k_opt -i 1 0 "${opt[@]}")
   obase=$(_k_opt -o 1 0 "${opt[@]}")
   val=$(_k_opt_end 1 "${opt[@]}")
   [ -n "$obase" ] || obase=10
   [ -n "$ibase" ] || ibase=10
   if [ "$obase" == "10" ]; then
       _k_bit_10 "$ibase" "$val"
   else
       _k_bit_cal "$ibase" "$obase" "$val"
   fi
}

_k_bit_10 () {
  local opts val
  ibase=$1
  val=$2
  [ -n "$val" ] || return 1
  echo "ibase=$ibase; $val;" |bc
}

_k_bit_cal () {
  local opts val
  ibase=$1
  obase=$2
  val=$3
  [ -n "$val" ] || return 1
  echo "obase=$obase;ibase=$ibase; $val;" |bc
}

# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "bit.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi
