########################################################################
# Copyright (c) CEP Research Institude, All rights reserved. Since 2008
#    Kage Park <kagepark@cep.kr>
#$version$:0.1.13
# Created at Mon Nov 17 10:05:59 CST 2014
# Description : 
########################################################################
KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k

_k_rpm_help() {
  echo "rpm - v$(grep "^#\$version\$:" $0 | awk -F: '{print $2}')

$(basename $0) [<opt> [<input>] ]

  --help : help
  --check <pkg file | pkg name>  : check packages
  --install <rpm file | rpm dir> : Install rpm file
  --iso <file file2...> : rpm source file with iso ( NOT support yet )
  --src <dir dir2 ...>  : rpm source dir
  --extract <rpm file>  : extract rpm file (not install)
  -ql <pkg>             : show package list
  -qa                   : queary all
  -q <pkg>              : queary <pkg>
  -e <pkg>              : delete (remove) <pkg>
  -C <dir>              : dest dir
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
_k_rpm() {
   local cmd rcmd opt get_val
   echo $1 | grep "^-" >& /dev/null || cmd=$1
   declare -F ${FUNCNAME}_${cmd} >& /dev/null && shift 1

   opt=("$@")
   dest_dir=$(_k_opt -C 1 0 "${opt[@]}")
   src_dir=$(_k_opt --src all 0 "${opt[@]}")

   if _k_opt --help 0 0 "${opt[@]}" >/dev/null; then
       _k_rpm_help
   elif get_val=$(_k_opt --extract 1 0 "${opt[@]}"); then
      _k_rpm_extract "$get_val" "$dest_dir" || return 1
   elif get_val=$(_k_opt --check all 0 "${opt[@]}"); then
      _k_rpm_check "$get_val" || return 1
   elif get_val=$(_k_opt -q 1 0 "${opt[@]}"); then
      _k_rpm_query "$get_val" || return 1
   elif _k_opt -qa 0 0 "${opt[@]}" >& /dev/null; then
      _k_rpm_query_all || return 1
   elif get_val=$(_k_opt -ql 1 0 "${opt[@]}"); then
      _k_rpm_query_list "$get_val" || return 1
   elif get_val=$(_k_opt -e 1 0 "${opt[@]}"); then
      _k_rpm_del "$get_val" || return 1
   elif get_val=$(_k_opt --install 1 0 "${opt[@]}"); then
      _k_rpm_install "$get_val" "$src_dir" || return 1
#or
#   elif _k_opt -t 2 0 "${opt[@]}" >& /dev/null; then
#      _k_rpm_sample "${opt_out[@]}" || return 1
   else
      # <command> "${opt[@]}"
      # or
      echo "Unknown option"
      exit 1
   fi
}

_k_rpm_extract () {
  local opts
  rpm_file=$1
  rpm_ext_dir=$2
  if _k_os_check ubuntu; then
      dpkg -x $rpm_file
  else 
      if (( $(id -u) == 0 )); then
           rpm2cpio $rpm_file | ( [ -n "$rpm_ext_dir" ] && ( [ -d $rpm_ext_dir ] || mkdir -p $rpm_ext_dir; cd $rpm_ext_dir && cpio -idmv) || cpio -idmv)
           rpm_name=$(rpm -qp --queryformat '%{name}' $rpm_file 2>/dev/null)
           if [ -n "$rpm_ext_dir" ]; then
               rpm -qp --scripts $rpm_file > $rpm_ext_dir/${rpm_name}_script.sh
           else
               rpm -qp --scripts $rpm_file > ${rpm_name}_script.sh
           fi
      else
           echo "It need root account"
           exit 1
      fi
  fi
}

_k_rpm_check() {
  local rpms rpm_name
  rpms=$*
  [ -n "$rpms" ] || return 1
  for ii in $rpms; do
      if [ -f "$ii" ]; then
          if file -i $ii | grep "/x-rpm;" >& /dev/null; then
              rpm_name=$(rpm -qp --qf '%{name}-%{version}.%{arch}\n' $ii)
              installed_name=$(rpm -q $rpm_name 2> /dev/null) && echo "$ii => Installed ($(echo $installed_name))" || echo "$ii => Not installed"
          elif file -i $ii | grep "text/plain;" >& /dev/null; then
              cat $ii | while read line; do
                  installed_name=$(rpm -q $line 2> /dev/null) && echo "$line => Installed ($(echo $installed_name))" || echo "$line => Not installed"
              done
          elif file -i $ii | grep "/x-empty;" >& /dev/null; then
              name=$(echo $ii | sed "s/\.rpm$//g")
              installed_name=$(rpm -q $name 2> /dev/null) && echo "$ii => Installed ($(echo $installed_name))" || echo "$ii => Not installed"
          fi
      else
          installed_name=$(rpm -q $ii 2> /dev/null) && echo "$ii => Installed ($(echo $installed_name))" || echo "$ii => Not installed"
      fi
  done
}

_k_rpm_install_exec() {
    if _k_os_check ubuntu; then
         dpkg -i $*
    elif _k_os_check centos rhel; then
         rpm -ihv $*
    elif _k_os_check sles; then
         zypper in $*
    fi 
}

_k_rpm_install () {
  local opts fname ffind new_rpm_file find_rpm_file src_dir rpm_file find_ii new_ii
  rpm_file=$1
  src_dir="$2"
  [ -n "$rpm_file" ] || return 1
  if [ -f $rpm_file ]; then
      if [ "$(stat -c '%s' $rpm_file)" == "0" ]; then
          if [ -n "$src_dir" -a -d "$src_dir" ]; then
              find_rpm_file=$(find $src_dir -name $rpm_file 2>/dev/null | head -n1)
              if [ -n "$find_rpm_file" ]; then
                  new_rpm_file=$find_rpm_file
              else
                  echo "$rpm_file not found in $src_dir"
                  exit 1
              fi
          else
              echo "Need --iso or --src option"
              exit 1
          fi
      fi
      [ -n "$new_rpm_file" ] && ffind=$new_rpm_file || ffind=$rpm_file
      if [ -f $rpm_file.dep ]; then
           cat $rpm_file.dep | grep -v "^#" | grep -v "^ " | while read line; do
               _k_rpm_install "$line" "$src_dir"
           done
      else
           rpm_name=$(rpm -qp --qf '%{name}.%{arch}\n' $rpm_file)
      fi
      _k_rpm_query $rpm_name >& /dev/null && echo "$rpm_file => Installed" || _k_rpm_install_exec $rpm_file

  elif [ -d $rpm_file ]; then
      for ii in $(ls $rpm_file/*.rpm); do
          if [ "$(stat -c '%s' $ii)" == "0" ]; then
              if [ -n "$src_dir" -a -d "$src_dir" ]; then
                  fname=$(basename $ii)
                  find_ii=$(find $src_dir -name $fname 2>/dev/null | head -n1)
                  if [ -n "$find_ii" ]; then
                      new_ii=$find_ii
                  else
                      echo "$fname not found in $src_dir"
                      continue
                  fi
              else
                  echo "Need --iso or --src option"
                  exit 1
              fi
          fi
          [ -n "$new_ii" ] && ffind=$new_ii || ffind=$ii
          if [ -f $ffind.dep ]; then
               cat $ffind.dep | grep -v "^#" | grep -v "^ " | while read line; do
                   _k_rpm_install "$line" "$src_dir"
               done
          else
               rpm_name=$(rpm -qp --qf '%{name}.%{arch}\n' $ffind)
          fi
          _k_rpm_query $rpm_name >& /dev/null && echo "$ii => Installed" || _k_rpm_install_exec $ffind
      done
  fi
}

_k_rpm_query () {
  if _k_os_check osx; then
    #spctl --list | grep "\.app"
    ls /Applications | grep "$1" && return 0 || return 1
  elif _k_os_check ubuntu; then
    dpkg -l | grep "$1" && return 0 || return 1
  else
    rpm -q $1 && return 0 || return 1
  fi
}

_k_rpm_query_all () {
  if _k_os_check osx; then
    #spctl --list | grep "\.app"
    #pkgutil --packages
    ls /Applications
  elif _k_os_check ubuntu; then
    dpkg -L
  elif _k_os_check sles; then
    zypper lr
  else
    rpm -qa 
  fi
}

_k_rpm_query_list () {
  if _k_os_check osx; then
    #spctl --list | grep "\.app"
    ls /Applications
  elif _k_os_check ubuntu; then
    dpkg -L $*
  else
    rpm -ql $*
  fi
}

_k_rpm_del () {
  if _k_os_check ubuntu; then
    dpkg -r $*
  else
    rpm -e $*
  fi
}

# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "rpm.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi
