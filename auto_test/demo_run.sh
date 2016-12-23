#!/bin/bash
# Copyright (c) PaddlePaddle Authors. All Rights Reserved
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
set -e

source /etc/profile

RUN_PATH="/root/auto_test"
DEMO_PATH="/root/paddle/demo"
logdate=`date "+%Y%m%d_%H%M%S"`
LOG_PATH="/root/auto_test/logdir"_${logdate}
mkdir ${LOG_PATH}
cd ${RUN_PATH}

#the demo list
DEMO_NAME=(
"quick_start@lr"
"quick_start@cnn"
"quick_start@lstm"
"quick_start@emb"
"recommendation"
"sentiment"
"seqToseq"
"image_classification"
"semantic_role_labeling"
)

#the demo name of quick start
QUICK_START=(
"quick_start@lr"
"quick_start@cnn"
"quick_start@lstm"
"quick_start@emb"
)

function usage()
{
  echo "usage: `basename $0` gpu demo_param" >&2
  echo "example: `basename $0` gpu quick" >&2
}

if [ $# -lt 2 ]
then
  usage >&2
  exit 1
fi

#According the name of demo,decide to run which demo;
#if demo_name is in ['quick_start','quick_start@all'], it will run all of the quick start demo;
#if demo_name is in ['all'],it will run all the demo;
#if demo_name is in ['$DEMO_NAME[@]'],it will run the demo input;
#if demo_name is None,it will run no demo and exit;
#if demo_name is not match any,it will exit.
if ([[ $2 == "quick_start" ]] || [[ $2 == "quick_start@all" ]]);then
    echo "run quick start demo !" 
    for demo in ${QUICK_START[@]};do
        python run.py -c demo_conf.json -n ${demo} -g $1
    done

elif [[ $2 == "all" ]];then
    echo "run all demo start!"
    for demo in ${DEMO_NAME[@]};do
        python run.py -c demo_conf.json -n ${demo} -g $1
    done

elif [[ "${DEMO_NAME[@]}" =~ "$2" ]];then
    echo "run $2 demo start"
    python run.py -c demo_conf.json -n $2 -g $1
    
elif [ !$2 ];then
	echo "No need to run demo!"
	exit

else:
	echo "Please enter the right param!"
	exit
	
fi

echo "Run Demo done!"
exit 0
