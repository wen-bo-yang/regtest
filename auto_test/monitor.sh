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

date=`date "+%Y-%m-%d_%H:%M:%S"`
output_file="./paddle_resource_usage.log"
echo "--------------- $date BEGIN ---------------" > $output_file
echo -e "DATE\tPID\t%MEM\tMEM\tGPU_MEM\tSTART\tTIME" >> $output_file

get_date(){
  local cur_date=`date "+%Y-%m-%d_%H:%M:%S"`
  local gpu_mem=`nvidia-smi -i 1 -q  -d "MEMORY" | awk -F ":" '{if(NR==11){print $2"_GPU_MEM"}}'`
  ps aux | grep -v "grep" | grep "paddle_trainer"\
    | awk -F " "  '
    {
      print "'$cur_date'"\
      "\t"$2"(PID)"\
      "\t"$4"(%memory)"\
      "\t"$6"(KB memory)"\
      "\t""'"$gpu_mem"'"\
      "\t"$9"(begin time)"\
      "\t"$10"(run durning time)";
    }' >> $output_file
}

trainer_alive=false
alive_or_death_period=0

while true;do
  pid=$( ps aux | grep -v "grep" | grep "paddle_trainer" | awk '{print $2}' )
  if [ x"$pid" != x ];then
    get_date
    trainer_alive=true
    alive_or_death_period=0
  else
    if [ $alive_or_death_period -ge 10 ];then
      echo "No training process detected. Program exit." >> $output_file
      exit 1
    elif [[ $trainer_alive == "true" && $alive_or_death_period -ge 5 ]];then
      echo "Training complete!" >> $output_file
      exit 0
	fi
  fi
  let alive_or_death_period+=1
  sleep 2
done
