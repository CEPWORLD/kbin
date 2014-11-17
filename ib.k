########################################################################
# Copyright (c) CEP Research Institude, All rights reserved. Since 2008
#    Kage Park <kagepark@cep.kr>
#$version$:0.1.2
# Created at Mon Nov 17 15:50:25 CST 2014
# Description : 
########################################################################
KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k
#include kmisc.so

_k_ib_help() {
  echo "ib - v$(grep "^#\$version\$:" $0 | awk -F: '{print $2}')

$(basename $0) [<opt> [<input>] ]

  --help : help
  --show_reg_mem : show registered memory size of ib
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
_k_ib() {
   local cmd rcmd opt get_val
   echo $1 | grep "^-" >& /dev/null || cmd=$1
   declare -F ${FUNCNAME}_${cmd} >& /dev/null && shift 1

   opt=("$@")
   if _k_opt --help 0 0 "${opt[@]}" >/dev/null; then
       _k_ib_help
#   elif get_val=$(_k_opt -t 1 0 "${opt[@]}"); then
#      _k_ib_sample $get_val || return 1
#or
   elif _k_opt --show_reg_mem 0 0 "${opt[@]}" >& /dev/null; then
      _k_ib_registered_memory "${opt_out[@]}" || return 1
   else
      # <command> "${opt[@]}"
      # or
      echo "Unknown option"
      exit 1
   fi
}

_k_ib_registered_memory() {
    local log_mtts_per_seg log_num_mtt kB
    kB=1024
    log_mtts_per_seg_orig=$(cat /sys/module/mlx4_core/parameters/log_mtts_per_seg)
    log_num_mtt_orig=$(cat /sys/module/mlx4_core/parameters/log_num_mtt)
    [ "$log_mtts_per_seg_orig" == "0" ] && log_mtts_per_seg=3 || log_mtts_per_seg=$log_mtts_per_seg_orig
    [ "$log_num_mtt_orig" == "0" ] && log_num_mtt=20 || log_num_mtt=$log_num_mtt_orig
    echo "log_mtts_per_seg : $log_mtts_per_seg($log_mtts_per_seg_orig)"
    echo "log_num_mtt : $log_num_mtt($log_num_mtt_orig)"
    echo "Registered memory size : $(_k_misc_print_byte $(echo "(2^$log_num_mtt) * (2^$log_mtts_per_seg) * (4 * $kB)" | bc ))"
}

# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "ib.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi
