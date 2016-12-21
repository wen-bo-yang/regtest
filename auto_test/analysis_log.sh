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

function usage() {
  echo "Usage: $0 -i MONITOR_LOG -t TRAIN_LOG -g GENERATED_LOG_PATH -s SAVE_LOG_PATH"
}

if [ $# -eq 0 ];then
  usage
  exit -1
fi

TEST_PATH="$(pwd)"
LOG_PATH=`ls ${TEST_PATH} | grep logdir | sort | tail -n 1`
if [ x$LOGPATH == x ];then
    LOG_PATH=$TEST_PATH/logdir
fi

while getopts "g:s:i:t:" arg;do
  case ${arg} in
    g)
      GENERATED_LOG_PATH=${OPTARG}
      ;;
    s) 
      SAVE_LOG_PATH=${OPTARG}
      ;;
    i)
      MONITOR_LOG=${OPTARG}
      ;;
    t)
      TRAIN_LOG=${OPTARG}
      ;;
    ?)
      usage
      exit 1
      ;;
  esac
done

mkdir -p ${LOG_PATH}/${SAVE_LOG_PATH}

awk '{if ($0 ~ /Batch=/) print $1,$2,$5,$6,$7,$8,$10,$12; else if ($0 ~ /Test samples/) print $1,$2,$6,$7,$9}' \
  ${GENERATED_LOG_PATH}/${TRAIN_LOG} > ${LOG_PATH}/${SAVE_LOG_PATH}/${TRAIN_LOG}.out
python ${TEST_PATH}/add_tag.py -m ${GENERATED_LOG_PATH}/${MONITOR_LOG}  -l ${LOG_PATH}/${SAVE_LOG_PATH}/${TRAIN_LOG}.out  \
  -o ${LOG_PATH}/${SAVE_LOG_PATH}/${MONITOR_LOG}.out
