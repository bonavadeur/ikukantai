"""
Command for setting up scenarios
"""

import os
import utils as ut



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



def setupVanillaArch(allin: str) -> None:
    logStage("Setting up Vanilla Arch")
    os.system(f"./utils_cmd/patch.sh vanilla {allin}")
    ut.waitPod("knative-serving", "activator", "running")
    ut.waitPod("knative-serving", "controller", "running")
    ut.waitPod("knative-serving", "autoscaler", "running")
    ut.waitPod("knative-serving", "net-kourier-controller", "running")
    ut.waitPod("kourier-system", "3scale-kourier-gateway", "running")



def setupProposalArch(tag: str) -> None:
    logStage("Setting up Proposal Arch")
    os.system(f"./utils_cmd/patch.sh proposal {tag}")
    ut.waitPod("knative-serving", "activator", "running")
    ut.waitPod("knative-serving", "controller", "running")
    ut.waitPod("knative-serving", "autoscaler", "running")
    ut.waitPod("knative-serving", "net-kourier-controller", "running")
    ut.waitPod("kourier-system", "3scale-kourier-gateway", "running")
    ut.checkActivatorPosition()
    ut.checkDaemonSet("kourier-system", "3scale-kourier-gateway")









def VanillaEdge() -> None:
    setupVanillaArch("cloud")
    os.system("kubectl delete -f ./manifest/proposal.yaml")
    os.system("kubectl apply -f ./manifest/vanilla_edge.yaml")
    ut.waitPod("default", "hello", "running")



def VanillaCloud() -> None:
    setupVanillaArch("cloud")
    os.system("kubectl delete -f ./manifest/proposal.yaml")
    os.system("kubectl apply -f ./manifest/vanilla_cloud.yaml")
    ut.waitPod("default", "hello", "running")



def Vanilla() -> None:
    setupVanillaArch("cloud")
    os.system("kubectl delete -f ./manifest/proposal.yaml")
    os.system("kubectl apply -f ./manifest/vanilla.yaml")
    ut.waitPod("default", "hello", "running")



def Proposal(tag: str) -> None:
    setupProposalArch(tag)
    os.system("kubectl delete -f ./manifest/vanilla.yaml")
    os.system("kubectl apply -f ./manifest/proposal.yaml")
    ut.waitPod("default", "hello", "running")



def VanillaAllOnEdge() -> None:
    setupVanillaArch("edge")
    os.system("kubectl delete -f ./manifest/proposal.yaml")
    os.system("kubectl apply -f ./manifest/vanilla_edge.yaml")
    ut.waitPod("default", "hello", "running")



def VanillaAllOnCloud() -> None:
    setupVanillaArch("cloud")
    os.system("kubectl delete -f ./manifest/proposal.yaml")
    os.system("kubectl apply -f ./manifest/vanilla_cloud.yaml")
    ut.waitPod("default", "hello", "running")
