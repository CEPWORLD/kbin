########################################################################
# Copyright (c) CEP Research Institude, All rights reserved. Since 2008
#    Kage Park <kagepark@cep.kr>
#$version$:0.1.1
# Created at Thu Sep 18 10:17:59 CDT 2014
# Description : 
########################################################################
KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k

_k_progress_help() {
  echo "progress - v$(grep "^#\$version\$:" $0 | awk -F: '{print $2}')

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

# example for cmd is sample
_k_progress() {
   local cmd rcmd opt get_val
   echo $1 | grep "^-" >& /dev/null || cmd=$1
   declare -F ${FUNCNAME}_${cmd} >& /dev/null && shift 1

   opt=("$@")
   if _k_opt --help 0 0 "${opt[@]}" >/dev/null; then
       _k_progress_help
#   elif get_val=$(_k_opt -t 1 0 "${opt[@]}"); then
#      _k_progress_sample $get_val || return 1
#or
#   elif _k_opt -t 2 0 "${opt[@]}" >& /dev/null; then
#      _k_progress_sample "${opt_out[@]}" || return 1
   fi
   _k_progress_rotate
}

_k_progress_rotate() {
    [ -n "$rotate_num" ] || rotate_num=0
    if [ "$rotate_num" == "0" ]; then
       printf "\b%s" "|"
    elif [ "$rotate_num" == "1" ]; then
       printf "\b%s" "/"
    elif [ "$rotate_num" == "2" ]; then
       printf "\b%s" "-"
    elif [ "$rotate_num" == "3" ]; then
       printf "\b%s" "\\"
    fi
    (( $rotate_num >= 3 )) && export rotate_num=0 || export rotate_num=$(($rotate_num+1))
}

# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "progress.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi
