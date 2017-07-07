#!/bin/bash

setup_content=~/bin/qcd
history_dir=$setup_content/history_dir

mkdir -p /tmp/qcd
touch /tmp/qcd/qcd_tmp
$setup_content/qcde.sh $@
[ ! "`cat /tmp/qcd/qcd_tmp`" ] || cd "`cat /tmp/qcd/qcd_tmp`"
rm /tmp/qcd/qcd_tmp
