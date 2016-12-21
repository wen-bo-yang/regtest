#!/bin/bash
# Copyright (c) 2016 PaddlePaddle Authors. All Rights Reserved
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
    echo "  --dockerhub : specify the conf file and build from dockerhub"
    echo "  --github    : specify the conf file and build from github"
    echo "  -h --help   : print this help message"
    echo ""
    echo "e.g.:"
    echo "  $0 --dockerhub=dockerhub    : build images from paddle dockerhub"
    echo ""
    echo "  $0 --github=github          : build images from paddle github" \
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
    params=$(grep -v "#" ${CONF_FILE} | awk -F "=" '{if($1 ~ /'${ITEM}/'){print $2}}')
    echo ${params}
}

############################################
# Prepare dockerfile
# Globals:
#   $CONF_FILE
#   $PADDLE_DF_PATH
#   $PADDLE_DF_NAME
#   $VERSION
# Arguments:
#   None
# Returns:
#   None
############################################
function prepare_dockerfile() {
    echo "...................begin prepare dockerfile..................."
    if [[ ${SOURCE_FROM} == 'github' ]]; then
        cp ${PADDLE_DF_PATH}/${PADDLE_DF_NAME} ${PADDLE_DF_PATH}/${PADDLE_DF_NAME}.bak
        sed -i "/build.sh$/a\RUN cp -r /paddle/ /root/" \
            ${PADDLE_DF_PATH}/${PADDLE_DF_NAME}
    elif [[ ${SOURCE_FROM} == 'dockerhub' ]]; then
        sed -i "s#FROM .*\$#FROM paddledev/paddle:${VERSION}#g" ./Dockerfile
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
    if [[ ${SOURCE_FROM} == 'github' ]]; then
        cp ${PADDLE_DF_PATH}/${PADDLE_DF_NAME}.bak ${PADDLE_DF_PATH}/${PADDLE_DF_NAME}
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
    ## create container run regression test
    ${DOCKER} run \
        ${GPU_SO} \
        ${GPU_DEVICES} \
        ${GPU_NVIDIA_SMI} \
        -v ${FAKE_ROOT}:${DOCKER_ROOT} \
        --name=${DOCKER_CONTAINER_NAME} \
        ${DOCKER_IMAGE_NAME}:${VERSION} \
        ${SHELL_TYPE} \
        ${DOCKER_ROOT}/demo_run.sh ${MOD} ${DEMO_NAME}
    ### create container and show container OUTPUT for DEBUG
    #${DOCKER} run \
    #    ${GPU_SO} \
    #    ${GPU_DEVICES} \
    #    ${GPU_NVIDIA_SMI} \
    #    -v ${FAKE_ROOT}:${DOCKER_ROOT} \
    #    --name=${DOCKER_CONTAINER_NAME} \
    #    ${DOCKER_IMAGE_NAME}:${VERSION} \
    #    ${GPU_NVIDIA_SMI}
    #${DOCKER} run -d \
    #	-p 8997:22 \
    #	${GPU_SO} \
    #	${GPU_DEVICES} \
    #    ${GPU_NVIDIA_SMI} \
    #	-v ${FAKE_ROOT}:${DOCKER_ROOT} \
    #   --security-opt seccomp=unconfined \
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
# LOCALS:
#   $ubuntu_mirror
# Arguments:
#   None
# Returns:
#   None
#########################################################
function build_docker_image(){
    local ubuntu_mirror
    if [[ -n ${UBUNTU_MIRROR} ]]; then
        ubuntu_mirror='--build-arg UBUNTU_MIRROR="'${UBUNTU_MIRROR}'"'
    else
        ubuntu_mirror=''
    fi

	echo "...................begin build image..................."
    init_image
    if [[ ${SOURCE_FROM} == 'github' ]]; then
        cd ${PADDLE_SOURCE_DIR}
        if [[ ${SUPPORT_AVX} == 'avx' ]]; then
            echo "avx"
            ${DOCKER} build \
                $ubuntu_mirror \
                -t ${DOCKER_IMAGE_NAME}:${VERSION} \
                -f ${PADDLE_DF_PATH}/${PADDLE_DF_NAME} .
        elif [[ ${SUPPORT_AVX} == 'noavx' ]]; then
            echo "noavx"
            ${DOCKER} build \
                --build-arg WITH_AVX=OFF \
                $ubuntu_mirror \
                -t ${DOCKER_IMAGE_NAME}:${VERSION} \
                -f ${PADDLE_DF_PATH}/${PADDLE_DF_NAME} .
        else
            echo "UNKNOW BUILD PADDLE SOURCE IMAGE"
        fi
        cd ${BASE_DIR}
    elif [[ ${SOURCE_FROM} == 'dockerhub' ]]; then
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
    local git_branch=''
    if [[ -d ${PADDLE_SOURCE_DIR} ]]; then
        rm -rf ${PADDLE_SOURCE_DIR}
    fi
    echo "------------------------------------------"
    echo "git clone paddle branch is " ${GIT_BRANCH} 
    echo "------------------------------------------"
    ${GIT} clone --recursive -b ${GIT_BRANCH} ${PADDLE_GIT_REPO}
    cd ${PADDLE_SOURCE_DIR}
    git_branch=( $(git describe --contains --all HEAD) )
    if [[ ${git_branch} != ${GIT_BRANCH} ]]; then
        err "git clone branch is not existed"
        exit -1
    fi
    cd ${BASE_DIR}
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
#   $UBUNTU_MIRROR
#   $SUPPORT_AVX
#   $PADDLE_DF_NAME
# Locals:
#   $opt
# Arguments:
#   $@
# Returns:
#   None
#########################################################
function pre_params() {
    echo "parameters is " $@
    if [[ $# -eq 0 || $# -gt 1 ]]; then
        usage
        exit -1
    fi
    while getopts c:h-: opt; do
        case ${opt} in
            -)
                case ${OPTARG} in
                    help)
                        usage
                        exit 0
                        ;;
                    github=*)
                        CONF_FILE=${OPTARG#*=}
                        SOURCE_FROM='github'
                        ;;
                    dockerhub=*)
                        CONF_FILE=${OPTARG#*=}
                        SOURCE_FROM='dockerhub'
                        ;;
                    *)
                        usage
                        exit 1
                        ;;
                esac
                ;;
            h)
                usage
                exit 0
                ;;
            ?)
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
    if [[ ${SOURCE_FROM} == 'github' ]]; then
        UBUNTU_MIRROR=( $(parser_params ${CONF_FILE} ubuntu_mirror) )
        PADDLE_GIT_REPO=( $(parser_params ${CONF_FILE} paddle_git_repo) )
        GIT_BRANCH=( $(parser_params ${CONF_FILE} paddle_branch) )
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

if [[ ${SOURCE_FROM} == 'github' ]]; then
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
elif [[ ${SOURCE_FROM} == 'dockerhub' ]]; then
    init_container
    echo "---------------------------------"
    echo rebuild docker images is ${IS_BUILD}
    echo "---------------------------------"

    if [[ "${IS_BUILD}" == "ON" ]]; then
        prepare_dockerfile
        build_docker_image
    fi

    run_container
else
    err "UNKNOW SOURCE OF PADDLE"
    usage
    exit 1
fi
