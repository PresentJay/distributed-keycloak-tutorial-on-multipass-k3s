#!/bin/bash

# Author: PresentJay (정현재, presentj94@gmail.com)

# param $1: command 동작을 확인하려는 대상
# example $1: "multipass", "kubectl", ...
checkPrerequisite(){
    silentRun=$($1 | grep "command not found: $1") && log_kill "$1 unavailable"
    unset silentRun
}


# param $1: dash-param 인자에 대해서 공백 없이, one character
# example $1: "ie", "a", "iu" ...
checkOpt(){
    checkDash=$1
    shift $(( OPTIND - 1 ))
    while getopts ${checkDash}: OPT; do
        if [ $OPT = "-" ]; then
            OPT=${OPTARG%%=*}
            OPTARG=${OPTARG#$OPT}
            OPTARG=${OPTARG#=}
        fi
    done
    echo $OPT
}

# param $1: exist check하려는 env name (Upper-case)
# example $1: "ITER"
checkEnv(){
    [[ -n $(printenv | grep $1) ]] && log_test "$1 is exist" || log_test "$1 is not exist"
}

### 로그코드 ###

log_kill() {
    echo >&2 "[ERROR] $@" && exit 1
}

log_info() {
    echo "[INFO] $@"
}

log_success() {
    echo "[SUCCESS] $@"
}

log_test() {
    echo "[TEST] $@"
}

### 로그코드 끝 ###

finalize() {
    case $1 in
        cluster-install)
            unset ITER
            unset K3S_URL
            unset K3S_URL_FULL
            unset K3S_TOKEN
        ;;
    esac
}
