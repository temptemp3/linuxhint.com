#!/bin/bash
## debug-restricted
## version 0.0.1 - initial
##################################################
debug-restricted() {
  cd ..
}
##################################################
if [ ${#} -eq 0 ] 
then
 true
else
 exit 1 # wrong args
fi
##################################################
debug-restricted
##################################################
## generated by create-stub2.sh v0.1.2
## on Wed, 22 May 2019 21:54:27 +0900
## see <https://github.com/temptemp3/sh2>
##################################################
