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

source /etc/profile

RUN_PATH="/root/auto_test"
DEMO_PATH="/root/paddle/demo"
logdate=`date "+%Y%m%d_%H%M%S"`
LOG_PATH="/root/auto_test/logdir"_${logdate}
mkdir ${LOG_PATH}
cd ${RUN_PATH}

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

if ([[ $2 == "quick_start" ]] || [[ $2 == "quick_start@all" ]]);then
    echo "run quick start demo !" 
    for demo in ${QUICK_START[@]};do
        python run.py demo.conf ${demo} $1
    done

elif [[ $2 == "all" ]];then
    echo "run all demo start!"
    for demo in ${DEMO_NAME[@]};do
        python run.py demo.conf ${demo} $1
    done

elif [[ "${DEMO_NAME[@]}" =~ "$2" ]];then
    echo "run $2 demo start"
    python run.py demo.conf $2 $1
    
elif [ !$2 ];then
	echo "No need to run demo!"
	exit

else:
	echo "Please enter the right param!"
	exit
	
fi
echo "Run Demo done!"

exit 0
