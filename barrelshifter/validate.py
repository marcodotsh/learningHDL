#!/usr/env python

import re
import sys

def check_res(input : str, offset : str, out : str):
    shift = int(offset,2)
    return input == (out[-shift:]+out[0:len(out)-shift])


for line in sys.stdin:
    if(re.search(r'in=([01]*) offset=([01]*) out=([01]*)',line) == None): continue

    input, offset, out = re.search(r'in=([01]*) offset=([01]*) out=([01]*)',line).groups()
    
    if(check_res(input,offset,out)):
        print("Correct result")
        print("in=\t{}\noffset=\t{}\nout=\t{}".format(input, offset, out))
    else:
        print("Error in computation")
        print("in=\t{}\noffset=\t{}\nout=\t{}".format(input, offset, out))

