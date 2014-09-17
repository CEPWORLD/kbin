########################################################################
# Copyright (c) CEP Research Institude, All rights reserved. Since 2008
#    Kage Park <kagepark@cep.kr>
#$version$:0.1.11
# Created at Tue Jun 10 07:15:21 CDT 2014
# Description : 
########################################################################
KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k

_k_sed_help() {
  echo "sed - v$(grep "^#\$version\$:" $0 | awk -F: '{print $2}')

$(basename $0) [<opt> [<input>] ]

  --help : help
  -i     : modify the file
  "
  exit 1
}

# example for cmd is sample
_k_sed() {
   local cmd rcmd opt get_val
   echo $1 | grep "^-" >& /dev/null || cmd=$1
   declare -F ${FUNCNAME}_${cmd} >& /dev/null && shift 1

   opt=("$@")
   _k_opt --help 0 0 "${opt[@]}" >/dev/null && _k_sed_help

   if _k_os_check osx; then
       if _k_opt -i 0 1 "${opt[@]}" >& /dev/null ; then
           file=$(_k_opt_end 1 "${opt[@]}")
           sed "${opt_out[@]}" > "${file}~"
           mv "${file}~" "${file}"
       fi
   else
       sed "${opt[@]}"
   fi
}


# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "sed.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi
