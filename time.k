########################################################################
# Copyright (c) CEP Research Institude, All rights reserved. Since 2008
#    Kage Park <kagepark@cep.kr>
#$version$:0.1.2
# Created at Mon Nov 17 17:05:42 CST 2014
# Description : 
########################################################################
KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k

_k_time_help() {
  echo "time - v$(grep "^#\$version\$:" $0 | awk -F: '{print $2}')

$(basename $0) [<opt> [<input>] ]

  --help : help
  -s     : show second time
  -c <sec> [<format>] : convert sec to format
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
_k_time() {
   local cmd rcmd opt get_val
   echo $1 | grep "^-" >& /dev/null || cmd=$1
   declare -F ${FUNCNAME}_${cmd} >& /dev/null && shift 1

   opt=("$@")
   if _k_opt --help 0 0 "${opt[@]}" >/dev/null; then
       _k_time_help
   elif get_val=$(_k_opt -c all 0 "${opt[@]}"); then
      _k_time_convert $get_val || return 1
   elif _k_opt -s 0 0 "${opt[@]}" >& /dev/null; then
      _k_time_sec "${opt_out[@]}" || return 1
   else
      # <command> "${opt[@]}"
      # or
      echo "Unknown option"
      exit 1
   fi
}

_k_time_sec() {
   echo $(date '+%s')
}

_k_time_convert() {
   local sec format
   sec=$1
   shift 1
   format=$*
   [ ! -n "$sec" -o "$sec" == "null" -o "$sec" == "now" ] && sec=$(_k_tm_sec)
   [ -n "$format" ] || format="%Y-%m-%d %H:%M:%S"
   #echo $(date --date="@$sec" "+%Y-%m-%d %H:%M:%S")
   echo $(date --date="@$sec" "+$format")
}

# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "time.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi
