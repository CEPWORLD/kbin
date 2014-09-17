########################################################################
# Copyright (c) CEP Research Institude, All rights reserved. Since 2008
#    Kage Park <kagepark@cep.kr>
#$version$:0.1.9
# Created at Wed Jul 23 09:57:45 CDT 2014
# Description : 
########################################################################
KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k

_k_screen_help() {
  echo "screen - v$(grep "^#\$version\$:" $0 | awk -F: '{print $2}')

$(basename $0) [<opt> [<input>] ]

  --help : help
  ls         : show screen list
  --list     : show screen list ( same as ls)
  -f <title> : find screen title and show the screen pid
  -e <title> <cmd> : run <cmd> with <title> of screen
  "
  exit 1
}

# example for cmd is sample
_k_screen() {
   local cmd rcmd opt get_val
   echo $1 | grep "^-" >& /dev/null || cmd=$1
   if declare -F ${FUNCNAME}_${cmd} >& /dev/null; then
        shift 1
        ${FUNCNAME}_${cmd} $*
        exit
   fi

   opt=("$@")
   if _k_opt --help 0 0 "${opt[@]}" >/dev/null; then
       _k_screen_help
   elif find_name=$(_k_opt -f 1 0 "${opt[@]}"); then
      _k_screen_find $get_val || return 1
   elif _k_opt --list 0 0 "${opt[@]}">/dev/null; then
      _k_screen_ls || return 1
   elif exec=$(_k_opt -e 1 0 "${opt[@]}"); then
      opt[0]=""
      opt=(${opt[@]})
      _k_screen_exec ${opt[@]} || return 1
   else
      echo "Unknown option"
      exit 1
   fi
}

_k_screen_bin () {
   local _screen_bin
   _screen_bin=$( which screen 2>/dev/null )
   [ -f $_screen_bin ] && echo $_screen_bin || return 1
}

_k_screen_ls() {
    $(_k_screen_bin) -ls 
}

_k_screen_find() {
    local dest
    dest="$1"
    #pid=$(_k_screen_ls | grep -e Detached -e Attached | awk '{print $1}' | grep ".${dest}=$" | awk -F. '{print $1}')
    pid=$(_k_screen_ls | grep -e Detached -e Attached | awk '{print $1}' | awk -F. -v awk_dest=${dest}= '{if($2==awk_dest) print $1}')
    [ -n "$pid" ] && echo $pid || return 1
}

_k_screen_exec() {
    local _title cmd
    _title=$1
    shift 1
    cmd=$@
    $(_k_screen_bin) -S ${_title}= $cmd
}


# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "screen.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi
