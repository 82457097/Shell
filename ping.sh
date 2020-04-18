#!/usr/bin/bash

ping -c1 www.baidu.com &>/dev/null && echo "baidu is up!" || echo "baidu is down!"

python <<-EOF
print "hello world!"
EOF
