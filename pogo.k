########################################################################
# Copyright (c) CEP Research Institude, All rights reserved. Since 2008
#    Kage Park <kagepark@cep.kr>
#$version$:0.1.2
# Created at Sat May 31 12:02:44 CDT 2014
# Description : 
########################################################################
KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k
#include file.k
#include is.k
#include md5.k

_k_pogo_help() {
  echo "pogo - v$(grep "^#\$version\$:" $0 | awk -F: '{print $2}')

$(basename $0) [<opt> [<input>] ]

  --help : help
  -dp <dest path> : define <dest path> ( default : ~/photostream )
  -sp <src path>  : define <src path> ( default : current directory )
  --check         : check <source file> in <dest path>
  --copy          : copy <source file> to <dest path>
  --move          : move <source file> to <dest path> (default)
  << still working >>
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
_k_pogo() {
   local cmd rcmd opt get_val
   echo $1 | grep "^-" >& /dev/null || cmd=$1
   declare -F ${FUNCNAME}_${cmd} >& /dev/null && shift 1

   opt=("$@")

   dest_path=$(_k_opt -dp 1 0 "${opt[@]}")
   [ -n "$dest_path" ] || dest_path=~/photostream
   src_path=$(_k_opt -sp 1 0 "${opt[@]}")
   [ -n "$src_path" ] || src_path=$(pwd)

   if _k_opt --help 0 0 "${opt[@]}" >/dev/null; then
       _k_pogo_help
   elif _k_opt --move 1 0 "${opt[@]}" >/dev/null; then
      _k_pogo_move "$src_path" "$dest_path" || return 1
   elif _k_opt --copy 0 0 "${opt[@]}" >& /dev/null; then
      _k_pogo_copy "$src_path" "$dest_path" || return 1
   elif _k_opt --check 0 0 "${opt[@]}" >& /dev/null ; then
      _k_pogo_check "$src_path" "$dest_path" || return 1
#or
#   elif _k_opt -t 2 0 "${opt[@]}" >& /dev/null; then
#      _k_pogo_sample "${opt_out[@]}" || return 1
   else
      # <command> "${opt[@]}"
      # or
      echo "Unknown option"
      exit 1
   fi
}

#_k_pogo_sample () {
#  local opts
#  opts=("$@")
#  example  for "k pogo sample"
#}


# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "pogo.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi
