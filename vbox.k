########################################################################
# Copyright (c) CEP Research Institude, All rights reserved. Since 2008
#    Kage Park <kagepark@cep.kr>
#$version$:0.0.14
# Created at Mon Nov 17 10:05:59 CST 2014
# Description : vbox
########################################################################
KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k

_k_vbox_help() {
  echo "vbox command

vbox - v$(grep "^#\$version\$:" $0 | awk -F: '{print $2}')

$(basename $0) [<opt> [<input>] ]

  --help : help
  --list : show vbox list
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

_k_vbox() {
   local cmd rcmd opt get_val
   echo $1 | grep "^-" >& /dev/null || cmd=$1
   declare -F ${FUNCNAME}_${cmd} >& /dev/null && shift 1

   opt=("$@")
   if _k_opt --help 0 0 "${opt[@]}" >/dev/null; then
       _k_vbox_help
   elif _k_opt --list 0 0 "${opt[@]}" >& /dev/null; then
       _k_vbox_list
   fi   
}

_k_vbox_su() {
   local id
   id=$1
   id $id >/dev/null || return 1
   shift 1
   su - $id $*
}

_k_vbox_list() {
    vboxmanage list vms
}

_k_vbox_create() {
    local vms ostype
    vms=$1
    ostype=$2
    vboxmanage createvm --name $vms --ostype $ostype
}

_k_vbox_delete() {
    local vms
    vms=$1
    vboxmanage unregistervm $vms --delete
}

_k_vbox_state() {
    local vms
    vms=$1
    vboxmanage showvminfo "$vms" | grep "State" | awk '{print $2;}'
}

_k_vbox_power() {
    local vms cmd chk
    cmd=$1
    vms=$2
    if [ "$cmd" == "off" -o "$cmd" == "reset" -o "$cmd" == "savestate" -o "$cmd" == "resume" -o "$cmd" == "on" -o "$cmd" == "state" -o "$cmd" == "powerbutton" -o "$cmd" == "sleepbutton" ]; then
        if [ "$cmd" == "off" ]; then 
           cmd=poweroff
        elif [ "$cmd" == "powerbutton" ]; then
           cmd=acpipowerbutton
        elif [ "$cmd" == "sleepbutton" ]; then
           cmd=acpisleepbutton
        elif [ "$cmd" == "on" ]; then
           chk=1
           _k_vbox_start $vms
        elif [ "$cmd" == "state" ]; then
           chk=1
           _k_vbox_state $vms
        fi

        if [ "$cmd" == "poweroff" -o "$cmd" == "savestate" -o "$cmd" == "powerbutton" -o "$cmd" == "sleepbutton" -o "$cmd" == "reset" ]; then 
              [ "$(_k_vbox_state $vms)" == "running" ] || chk=1
        fi
        [ "$chk" != "1" ] &&  vboxmanage controlvm $vms $cmd
    else
       echo "_k_vbox_power <on|off|reset|savestate|resume|powerbutton|sleepbutton|state> <vms>"
    fi
}

_k_vbox_info() {
    local vms
    vms=$1
    vboxmanage showvminfo $vms
}



# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "vbox.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi
