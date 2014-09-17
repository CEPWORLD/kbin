########################################################################
# Copyright (c) CEP Research Institude, All rights reserved. Since 2008
#    Kage Park <kagepark@cep.kr>
#$version$:0.1.60
# Created at Wed Jul 23 09:48:44 CDT 2014
# Description : 
########################################################################
KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k
#include screen.k

_k_tunnel_help() {
  echo "tunnel - v$(grep "^#\$version\$:" $0 | awk -F: '{print $2}')

$(basename $0) [<opt> [<input>] ]

  --help : help
  --open <login1 server> [ <login2 server> ....] <dest server>   : open tunnel with ssh (up to 9 hops tunnel)
  --make <dest server> <dest port> <login server> [<login port>] : open 1 hop tunnel
  --find <host> : find host
  --list : show open list
  "
  exit 1
}

# example for cmd is sample
_k_tunnel() {
   local cmd rcmd opt get_val
   echo $1 | grep "^-" >& /dev/null || cmd=$1
   declare -F ${FUNCNAME}_${cmd} >& /dev/null && shift 1

   opt=("$@")
   if _k_opt --help 0 0 "${opt[@]}" >/dev/null; then
       _k_tunnel_help
   elif get_val=$(_k_opt --open all 0 "${opt[@]}"); then
      _k_tunnel_open $get_val || return 1
   elif get_val=$(_k_opt --make all 0 "${opt[@]}"); then
      _k_tunnel_make $get_val || return 1
   elif _k_opt --list 0 0 "${opt[@]}" >/dev/null; then
      _k_tunnel_list
   elif get_val=$(_k_opt --find 1 0 "${opt[@]}"); then
      _k_tunnel_find_host $get_val
   else
      echo "Unknown option"
      exit 1
   fi
}

_k_tunnel_make() {
    local opts
    opts=("$@")
    dest=$1
    dest_port=$2
    login=$3
    login_port=$4
    # base command
    # [ -n "$login_port" ] && login_port_str="-p $login_port" 
    # ssh $login_port_str -L$dest_port:$dest:22 $login

    if [ -n "$login_port" ]; then
         login_port_str="-p $login_port" 
         login_str=$(echo $login | grep "@" >& /dev/null &&  echo $login | awk -F@ '{printf "%s@localhost", $1}' || echo localhost)
    else
         #|| login_port_str="-C"
         login_str=$login
    fi
    tunnel_tmp=$(mktemp /tmp/XXXXXXXXXX.L${dest_port}:$dest:22)

     echo "
echo
echo Detache is Control a+d for screen mode
echo
echo Please type password of $login to below asking
ssh $login_port_str -L$dest_port:$dest:22 $login_str" > $tunnel_tmp
    _k_screen_exec ${dest}=tunnel sh $tunnel_tmp
    rm -f $tunnel_tmp
}

_k_tunnel_open() {
    local hosts dest dest_port login_port id
    hosts=($*)
    for ((ii=0;ii<$(( ${#hosts[*]} - 1 )); ii++)); do
        if find_first_port=$(_k_tunnel_find_host $(echo ${hosts[$ii]} | awk -F@ '{print $2}')); then
            open_num=$(printf "%d" $(echo $find_first_port | cut -c $((${#find_first_port}-1))- ) )
        else
            open_num=0
        fi
        if (( $open_num > 99 )); then
            echo "It support up to 99 open tunnel"
            return 1
        fi

        dest=$(echo ${hosts[$ii+1]} | awk -F@ '{print $2}')
        if dest_find_port=$(_k_tunnel_find_host $dest); then
             login_port=$(echo $dest_find_port | awk -F: '{print $2}')
             continue
        fi
        dest_port=$(_k_tunnel_port $(($ii+1)) "$open_num")
        _k_tunnel_make $dest $dest_port ${hosts[$ii]} $login_port
        login_port=$dest_port
     done 
}

_k_tunnel_port() {
    #<hope><user><tunnel id>
    #<hope> : 1 ~ 6
    #<user> : 1 ~ 99
    #<tunnel id> : 1~99
    local tunnel_port jump open_group_num uid id
    tunnel_port="10000"
    jump=$1
    open_group_num=$2
    [ ! -n "$jump" -o "$jump" == "0" -o "$jump" == "1" ] && jump=1
    tunnel_port=$(( $tunnel_port * $jump ))
    [ ! -n "$open_group_num" -o "$open_group_num" == "0" -o "$open_group_num" == "1" ] && open_group_num=1

    id=$(id -un)
    if [ -f /tmp/ktunnel.id.log ]; then
        id_num=$(awk -v id=$id '{if($1==id) print NR -1}' /tmp/ktunnel.id.log)
        if [  -n "$id_num" ]; then
            id_num=$(($id_num+1))
        else
             echo $id >> /tmp/ktunnel.id.log
             id_num=1
        fi
    else
        echo $id >> /tmp/ktunnel.id.log
        id_num=1
    fi

    echo $(($tunnel_port + $open_group_num + $(($id_num * 100)) ))
}

_k_tunnel_find_host() {
    local host get
    host=$1
    [ -n "$host" ] || return 1
    get=$(_k_screen_ls | grep "=tunnel=" | awk '{print $1}' | awk -F. -v find_host=${host}=tunnel= '{if($2==find_host) print $2}' | sed "s/=tunnel=$//g")
    if [ -n "$get" ]; then
       echo ${get}:$(_k_tunnel_find_host_port $(_k_screen_find "${get}=tunnel"))
       return 0 
    else
       return 1
    fi
}

_k_tunnel_list() {
    for ii in $(_k_screen_ls | grep "=tunnel=" | awk '{print $1}' | awk -F. '{print $2}' | sed "s/=tunnel=$//g"); do
        echo ${ii}:$(_k_tunnel_find_host_port $(_k_screen_find "${ii}=tunnel"))
    done
}

_k_tunnel_find_host_port() {
    local screen_pid
    screen_pid=$1
    [ -n "$screen_pid" ] || return 1
    if [ -d /proc ]; then
        #Linux
        screen_info=( $(cat /proc/$screen_pid/cmdline | sed -e "s/L/ /g" -e "s/:/ /g") )
        echo ${screen_info[${#screen_info[*]}-3]}
    else
        #MAC
        for sci in $(ps -ef | awk -v pid=$screen_pid '{if($2==pid) print}'); do
            echo $sci | grep -e "^-L" -e "/tmp/XXXXXXXXXX.L"
        done | awk -F: '{print $1}' | sed -e "s/-L//g" -e "s#/tmp/XXXXXXXXXX.L##g"
    fi
}

# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "tunnel.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi
