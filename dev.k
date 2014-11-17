KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k

_k_dev_help() {
  echo "
  device file manage

  $(basename $0) [<opt> [<input>] ]

  --help : help
  -u <dev>     : check use <dev> or not 
  -t <dev>     : show <dev> type
  "
  exit
}

_k_dev() {
   local cmd rcmd opt get_val
   echo $1 | grep "^-" >& /dev/null || cmd=$1
   declare -F ${FUNCNAME}_${cmd} >& /dev/null && shift 1

   opt=("$@")

   if _k_opt --help 0 0 "${opt[@]}" >/dev/null; then
       _k_dev_help
       exit 0
   elif get_val=$(_k_opt -u 1 0 "${opt[@]}"); then
      _k_dev_used $get_val || return 1
   elif get_val=$(_k_opt -t 1 0 "${opt[@]}"); then
      _k_dev_block_type $get_val || return 1
   else
      echo "Unknown option"
      exit 1
   fi
}

# cmd sample
_k_dev_used() {
    local dev
    dev=$1
    [ -b $dev ] || return 1
    fuser -m $dev >& /dev/null && return 0
    [ -d /sys/block/$(basename $dev) ] || return 1
    for (( ii=1; ii<$(cat /sys/block/$(basename $dev)/range); ii++)); do
        [ -b $dev$ii ] || continue
        if fuser -m $dev$ii >& /dev/null; then
           echo $ii
           return 0
        fi
    done
    return 1
}

_k_dev_block_type() {
    local dev
    dev=$1
    [ -b $dev ] || return 1
    file -s $(readlink -f $dev)
}

# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "dev.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") $* || exit $?
fi
