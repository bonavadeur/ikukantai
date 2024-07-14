#!/root/.kn-measure-venv/bin/python3

import scenarios, sys

arch = sys.argv[1]

if arch == "vanilla":
    allin = sys.argv[2]
    scenarios.setupVanillaArch(allin)
if arch == "proposal":
    tag = sys.argv[2]
    scenarios.setupProposalArch(tag)
