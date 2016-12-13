#!/usr/bin/python
import sys
import datetime
import bisect

def readMonitorFile(monitorFile):
    monitorTime = []
    with open(monitorFile, 'r') as f:
        line = f.readline()
        line = f.readline()
        line = f.readline()
        while line:
            time = line.split()[0]
            dtime = datetime.datetime.strptime(time, "%Y-%m-%d_%H:%M:%S")
            monitorTime.append(dtime)
            line = f.readline()
    return monitorTime



def readTrainLogFileAndLocateTag(logFile, monitorTime):
    tagList = {}
    with open(logFile, 'r') as f:
        line = f.readline()
        while line:
            [t1, t2, tag] = line.split()[:3]
            t1 = t1.replace('I','').replace('.','')
            dtime = datetime.datetime.strptime(str(datetime.datetime.now().year) + "-" + t1[:2] + "-" + t1[2:] 
                    + "_" + t2.split('.')[0], "%Y-%m-%d_%H:%M:%S")
            index= bisect.bisect(monitorTime, dtime)
            if index not in tagList.keys() or "Pass" not in tagList[index]:
            	tagList[index] = tag
            line = f.readline()
    return tagList

def addTagToMonitor(monitorTime, monitorFile, tagList, outMonitorFile):
    with open(monitorFile, 'r') as IN:
        with open(outMonitorFile, 'w') as OUT:
            index = 0
            line = IN.readline()
            while line:
                if index in tagList.keys():
                    print >>OUT, line.strip(),tagList[index]
                else:
                    print >>OUT, line.strip()
                line = IN.readline()
                index += 1

if __name__ == '__main__':
    monitorFile = sys.argv[1]
    logFile = sys.argv[2]
    outMonitorFile = sys.argv[3]

    monitorTime = readMonitorFile(monitorFile)
    tagList = readTrainLogFileAndLocateTag(logFile, monitorTime)
    addTagToMonitor(monitorTime, monitorFile, tagList, outMonitorFile)

