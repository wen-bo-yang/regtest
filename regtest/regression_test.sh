#!/bin/bash
#######################################################
#
# Copyright (c) 2016 Baidu, Inc. All Rights Reserved
# Author PADDLE QA TEAM
#
# paddle regression test
#
#######################################################

#set -x

MOD=''
VERSION=''
IS_BUILD=''
CONF_FILE=''
DEMO_NAME=''
SHELL_TYPE=/bin/bash
DOCKER=$( which docker )
GIT=$( which git )
BASE_DIR=${PWD}
PADDLE_SOURCE_DIR=${BASE_DIR}/Paddle
FAKE_ROOT=${BASE_DIR}/auto_test
DOCKER_ROOT=/root/auto_test
PADDLE_DF_PATH=${BASE_DIR}/Paddle/paddle/scripts/docker

############################################
# Show the help message
# Globals:
#   $0
# Arguments:
#   None
# Returns:
#   None
############################################
function usage(){
    echo "Usage: $0 [option] [arg]"
    echo ""
    echo "Options and arguments"
    echo ""
    echo "  -c --conf   : specify the conf path"
    echo "  -h --help   : print this help message"
    echo ""
    echo "e.g.:"
    echo "  $0 -c dockerhub        : build images from paddle dockerhub"
    echo "  $0 --conf=dockerhub    : build images from paddle dockerhub"
    echo ""
    echo "  $0 -c github           : build images from paddle github" \
                                     "that branch is develop"
    echo "  $0 --conf=github       : build images from paddle github" \
                                     "that branch is develop"
    echo ""
}

############################################
# Print the error message
# Globals:
#   None
# Arguments:
#   $@
# Returns:
#   None
############################################
function err() {
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" >&2
}

############################################
# Parser parameter from $CONF_FILE
# Globals:
#   $CONF_FILE
# Arguments:
#   $CONF_FILE
#   key in $CONF_FILE
# Returns:
#   None
############################################
function parser_params() {
    INIFILE=$1
    ITEM=$2
    params=$( cat ${CONF_FILE} \
        | grep -v "#" \
        | awk -F "=" '{if($1 ~ /'${ITEM}/'){print $2}}' )
    echo ${params}
}

############################################
# Prepare dockerfile
# Globals:
#   $CONF_FILE
#   $PADDLE_DF_PATH
#   $PADDLE_DF_NAME
#   $CHINA_APT_MIRRORS
#   $VERSION
# Arguments:
#   None
# Returns:
#   None
############################################
function prepare_dockerfile() {
    echo "...................begin prepare dockerfile..................."
    if [[ ${CONF_FILE} == 'github' ]]; then
        cp ${PADDLE_DF_PATH}/${PADDLE_DF_NAME} ${PADDLE_DF_PATH}/${PADDLE_DF_NAME}.bak
        if [[ ${CHINA_APT_MIRRORS} == 'ON' ]]; then
            sed -i "/RUN apt-get update/i\RUN sed -i 's#http://archive.ubuntu.com#http://mirrors.163.com#g' /etc/apt/sources.list" \
                ${PADDLE_DF_PATH}/${PADDLE_DF_NAME}
        fi
        sed -i "/build.sh$/a\RUN cp -r /paddle/ /root/" \
            ${PADDLE_DF_PATH}/${PADDLE_DF_NAME}
    elif [[ ${CONF_FILE} == 'dockerhub' ]]; then
        sed -i "s#FROM .*\$#FROM paddledev/paddle:${VERSION}#g" ./Dockerfile
        if [[ ${CHINA_APT_MIRRORS} == 'ON' ]]; then
            sed -i "/apt-get update/i\    sed -i 's#http://archive.ubuntu.com#http://mirrors.163.com#g' /etc/apt/sources.list" \
                ./build_docker.sh
        fi
    else
        err "UNKNOWN prepare dockerfile in function prepare_dockerfile"
        exit 1
    fi
    echo "...................end prepare dockerfile....................."
}

############################################
# repair env
# Globals:
#   $CONF_FILE
#   $PADDLE_DF_PATH
#   $PADDLE_DF_NAME
# Arguments:
#   None
# Returns:
#   None
############################################
function repair_env() {
    if [[ ${CONF_FILE} == 'github' ]]; then
        cp ${PADDLE_DF_PATH}/${PADDLE_DF_NAME}.bak ${PADDLE_DF_PATH}/${PADDLE_DF_NAME}
    elif [[ $CONF_FILE == 'dockerhub' ]]; then
        sed -i "/^ .*sed -i 's#/d" ./build_docker.sh
    fi
}

######################################################
# Running docker container use builded docker images
# Globals:
#   $MOD
#   $GPU_SO
#   $GPU_DEVICES
#   $DOCKER
#   $FAKE_ROOT
#   $DOCKER_ROOT
#   $GPU_NVIDIA_SMI
#   $DOCKER_CONTAINER_NAME
#   $SHELL_TYPE
#   $DEMO_NAME
# Arguments:
#   None
# Returns:
#   None
######################################################
function run_container(){
    if [[ ${MOD} == "gpu" ]]; then
        echo "...................begin load_gpu.............................."
        export GPU_SO="$( \ls /usr/lib64/libcuda* | xargs -I{} echo '-v {}:{}' ) \
            $( \ls /usr/lib64/libnvidia* | xargs -I{} echo '-v {}:{}' )"
        export GPU_DEVICES=$( \ls /dev/nvidia* | xargs -I{} echo '--device {}:{}' )
        export GPU_NVIDIA_SMI=$( which nvidia-smi | xargs -I{} echo '-v {}:{}' )
    else
        GPU_SO=''
        GPU_DEVICES=''
        GPU_NVIDIA_SMI=''
    fi
    ## create container
    #${DOCKER} run \
    #    ${GPU_SO} \
    #    ${GPU_DEVICES} \
    #    ${GPU_NVIDIA_SMI} \
    #    -v ${FAKE_ROOT:$DOCKER_ROOT} \
    #    --name=${DOCKER_CONTAINER_NAME} \
    #    ${DOCKER_IMAGE_NAME}:${VERSION} \
    #    ${SHELL_TYPE} \
    #    ${DOCKER_ROOT}/demo_run.sh ${MOD} ${DEMO_NAME}
    ### create container and show container OUTPUT for DEBUG
    #${DOCKER} run \
    #    ${GPU_SO} \
    #    ${GPU_DEVICES} \
    #    ${GPU_NVIDIA_SMI} \
    #    -v ${FAKE_ROOT}:${DOCKER_ROOT} \
    #    --name=${DOCKER_CONTAINER_NAME} \
    #    ${DOCKER_IMAGE_NAME}:${VERSION} \
    #    ${GPU_NVIDIA_SMI}
    ${DOCKER} run -d \
    	-p 8997:22 \
    	${GPU_SO} \
    	${GPU_DEVICES} \
        ${GPU_NVIDIA_SMI} \
    	-v ${FAKE_ROOT}:${DOCKER_ROOT} \
        --security-opt seccomp=unconfined \
    	--name=${DOCKER_CONTAINER_NAME} \
    	${DOCKER_IMAGE_NAME}:${VERSION}
    #${DOCKER} run -d \
    #	-p 8997:22 \
    #	-v ${FAKE_ROOT}:${DOCKER_ROOT} \
    #	--name=${DOCKER_CONTAINER_NAME} \
    #	${DOCKER_IMAGE_NAME}:${VERSION}

    echo "...................end load_gpu................................"
}

######################################################
# Initialize image,if you rebuild docker image
# Globals:
#   $DOCKER_IMAGE_NAME
#   $VERSION
#   $DOCKER
# Arguments:
#   None
# Returns:
#   None
######################################################
function init_image(){
    docker images | grep "${DOCKER_IMAGE_NAME} *.${VERSION} "
    if [[ $? -eq 0 ]]; then
        ${DOCKER} rmi ${DOCKER_IMAGE_NAME}:${VERSION}
    fi
}

#########################################################
# Initialize container,if you rerun the docker container
# with the same docker container name
# Globals:
#   $DOCKER_CONTAINER_NAME
#   $DOCKER
# Arguments:
#   None
# Returns:
#   None
#########################################################
function init_container(){
	echo "..............begin init container..................."
	docker ps -a | grep "${DOCKER_CONTAINER_NAME}"
	if [[ $? -eq 0 ]]; then
		${DOCKER} rm -f "${DOCKER_CONTAINER_NAME}"
	fi
	echo "................end init container..................."
}

#########################################################
# Build docker image
# Globals:
#   $CONF_FILE
#   $PADDLE_SOURCE_DIR
#   $SUPPORT_AVX
#   $DOCKER
#   $DOCKER_IMAGE_NAME
#   $VERSION
#   $PADDLE_DF_PATH
#   $PADDLE_DF_NAME
#   $BASE_DIR
# Arguments:
#   None
# Returns:
#   None
#########################################################
function build_docker_image(){
	echo "...................begin build image..................."
    init_image
    if [[ ${CONF_FILE} == 'github' ]]; then
        cd ${PADDLE_SOURCE_DIR}
        if [[ ${SUPPORT_AVX} == 'avx' ]]; then
            echo "avx"
            ${DOCKER} build \
                -t ${DOCKER_IMAGE_NAME}:${VERSION} \
                -f ${PADDLE_DF_PATH}/${PADDLE_DF_NAME} .
        elif [[ ${SUPPORT_AVX} == 'noavx' ]]; then
            echo "noavx"
            ${DOCKER} build \
                --build-arg WITH_AVX=OFF \
                -t ${DOCKER_IMAGE_NAME}:${VERSION} \
                -f ${PADDLE_DF_PATH}/${PADDLE_DF_NAME} .
        else
            echo "UNKNOW BUILD PADDLE SOURCE IMAGE"
        fi
        cd ${BASE_DIR}
    elif [[ ${CONF_FILE} == 'dockerhub' ]]; then
        ${DOCKER} build -t ${DOCKER_IMAGE_NAME}:${VERSION} .
    else
        err "UNKNOW BUILD DOCKER IMAGE build_docker_image"
        exit 1
    fi
	echo "...................end build image..................."
}

#########################################################
# Pull the paddle source code from github of paddle
# Globals:
#   $PADDLE_SOURCE_DIR
#   $GIT
#   $PADDLE_GIT_REPO
# Arguments:
#   None
# Returns:
#   None
#########################################################
function pull_paddle_source_code() {
    if [[ -d ${PADDLE_SOURCE_DIR} ]]; then
        rm -rf ${PADDLE_SOURCE_DIR}
    fi
    ${GIT} clone ${PADDLE_GIT_REPO}
}

#########################################################
# Prepare parameters
# Globals:
#   $#
#   $OPTARG
#   $CONF_FILE
#   $IS_BUILD
#   $DEMO_NAME
#   $MOD
#   $VERSION
#   $DOCKER_IMAGE_NAME
#   $DOCKER_CONTAINER_NAME
#   $PADDLE_GIT_REPO
#   $CHINA_APT_MIRRORS
#   $SUPPORT_AVX
#   $PADDLE_DF_NAME
# Locals:
#   $OPTIND
#   $opt
# Arguments:
#   $@
# Returns:
#   None
#########################################################
function pre_params() {
    if [[ $# -eq 0 || $# -lt 2 ]]; then
        usage
        exit -1
    fi
    local OPTIND
    while getopts c:h-: opt; do
        case ${opt} in
            -)
                case ${OPTARG} in
                    help)
                        usage
                        exit 0
                        ;;
                    conf=*)
                        CONF_FILE=${OPTARG#*=}
                        ;;
                    *)
                        usage
                        exit 1
                        ;;
                esac
                ;;
            c)
                CONF_FILE=${OPTARG}
                ;;
            h)
                usage
                exit 0
                ;;
            \?)
                usage
                exit 1
                ;;
        esac
    done
    IS_BUILD=( $(parser_params ${CONF_FILE} rebuild) )
    DEMO_NAME=( $(parser_params ${CONF_FILE} demo_name) )
    MOD=( $(parser_params ${CONF_FILE} mod) )
    VERSION=( $(parser_params ${CONF_FILE} version) )
    DOCKER_IMAGE_NAME=( $(parser_params ${CONF_FILE} docker_image_name) )
    DOCKER_CONTAINER_NAME=( $(parser_params ${CONF_FILE} docker_container_name) )
    CHINA_APT_MIRRORS=( $(parser_params ${CONF_FILE} china_apt_mirrors) )
    if [[ ${CONF_FILE} == 'github' ]]; then
        PADDLE_GIT_REPO=( $(parser_params ${CONF_FILE} paddle_git_repo) )
        SUPPORT_AVX=${VERSION##*-}
        if [[ ${MOD} == 'gpu' ]]; then
            PADDLE_DF_NAME=Dockerfile.${MOD}
        elif [[ ${MOD} == 'cpu' ]]; then
            PADDLE_DF_NAME=Dockerfile
        else
            echo "UNKNOW DOCKER FILE NAME"
        fi
    fi
}

pre_params $@

if [[ ${CONF_FILE} == 'github' ]]; then
    init_container

    echo "---------------------------------"
    echo rebuild docker images is ${IS_BUILD}
    echo "---------------------------------"

    if [[ "${IS_BUILD}" == "ON" ]]; then
        pull_paddle_source_code
        prepare_dockerfile
        build_docker_image
        repair_env
    fi

    run_container
elif [[ ${CONF_FILE} == 'dockerhub' ]]; then
    init_container
    echo "---------------------------------"
    echo rebuild docker images is ${IS_BUILD}
    echo "---------------------------------"

    if [[ "${IS_BUILD}" == "ON" ]]; then
        prepare_dockerfile
        build_docker_image
        repair_env
    fi

    run_container
else
    err "UNKNOW SOURCE OF PADDLE"
    usage
    exit 1
fi

