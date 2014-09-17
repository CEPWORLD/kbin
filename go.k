########################################################################
# Copyright (c) CEP Research Institude, All rights reserved. Since 2008
#    Kage Park <kagepark@cep.kr>
#$version$:0.1.17
# Created at Thu Jun  5 10:33:36 CDT 2014
# Description : 
########################################################################
KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k

_k_go_help() {
  echo "go - v$(grep "^#\$version\$:" $0 | awk -F: '{print $2}')

$(basename $0) [<opt> [<input>] ]

  --help : help
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

_k_go_define() {
   local dest
   dest="$1"
   dest_info[0]="home"
   dest_info[1]=$_K_HOME
   dest_info[2]="kbin"
   dest_info[3]=$_K_BIN
   dest_info[4]="klib"
   dest_info[5]=$_K_LIB
   for ((ii=0;ii<${#dest_info[*]}; ii++)); do
        if [ "${dest_info[$ii]}" == "$dest" ]; then
             cd ${dest_info[ii+1]}; bash --login
             return 0
        fi
        ii=$(($ii+1))
   done
   return 1
}

# example for cmd is sample
_k_go() {
   local cmd rcmd opt get_val
   echo $1 | grep "^-" >& /dev/null || cmd=$1
   declare -F ${FUNCNAME}_${cmd} >& /dev/null && shift 1

   opt=("$@")
   if _k_opt --help 0 0 "${opt[@]}" >/dev/null; then
       _k_go_help
   elif dest_path=$(_k_opt_end  1 "${opt[@]}"); then
      [ -n "$dest_path" ] || _k_go_help
      _k_go_define "$dest_path"
   fi
}

# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "go.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi
