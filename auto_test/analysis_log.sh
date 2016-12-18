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

TEST_PATH=/root/auto_test
LOG_PATH=`ls ${TEST_PATH} | grep logdir | sort | tail -n 1`

function usage() {
  echo "Usage: $0 -i MONITOR_LOG -t TRAIN_LOG"
}

if [ $# -eq 0 ];then
  usage
  exit -1
fi

while getopts "d:s:i:t:" arg;do
  case ${arg} in
    d)
      DEMO_PATH=${OPTARG}
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

if [ -d ${LOG_PATH}/${SAVE_LOG_PATH} ]; then
  rm -rf ${LOG_PATH}/${SAVE_LOG_PATH}
fi

mkdir -p ${LOG_PATH}/${SAVE_LOG_PATH}

awk '{if ($0 ~ /Batch=/) print $1,$2,$5,$6,$7,$8,$10,$12; else if ($0 ~ /Test samples/) print $1,$2,$6,$7,$9}' \
  ${DEMO_PATH}/${TRAIN_LOG} > ${LOG_PATH}/${SAVE_LOG_PATH}/${TRAIN_LOG}.out
python ${TEST_PATH}/addTag.py -m ${DEMO_PATH}/${MONITOR_LOG}  -l ${LOG_PATH}/${SAVE_LOG_PATH}/${TRAIN_LOG}.out  \
  -o ${LOG_PATH}/${SAVE_LOG_PATH}/${MONITOR_LOG}.out
