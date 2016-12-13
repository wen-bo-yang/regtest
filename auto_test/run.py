#!/usr/bin/env python
# -*- coding:utf-8 -*-

import ConfigParser
import string,os,sys
import subprocess
import time

def parse_conf(filename,demo_mode):
    cf = ConfigParser.ConfigParser()
    cf.read(filename)
    secs = cf.sections()
    opts = cf.options(demo_mode)
    print 'options:',opts
    optList = ['download', 'preprocess', 'train', 'test', 'predict', 'log']
    outList = []
    for opt in optList:
        if opt in opts:
            out = cf.get(demo_mode, opt)
            outList.append(out)
        else:
            outList.append(None)
    return outList

def download_pro(download):
    if download is not None:
        download_pro = subprocess.call(download, shell=True)

def preprocess_pro(preprocess):
    if preprocess is not None:
        preprocess_pro = subprocess.call(preprocess, shell=True)
    
def train_pro(train):
    if train is not None:
        train_pro = subprocess.call(train, shell=True)
    
def predict_pro(predict):
    if predict is not None:
        predict_pro = subprocess.call(predict, shell=True)

def test_pro(test):
    if test is not None:
        test_pro = subprocess.call(test, shell=True)

def replace_mode_pro(source, gpu_mode, demo_mode, sub_demo):
    """replace mode when need gpu or cpu
    Args:
        source:the file need to replace
        gpu_mode:the value of gpu_mode
        demo_mode:the name of demo
        sub_demo:the name of sub_demo
    """
    if source is not None:
        source = source.split('./')[1]
        os.path.isfile(source)
        destination = source + "_bak"
        demoList = ['lr','emb','cnn','lstm','all']
        if gpu_mode in ["gpu"]:
            if demo_mode == 'image_classification':
                cmd1 = ["sed", "s/^use_gpu=1/use_gpu=1/g", source, ]
            else:
                if sub_demo is not None:
                    cmd2 = ["sed","s/.*trainer_config.lr.*/#cfg=trainer_config.lr.py/g", destination, ]
                    cmd3 = ["sed","/%s/s/^#//" % sub_demo, source, ]
                cmd1 = ["sed","s/.*use_gpu.*/  --use_gpu=True \\\/g", source, ]
        else:
            if demo_mode == 'image_classification':
                cmd1 = ["sed","s/^use_gpu=1/use_gpu=0/g",source,]
            else:
                if sub_demo is not None:
                    cmd2 = ["sed","s/.*trainer_config.lr.*/#cfg=trainer_config.lr.py/g", destination, ]
                    cmd3 = ["sed","/%s/s/^#//" % sub_demo,source,]
                cmd1 = ["sed","s/.*use_gpu.*/  --use_gpu=False \\\/g", source,]
        subprocess.call(cmd1,stdout=open(destination,'w'))
        if sub_demo is not None:
            subprocess.call(cmd2, stdout=open(source,'w'))
            subprocess.call(cmd3, stdout=open(destination,'w'))
        os.rename(destination, source)
        os.system('chmod +x '+source)

def get_sub_demo(demo_mode):
    """get the name of sub demo!"""

    if demo_mode.find('@') >= 0:
        print "Demo_mode contains the sub demo!"
        sub_demo = demo_mode.split('@')[1]
        demo_name = demo_mode.split('@')[0]
    else:
        demo_name = demo_mode
        sub_demo = None
    return demo_name,sub_demo

def main(argv):
    demo_conf = sys.argv[1]
    demo_name = sys.argv[2]
    gpu_mode = sys.argv[3]

    DEMO_PATH = "/root/paddle/demo/"
    demo_mode,sub_demo = get_sub_demo(demo_name)
    [download,preprocess,train,test,predict, log] = parse_conf(demo_conf,demo_mode)
    workdir = os.path.join(DEMO_PATH,demo_mode)
    os.chdir(workdir)
    download_pro(download)
    os.chdir(workdir)
    preprocess_pro(preprocess)
    if demo_mode == 'seqToseq':
        curdir = os.path.join(workdir,"translation")
        os.chdir(curdir)
    if demo_mode == 'sentiment':
        replace_mode_pro(test,gpu_mode,demo_mode,sub_demo)
        test_pro(test)

    os.system('nohup /root/auto_test/monitor.sh &')
    if demo_mode is 'recommendation':
        os.system("sed -i '/num_passes/s/=[0-9]*/=5/' " + train)
    if demo_mode is not 'semantic_role_labeling':
        replace_mode_pro(train,gpu_mode,demo_mode,sub_demo)
    train_pro(train)

    if demo_mode == 'seqToseq':
        test_name = test.split('&')[1]
        replace_mode_pro(test_name,gpu_mode,demo_mode,sub_demo)
        test_pro(test_name)
    
    demo_path = demo_mode
    if sub_demo:
        demo_path += '/' + sub_demo
    os.system('/root/auto_test/analysis_log.sh -d %s -s %s -i capability -t %s' % (DEMO_PATH+demo_mode, demo_path, log))

    if demo_mode in ['quick_start','image_classification']:
        replace_mode_pro(predict,gpu_mode,demo_mode,sub_demo)
    predict_pro(predict)
  
if __name__ == '__main__':
    main(sys.argv)    