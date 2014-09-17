########################################################################
# Copyright (c) CEP Research Institude, All rights reserved. Since 2008
#    Kage Park <kagepark@cep.kr>
#$version$:0.1.4
# Description :
########################################################################
KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k

_k_md5_help() {
  echo "$(basename $0) [<opt> [<input>] ]

  --help           : help
  -m               : Create MD5 path to base path
    -b <base path> : base path of MD5 (default: ~/.k_md5)
  "
  exit
}

# base starting sample
_k_md5() {
   local cmd rcmd opt file md5_sum
   echo $1 | grep "^-" >& /dev/null || cmd=$1
   declare -F _k_${name}_${cmd} >& /dev/null && shift 1

   opt=("$@")
   file=$(_k_opt_end 1 "${opt[@]}")
   if ! md5_sum=$(_k_md5_sum "$file"); then
      echo "$file not found"
      return 1
   fi

   if _k_opt -m "${opt[@]}" >& /dev/null; then
       base_path=$(_k_opt -b "${opt[@]}")
       if ! _k_md5_check "$md5_sum" "$base_path"; then
           echo "$(_k_md5_make "$md5_sum" "$base_path")"
       fi
       return 0
   else
       echo $md5_sum
       return 0
   fi

   if _k_opt --help "${opt[@]}" >/dev/null; then
       _k_md5_help
       exit 0
   fi

}

_k_md5_cmd() {
   if _k_os_check osx; then
       _k_md5_cmd="/sbin/md5 -q"
   else
      _k_md5_cmd=/usr/bin/md5sum
   fi
   [ -f "$(echo $_k_md5_cmd | awk '{print $1}')" ] || return 1
   echo $_k_md5_cmd
}

_k_md5_sum() {
    local _k_md5_cmd file
    file=$1
    [ -f "$file" ] || return 1
    _k_md5_cmd=$(_k_md5_cmd)
    $_k_md5_cmd "$file" | awk '{print $1;}'
}

_k_md5_make() {
    local md5_sum base_path
    md5_sume=$1
    base_path=$2
    [ -n "$base_path" ] || base_path=~/.k_md5
    mkdir -p "$base_path/$md5_sum" 
    echo "$base_path/$md5_sum"
}

_k_md5_check() {
    local md5_sum base_path
    md5_sume=$1
    base_path=$2
    [ -n "$base_path" ] || base_path=~/.k_md5
    [ -d "$base_path/$md5_sum" ] && return 0 || return 1
}

_k_md5_db_find() {
   local md5_path find dest sdate
   md5_path="$1"
   src="$2"
   dest="$3"
   [ ! -f "$md5_path/info.txt" -o "$(stat -f "%z" "$md5_path/info.txt" 2>/dev/null)" == "0" ] && return 1

   if [ "$dest" == "dup" -a -n "$src" ]; then
      find_src="dup"
   elif [ "$dest" == "both" -a -n "$src" ]; then
      sdate=($(awk -v fn="$src" -F\| '{if($4==fn) printf "%s ",$1}' "$md5_path/info.txt"))
      find_src="dest"
      if (( ${#sdate[@]} == 0 )); then
          sdate=($(awk -v fn="$src" -F\| '{if($3==fn) printf "%s ",$1}' "$md5_path/info.txt"))
          find_src="src"
      fi
   elif [ -n "$dest" -a -n "$src" ]; then
      find_src="both"
      sdate=($(awk -v fs="$src" -v fd="$dest" -F\| '{if($4==fd && $3==fs) printf "%s ",$1}' "$md5_path/info.txt"))
   elif [ -n "$dest" ]; then
      find_src="dest"
      sdate=($(awk -v fn="$find" -F\| '{if($4==fn) printf "%s ",$1}' "$md5_path/info.txt"))
   elif [ -n "$src" ]; then
      find_src="src"
      sdate=($(awk -v fn="$find" -F\| '{if($3==fn) printf "%s ",$1}' "$md5_path/info.txt"))
   fi
   (( ${#sdate[@]} == 0 )) && return 1
   echo "$find_src ${sdate[@]}"
   return 0
}

_k_md5_db_view() {
   local md5_path find dest sdate
   md5_path="$1"
   [ -f "$md5_path/info.txt" ] || return 1

   echo "$(basename "$md5_path")" 
   cat "$md5_path/info.txt" | while read info_line; do
       md5_date=$(echo $info_line | awk -F\| '{print $1}')
       md5_cmd=$(echo $info_line | awk -F\| '{print $2}')
       md5_src_file=$(echo $info_line | awk -F\| '{print $3}')
       md5_dest_file=$(echo $info_line | awk -F\| '{print $4}')
       [ -n "$md5_date" ] && echo "$(date -r $md5_date) : $md5_cmd : $md5_src_file : $md5_dest_file"
   done
}

_k_md5_db_ctl() {
   local md5_path md5_cmd cmd src dest
   md5_path="$1"
   md5_cmd="$2"
   cmd="$3"
   src="$4"
   dest="$5"

   [ -n "$md5_path" ] || return 1
   [ ! -n "$src" -a ! -n "$dest" ] && return 1

   if [ "$md5_cmd" == "add" ]; then
       [ -d "$md5_path" ] || mkdir -p "$md5_path"
       [ -n "$dest" ] || dest="$src"
       [ -n "$cmd" ] || cmd=init
       echo "$(date +%s)|$cmd|$src|$dest" >> "$md5_path/info.txt" 
       return 0
   elif [ "$md5_cmd" == "del" ]; then
       if [ -n "$dest" ]; then
           sdate=($(_k_md5_db_find "$md5_path" "" "$dest")) || return 1
       else
           sdate=($(_k_md5_db_find "$md5_path" "$src" "")) || return 1
       fi
       
       for ((ii=1;ii<${#sdate[*]};ii++)); do
               sed  "/^${sdate[$ii]}/d" "$md5_path/info.txt" > "$md5_path/info.txt~"
               mv "$md5_path/info.txt~" "$md5_path/info.txt"
       done
       [ ! -f "$md5_path/info.txt" -o "$(stat -f "%z" "$md5_path/info.txt" 2>/dev/null)" == "0" ] && rm -fr "$md5_path"
       return 0
   elif [ "$md5_cmd" == "fix" ]; then
       cat "$md5_path/info.txt" | while read info_line; do
           md5_src_file=$(echo $info_line | awk -F\| '{print $3}')
           md5_dest_file=$(echo $info_line | awk -F\| '{print $4}')
           if [ ! -f "$md5_dest_file" -a ! -f "$md5_src_file" ]; then
                _k_md5_db_ctl "$md5_path" "del" "" "$md5_src_file" "$md5_dest_file" || return 1
           elif [ -f "$md5_src_file" -a ! -f "$md5_dest_file" ]; then
                _k_md5_db_ctl "$md5_path" "del" "" "$md5_src_file" "$md5_dest_file" || return 1
                _k_md5_db_ctl "$md5path" "add" "FixDB" "" "$md5_src_file" || return 1
           fi
       done
       [ ! -f "$md5_path/info.txt" -o "$(stat -f "%z" "$md5_path/info.txt" 2>/dev/null)" == "0" ] && rm -fr "$md5_path"
   fi
}


# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "md5.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi
