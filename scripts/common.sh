#!/bin/bash

# Author: PresentJay (정현재, presentj94@gmail.com)

case $(uname -s) in
    "Darwin"* | "Linux"*) export _OS_="linux" ;;
    "MINGW32"* | "MINGW64"* | "CYGWIN" ) export _OS_="windows" ;;
    *) log_kill "this OS($(uname -s)) is not supported yet." ;;
esac

#########################
#### Check Functions ####
#########################

# param $1: command 동작을 확인하려는 대상
# example $1: "multipass", "kubectl", ...
checkPrerequisite() {
    silentRun=$($1 | grep "command not found: $1") && log_kill "$1 unavailable"
    unset silentRun
}


# param $1: dash-param 인자에 대해서 공백 없이, one character
# example $1: "ie", "a", "iu" ...
checkOpt() {
    checkDash=$1
    shift
    while getopts ${checkDash}h-: OPT; do
        if [ $OPT = "-" ]; then
            OPT=${OPTARG%%=*}
            OPTARG=${OPTARG#$OPT}
            OPTARG=${OPTARG#=}
        fi
        case $OPT in
            *) echo $OPT ;;
            ?) eval "log_kill parameter-fault" ;;
        esac
    done
}

# param $1: exist check하려는 env name (Upper-case)
# example $1: "ITER"
checkEnv() {
    [[ -n $(printenv | grep $1) ]] && log_test "$1 is exist" || log_test "$1 is not exist"
}

#######################
#### Log Functions ####
#######################

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

log_help_head() {
    echo -e "\n$1 [Options ...]"
    log_help_content h help "print help messages"
}

log_help_content() {
    if [[ $# -gt 2 ]]; then
        param_cnt=1
        echo -en "\t["
        while (($param_cnt<$#)); do
            case ${param_cnt} in
                1)
                    echo -n "-"
                    echo -n "${!param_cnt}"
                ;;
                *)
                    echo -n ", --${!param_cnt}"
                ;;
            esac
            param_cnt=$((${param_cnt}+1))
        done
        echo -e "]: ${!param_cnt}"
    elif [[ $# -eq 2 ]]; then
        echo -e "\t[--$1]: $2"
    fi
}

log_help_tail() {
    echo -e "\n"
    exit 1
}

################################
#### Optimization Functions ####
################################

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

cleanUp() {
    case $_OS_ in
        linux)
            if [[ -e longhorn.sh ]]; then
                echo -n "[DELETE] "
                rm -v longhorn.sh 
            fi

            if [[ -e k8s.sh ]]; then
                echo -n "[DELETE] "
                rm -v k8s.sh
            fi

            if [[ -e /usr/local/bin/longhorn ]]; then
                echo -n "[DELETE] "
                rm -v /usr/local/bin/longhorn
            fi

            if [[ -e /usr/local/bin/k8s ]]; then
                echo -n "[DELETE] "
                rm -v /usr/local/bin/k8s
            fi
        ;;
        window)
            if [[ -e longhorn.bat ]]; then
                echo -n "[DELETE] "
                rm -v longhorn.bat 
            fi

            if [[ -e k8s.bat ]]; then
                echo -n "[DELETE] "
                rm -v k8s.bat
            fi
        ;;
    esac
}
