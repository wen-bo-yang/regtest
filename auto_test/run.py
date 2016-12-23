#!/usr/bin/python
# -*- coding:utf-8 -*-
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
"""Usage: run.py -c [DEMOCONF] -n [DEMONAME] -g [GPUMODE]

 run.py
 Version 1.0

 run.py -- to decide how th run each demo,
           and get the train.log for monitor

Arguments:
    DEMOCONF                the configure file of demo 
    DEMONAME                choose which demo to run 
    GPUMODE                 choose whether to use gpu 

Options:
    -h      --help
    -c      demo_conf
    -n      demo_name
    -g      gpu_mode

"""

import json
import string, os, sys
import subprocess
import time
from docopt import docopt


def parse_conf(filename, demo_mode):
    """
    According to the value of demo_mode,
    get the related information to run each demo.
    :param filename:the process name write in demo_conf.json 
    :param demo_mode:the name of demo_mode which input
    :return: the list for each demo_mode
    """
    with open(filename) as jsonfile:
        json_data = json.load(jsonfile)
        optList = ['download', 'preprocess', 'train', 'test', 'predict', 'log']
        outList = []
        sess = json_data.keys()
        if demo_mode in sess:
            for demo_value in json_data[demo_mode]:
                opts = demo_value.keys()
                for opt in optList:
                    if opt in opts:
                        outList.append(demo_value[opt])
                    else:
                        outList.append(None)
                print outList
                return outList
        else:
            raise ValueError("Demo is not in demo_mode!")


def download_pro(download):
    """
    According to the value of download, to run the download data process.
    :param download: the value of download
    :return:None
    """
    if download is not None:
        download_pro = subprocess.call(download, shell=True)


def preprocess_pro(preprocess):
    """
    According to the value of preprocess, to run the preprocess process.
    :param preprocess: the value of preprocess
    :return:None
    """
    if preprocess is not None:
        preprocess_pro = subprocess.call(preprocess, shell=True)


def train_pro(train):
    """
    According to the value of train, to run the train process.
    :param train: the value of train
    :return:None
    """
    if train is not None:
        train_pro = subprocess.call(train, shell=True)


def predict_pro(predict):
    """
    According to the value of predict, to run the predict process.
    :param predict: the value of predict
    :return:None
    """
    if predict is not None:
        predict_pro = subprocess.call(predict, shell=True)


def test_pro(test):
    """
    According to the value of test, to run the test process.
    :param test: the value of test
    :return:None
    """
    if test is not None:
        test_pro = subprocess.call(test, shell=True)


def replace_mode_pro(source, gpu_mode, demo_mode, sub_demo):
    """
    replace mode when need gpu or cpu
    :param source:the file need to replace
    :param gpu_mode:the value of gpu_mode
    :param demo_mode:the name of demo
    :param sub_demo:the name of sub_demo
    :return:None
    """
    if source is not None:
        source = source.split('./')[1]
        os.path.isfile(source)
        destination = source + "_bak"
        demoList = ['lr', 'emb', 'cnn', 'lstm', 'all']
        if gpu_mode in ["gpu"]:
            if demo_mode == 'image_classification':
                cmd1 = [
                    "sed",
                    "s/^use_gpu=1/use_gpu=1/g",
                    source,
                ]
            else:
                if sub_demo is not None:
                    cmd2 = [
                        "sed",
                        "s/.*trainer_config.lr.*/#cfg=trainer_config.lr.py/g",
                        destination,
                    ]
                    cmd3 = [
                        "sed",
                        "/%s/s/^#//" % sub_demo,
                        source,
                    ]
                cmd1 = [
                    "sed",
                    "s/.*use_gpu.*/  --use_gpu=True \\\/g",
                    source,
                ]
        else:
            if demo_mode == 'image_classification':
                cmd1 = [
                    "sed",
                    "s/^use_gpu=1/use_gpu=0/g",
                    source,
                ]
            else:
                if sub_demo is not None:
                    cmd2 = [
                        "sed",
                        "s/.*trainer_config.lr.*/#cfg=trainer_config.lr.py/g",
                        destination,
                    ]
                    cmd3 = [
                        "sed",
                        "/%s/s/^#//" % sub_demo,
                        source,
                    ]
                cmd1 = [
                    "sed",
                    "s/.*use_gpu.*/  --use_gpu=False \\\/g",
                    source,
                ]
        subprocess.call(cmd1, stdout=open(destination, 'w'))
        if sub_demo is not None:
            subprocess.call(cmd2, stdout=open(source, 'w'))
            subprocess.call(cmd3, stdout=open(destination, 'w'))
        os.rename(destination, source)
        os.system('chmod +x ' + source)


def get_sub_demo(demo_mode):
    """
    get the name of sub demo
    :param demo_mode: the name of demo_mode
    :return:demo_name,sub_demo
    """
    if demo_mode.find('@') >= 0:
        print "Demo_mode contains the sub demo!"
        sub_demo = demo_mode.split('@')[1]
        demo_name = demo_mode.split('@')[0]
    else:
        demo_name = demo_mode
        sub_demo = None
    return demo_name, sub_demo


def main(argv):
    demo_conf = argv['DEMOCONF']
    demo_name = argv['DEMONAME']
    gpu_mode = argv['GPUMODE']

    DEMO_PATH = "/root/paddle/demo"
    demo_mode, sub_demo = get_sub_demo(demo_name)
    [download, preprocess, train, test, predict, log] = parse_conf(demo_conf,demo_mode)
    workdir = os.path.join(DEMO_PATH, demo_mode)
    os.chdir(workdir)
    download_pro(download)
    os.chdir(workdir)
    preprocess_pro(preprocess)
    if demo_mode == 'seqToseq':
        curdir = os.path.join(workdir, "translation")
        os.chdir(curdir)
    if demo_mode == 'sentiment':
        replace_mode_pro(test, gpu_mode, demo_mode, sub_demo)
        test_pro(test)

    os.system('nohup /root/auto_test/monitor.sh &')
    if demo_mode is 'recommendation':
        os.system("sed -i '/num_passes/s/=[0-9]*/=5/' " + train)
    if demo_mode is not 'semantic_role_labeling':
        replace_mode_pro(train, gpu_mode, demo_mode, sub_demo)
    train_pro(train)

    if demo_mode == 'seqToseq':
        test_name = test.split('&')[1]
        replace_mode_pro(test_name, gpu_mode, demo_mode, sub_demo)
        test_pro(test_name)

    demo_path = demo_mode
    if sub_demo:
        demo_path += '/' + sub_demo
    os.system(
        '/root/auto_test/analysis_log.sh -d %s -s %s -i paddle_resource_usage.log -t %s'
        % (DEMO_PATH + demo_mode, demo_path, log))

    if demo_mode in ['quick_start', 'image_classification']:
        replace_mode_pro(predict, gpu_mode, demo_mode, sub_demo)
    predict_pro(predict)


if __name__ == '__main__':
    arguments = docopt(__doc__)
    main(arguments)
