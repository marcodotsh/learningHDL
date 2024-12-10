#!/usr/env python

import re
import sys

def check_res(res,prio):
    isValid = True
    for i in range(len(res)):
         if (i==prio and res[i] != "1") or (i != prio and res[i] != "0"):
            isValid = False
            break
    return isValid


for line in sys.stdin:
    if(re.search(r'r=([01]*) p=([01]*) res=([01]*)',line) == None): continue

    r, p, res = re.search(r'r=([01]*) p=([01]*) res=([01]*)',line).groups()
    
    if(p.count("1") != 1):
        print("Error in generation: p vector must have exactly a 1")
        print("r=\t{}\np=\t{}\nres=\t{}".format(r,p,res))
        exit(1)

    if(r.count("1") == 0):
        if(res.count("1") != 0):
            print("Error in computation: with 0 requests there should be no grant")
            print("r=\t{}\np=\t{}\nres=\t{}".format(r,p,res))
            exit(1)
        else:
            print("Correct result")
            print("r=\t{}\np=\t{}\nres=\t{}".format(r,p,res))
            continue

    n = len(p)

    prio = p.index("1")

    while(True):
        if r[prio] == "1":
            if(check_res(res,prio)):
                print("Correct result")
                print("r=\t{}\np=\t{}\nres=\t{}".format(r,p,res))
                break
            else:
                print("Error in computation: invalid result")
                print("r=\t{}\np=\t{}\nres=\t{}".format(r,p,res))
                exit(1)
        else: prio = prio-1 if prio-1 >= 0 else n+prio-1 

