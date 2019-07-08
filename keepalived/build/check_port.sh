#!/bin/bash

#通过返回的状态码$?传递给keepalived，如果grep open为0，则$?为1，如果grep open为1，则$?为0
#udp 加上-u 标识，即 -unvz
/bin/nc -nvz -w 1 $1 $2 2>&1 | grep open &> /dev/null
exit $?
