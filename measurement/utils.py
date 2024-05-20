import os, subprocess, csv
from typing import List
import numpy as np



########## BONALOG ############################################################
COLOR_RED = "\e[31m"
COLOR_GREEN = "\e[32m"
COLOR_BLUE = "\e[34m"
COLOR_YELLOW = "\e[33m"
COLOR_VIOLET = "\e[35m"
COLOR_NONE = "\e[0m"
REDBGR='\033[0;41m'
NCBGR='\033[0m'
def logStage(message):
    os.system(f'echo "{COLOR_GREEN}-----{message}-----{COLOR_NONE}";')
def logNormal(message):
    os.system(f'echo "{COLOR_YELLOW}-----{message}-----{COLOR_NONE}";')
def logInfo(message):
    os.system(f'echo "{COLOR_BLUE}-----{message}-----{COLOR_NONE}";')
def logVio(message):
    os.system(f'echo "{COLOR_VIOLET}-----{message}-----{COLOR_NONE}";')
def logWarn(message):
    os.system(f'echo "{COLOR_RED}-----{message}-----{COLOR_NONE}";')
################################################################################



########## CONFIG HERE ##########
MOTHER_MACHINE_IP = "192.168.101.11"
#################################



def setLatency(bandwidth: int, delay: int, jitter: int) -> None:
    unsetLatency()
    os.system(f"ssh root@{MOTHER_MACHINE_IP} sh ~/netemu/delaynor.sh 100 {bandwidth} {delay} {jitter}")



def setLatencyWithDataset(delay: int, jitter: int) -> None:
    unsetLatency()
    subprocess.Popen(["ssh", f"root@{MOTHER_MACHINE_IP}", f'cd ~/netemu && ./netem.sh {delay} {jitter}'])



def unsetLatency() -> None:
    os.system(f"ssh root@{MOTHER_MACHINE_IP} bash ~/netemu/undelay.sh")



def waitPod(namespace: str, grepName: str, desiredStatus: str) -> None: # desiredStatus = ["running", "terminating"]
    _TIME_SLEEP_INTERVAL = 5
    os.system(f"sleep {_TIME_SLEEP_INTERVAL}")
    if desiredStatus == "running":
        logNormal(f"Waiting for Running Pods: {grepName}")
        while True:
            nTotalPods = int(subprocess.check_output(f"kubectl get pod -n {namespace} | grep {grepName} | wc -l", shell=True).decode("utf-8"))
            nRunningPods = int(subprocess.check_output(f"kubectl get pod -n {namespace} | grep {grepName} | grep Running | wc -l", shell=True).decode("utf-8"))
            if nRunningPods == nTotalPods:
                break
            else:
                os.system(f"sleep {_TIME_SLEEP_INTERVAL}")
    if desiredStatus == "terminating":
        logNormal(f"Waiting for Terminating Pods: {grepName}")
        while True:
            nTotalPods = int(subprocess.check_output(f"kubectl get pod -n {namespace} | grep {grepName} | wc -l", shell=True).decode("utf-8"))
            if nTotalPods == 0:
                break
            else:
                os.system(f"sleep {_TIME_SLEEP_INTERVAL}")



def checkDaemonSet(namespace: str, grepName: str) -> None:
    logNormal(f"Checking DaemonSet: {grepName}")
    _TIME_SLEEP_INTERVAL = 5
    os.system(f"sleep {_TIME_SLEEP_INTERVAL}")
    while True:
        inNode1 = int(subprocess.check_output(f"kubectl get pod -n {namespace} -o wide | grep {grepName} | grep node1 | wc -l", shell=True).decode("utf-8"))
        inNode2 = int(subprocess.check_output(f"kubectl get pod -n {namespace} -o wide | grep {grepName} | grep node2 | wc -l", shell=True).decode("utf-8"))
        inNode3 = int(subprocess.check_output(f"kubectl get pod -n {namespace} -o wide | grep {grepName} | grep node3 | wc -l", shell=True).decode("utf-8"))
        logInfo(str(inNode1) + " " + str(inNode2) + " " + str(inNode3))
        if inNode1 == 1 and inNode2 == 1 and inNode3 == 1:
            break
        else:
            os.system(f"kubectl -n {namespace} delete pod --all")
            os.system(f"sleep {_TIME_SLEEP_INTERVAL}")



def checkActivatorPosition() -> None:
    logNormal(f"Checking Activator Position:")
    _TIME_SLEEP_INTERVAL = 5
    os.system(f"sleep {_TIME_SLEEP_INTERVAL}")
    while True:
        inNode1 = int(subprocess.check_output(f"kubectl get pod -n knative-serving -o wide | grep activator | grep node1 | wc -l", shell=True).decode("utf-8"))
        inNode2 = int(subprocess.check_output(f"kubectl get pod -n knative-serving -o wide | grep activator | grep node2 | wc -l", shell=True).decode("utf-8"))
        inNode3 = int(subprocess.check_output(f"kubectl get pod -n knative-serving -o wide | grep activator | grep node3 | wc -l", shell=True).decode("utf-8"))
        logInfo(str(inNode1) + " " + str(inNode2) + " " + str(inNode3))
        if inNode1 <= 1 and inNode2 <= 1 and inNode3 <= 1:
            break
        else:
            os.system("./utils_cmd/delpod.sh knative-serving activator")
            os.system(f"sleep {_TIME_SLEEP_INTERVAL}")



def patchImage(arch: str) -> None:
    logNormal(f"Patching {arch} image")
    os.system(f"./utils_cmd/patchImage.sh {arch}")
    waitPod("knative-serving", "activator", "running")
    waitPod("knative-serving", "net-kourier-controller", "running")



def readFromCSVFile(resultFile, percentage):
    responseTimes = []
    with open(resultFile, newline='') as csvfile:
        spamreader = csv.reader(csvfile, delimiter=' ')
        for row in spamreader:
            row = str(row)[2:-2].split(",")
            try:
                _responseTime = float(row[0])*1000 # second to millisecond
            except:
                continue
            _statusCode = row[6]
            if _statusCode == "200":
                responseTimes.append(_responseTime)
    responseTimes.sort()
    return responseTimes[:int(round(len(responseTimes)*percentage/100, 0))]



def CDF(data: List):
    count, bins = np.histogram(data, bins=100)
    return {
        "bins": bins,
        "CDF": np.cumsum(count/sum(count))
    }
