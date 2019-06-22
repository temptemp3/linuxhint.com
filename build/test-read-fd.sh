#!/bin/bash
## test-read-fd
## version 0.0.1 - initial
##################################################
#!/bin/bash
## commands (alias)
## - function command cli adapter
## version 0.0.6 - enable alias expansion for standalone use
##################################################
list-available-commands() { { local function_name ; function_name="${1}" ; local filter_include ; filter_include="${2}" ; }
 echo available commands:
 declare -f \
   | grep -e "^${function_name}" \
   | cut "-f1" "-d " \
   | grep -v -e "which" -e "for-each" -e "payload" -e "initialize" \
   | sed -e "s/${function_name}-//" \
   | xargs -I {} echo "- {}" \
   | sed  "1d" \
   | grep -e "${filter_include}"
}
shopt -s expand_aliases
alias read-command-args='
 list-available-commands ${FUNCNAME}
 echo "enter new command (or q to quite)"
 read command_args
'
alias parse-command-args='
 _car() { echo ${1} ; }
 _cdr() { echo ${@:2} ; }
 _command=$( _car ${command_args} )
 _args=$( _cdr ${command_args} )
'
alias commands='
 #test "${_command}" || { local _command ; _command="${1}" ; }
 #test "${_args}" || { local _args ; _args=${@:2} ; }
 { local _command ; _command="${1}" ; }
 { local _args ; _args=${@:2} ; }
 test ! "$( declare -f ${FUNCNAME}-${_command} )" && {
  {    
    test ! "${_command}" || {
     echo "${FUNCNAME} command \"${_command}\" not yet implemented"
    }
    list-available-commands ${FUNCNAME} 
  } 1>&2
 true
 } || {
  ${FUNCNAME}-${_command} ${_args}
 }
'
alias run-command='
 {
   commands
 } || true
'
alias handle-command-args='
 case ${command_args} in
   q|quit) {
    break  
   } ;; 
   *) { 
    parse-command-args
   } ;;
 esac
'
alias command-loop='
 while [ ! ]
 do
  run-command
  read-command-args
  handle-command-args
 done
'
##################################################
#!/bin/bash
## error
## =standalone=
## version: 2.0.7 - revise date format
#####################################################################################
{ # error handling

 set -e # exit on error

 date_offset=0 # may depreciate later
 _date() {   _() { echo "date" ; } ;  __() { echo "--$( _ )=@$(( $( $( _ ) +%s ) + ${date_offset} ))" ; } ;  ___() { echo "+%y%m%dT%H%M" ; } ;  "$( _ )" "$( __ )" "$( ___ )" ; }  
 _finally() { true ; }
 _cleanup() { true ; }
 _on_error() { true ; }
 _on_success() { true ; }
 error-show() {
  cat << EOF
error_message: ${error_message}
error_function_name: ${error_function_name}
error_line_number: ${error_line_number}
error_show: ${error_show}
EOF
 }
 error-help() {
  cat << EOF
error
- error handling interface

USAGE

# show|hide error errors
error true|false

# exit with error message
false || {
 error "manual break" "\${BASH_FUNC}" "\${LINE_NO}"
 false
}


EOF
 } 
 error() {
  case ${#} in
   3) {
    error_message="${1}"
    error_function_name="${2}"
    error_line_number="${3}" 
   } ;;
   1) {
    error_show=${1}
   } ;;
  esac
 }
 _exit() { set +v +x ; { local function_name ; local line_number ; function_name=${1} ; line_number=${2} ; }
 if-function-name() { _() { echo $( test "${1}" && { echo "${1}" ; true ; } || { echo "${2}" ; } ; ) ; } ; _ "${error_function_name}" "${function_name}" ; }
 if-line-number() { _() { echo $( test ! "${1}" -a ! ${2} -ne 1 || { echo "on line" ; test ! "${1}" && { test ! ${2} -ne 1 || { echo "${2}" ; } ; true ; } || { echo "${1}" ; } ; } ; ) ; } ; _ "${error_line_number}" "${line_number}" ; }
 if-message() { _() { test ! "${1}" || { echo "\"${1}\"" ; } ; } ; _ "${error_message}" ; }
 if-error-show() {
   test "${error_show}" = "false" || {
    cat >> error-log << EOF
$( _date ) ${0} $( if-message )
error in $( if-function-name ) $( if-line-number )
EOF
    echo $( tail -n 2 error-log ) 1>&2 # stdout to stderr
   }
  }
  test ! "${function_name}" = "" && {
   if-error-show 
   _on_error
  true
  } || { # on success
   _on_success
  }
  _finally ; _cleanup ;
 }
 error "false" # default
 trap '_exit "${FUNCNAME}" "${LINENO}"' EXIT ERR
}
#####################################################################################
error "true"			# show errors
#!/bin/bash
## cecho
## - color echo
## version 0.0.2 - remove entry
##################################################
cecho-color() { #{ local candidate_color ; candidate_color="${1}" ; }
 case ${candidate_color} in
  blue) {
   echo 34 
  } ;;
  yellow) {
   echo 33
  } ;;
  green) {
   echo 32 
  } ;; 
  *) {
   echo 0
  } ;;
 esac
}
#-------------------------------------------------
cecho() { { local candidate_color ; candidate_color="${1}" ; local line ; line=${@:2} ; }
  test ! "${line}" || {
    echo -e "\e[$( ${FUNCNAME}-color )m ${line} \e[0m" 
  } 1>&2
}
##################################################
#!/bin/bash
## build
## version 0.0.1 - initial
##################################################
build() {
  local outfile
  outfile="${build}/$( basename ${0} .sh )-$( date +%y%m%dT%H%M )"
  cecho green "building standalone ..."
  ################################################
  ## 1.  cleanup build (creates empty build dir)
  ## 1.  populate build (minimum: source script)
  ## 1.1 migrate script
  ################################################
  ## 1. cleanup build (creates empty build dir)
  ################################################
  cecho green "cleanup up build ..."
  cecho yellow $( test ! -d "${build}" || rm -rvf ${_} )
  cecho yellow $( mkdir -v "${build}" )
  cecho green "build clean"
  ################################################
  ## 1. populate build (minimum: source script)
  ################################################
  ## 1.1 migrate script
  ## - resolves '.' lines
  ## - keeps 'source' lines
  ################################################
  { # resolve source lines
    bash -vp ${0} true 2>&1 | 
    grep -v -e '^\s*[.]\s\+' 
  } | tee ${outfile}-build.sh
  { # make source copies
    cp ${0} ${outfile}-src.sh
    cp ${0} ${build}/${0}
  }
  ################################################
  cecho green "standalone built"
}
##################################################
## generated by create-stub2.sh v0.1.2
## on Sat, 04 May 2019 11:57:45 +0900
## see <https://github.com/temptemp3/sh2>
##################################################
_finally() {
  cecho green "fds before cleaning up"
  ls /dev/fd
  cecho green "cleaning up ..."
  fd-cleanup 10
  cecho green "fds after cleaning up"
  ls /dev/fd
}
fd-file() { 
  echo /tmp/test-read-fd-${1}
}
fd-cleanup() { { local fd_count ; fd_count="${1-1}" ; }
  cecho green "cleaning up fds ..."
  _() {
    eval "exec ${i}<&-"
    rm $( fd-file ${i} ) 2>/dev/null || true
  }
  fd-foreach _
  cecho green "done cleaning up fds"
}
fd-initialize() { { local fd_count ; fd_count="${1-1}" ; }
  cecho green "initializing fds ..."
  _() {
    cecho green "initializing fd ${i} ..."
    cat /dev/null > $( fd-file ${i} )
    eval "exec ${i}< $( fd-file ${i} )"
    cecho green "fd ${i} intialized"
  }
  fd-foreach _
  cecho green "fds intialized"
}
fd-range() {
  seq 3 $(( fd_count + 3 ))
}
fd-foreach() { { local function_name ; function_name="${1}" ; }
  local i 
  for i in $( fd-range )
  do
    ${function_name}
  done
}
fd() {
  commands
}
test-read-fd-train-initialize() {
  fd-initialize ${fd_count}
}
test-read-fd-train() { { local fd_count ; fd_count="${1-1}" ; }
  ${FUNCNAME}-initialize
  seq 3 $(( fd_count + 3 )) | while read -r i ; do echo ${i} > $( fd-file ${i} ) ; done
  for j in $( seq 4 $(( fd_count + 3 - 1 )) )
  do
   cecho green "reading from fd $(( ${j} - 1 )) ..."
   while read -u $(( ${j} - 1 )) i ; do echo ${i} >> $( fd-file ${j} ) ; done 
   cecho green "done reading from fd $(( ${j} - 1 ))"
  done
  cecho green "reading from fd $(( fd_count + 3 - 1 )) and $(( fd_count + 3 )) ..."
  {
    while read -u $(( fd_count + 3 )) i ; do echo ${i} ; done 
    while read -u $(( fd_count + 3 - 1  )) i ; do echo ${i} ; done 
  } | xargs
}
test-read-fd-true() {
  true
}
test-read-fd-build() {
  build=build
  build 
}
test-read-fd() {
  commands 
}
##################################################
if [ ! ] 
then
 true
else
 exit 1 # wrong args
fi
##################################################
test-read-fd ${@}
##################################################
## generated by create-stub2.sh v0.1.2
## on Sat, 22 Jun 2019 13:50:11 +0900
## see <https://github.com/temptemp3/sh2>
##################################################
