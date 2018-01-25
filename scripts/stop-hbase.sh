#!/bin/bash
#
# SCRIPT: stop-hbase.sh
#

if [ "$1" == "cleanup" ]
then
    echo
    echo " Stopping HBase tasks with option \"cleanup\". "
    CLEANUP=true
else
    echo
    echo " Stopping HBase tasks. "
    echo
    echo " NOTE: To cleanup Zookeeper znodes and HDFS directories, use the \"cleanup\" option."
    echo "   e.g.   $ scripts/stop-hbase.sh cleanup "
fi

echo
echo " ### Retrieving core.dcos_url ### "
CORE_DCOS_URL=$(dcos config show core.dcos_url 2>&1)

if [[ $CORE_DCOS_URL == *"http"* ]]
then
    echo "     core.dcos_url found."
else
    echo "     ERROR: core.dcos_url not found. Exiting."
    exit 1
fi

echo
echo " ### Stopping HBase Regionservers "

running_task_count=$(dcos task |grep hbase-regionserver- | awk '{print $4}' | grep R | wc -l)

if [ "$running_task_count" -gt 0 ]
then

    running_task_count=$((running_task_count-1))

    for i in $(eval echo "{0..$running_task_count}")
    do
        echo "     dcos marathon app remove /hbase/hbase-regionserver-${i}"
        dcos marathon app remove /hbase/hbase-regionserver-${i}
    done
fi

echo
echo " ### Stopping HBase Masters "

running_task_count=$(dcos task |grep hbase-master- | awk '{print $4}' | grep R | wc -l)

if [ "$running_task_count" -gt 0 ]
then
    running_task_count=$((running_task_count-1))

    for i in $(eval echo "{0..$running_task_count}")
    do
        echo "     dcos marathon app remove /hbase/hbase-master-${i}"
        dcos marathon app remove /hbase/hbase-master-${i}
    done
fi

echo
echo " ### Stopping HBase Shell Session "

dcos marathon app remove  /hbase/hbase-shell-session

echo
echo " ### Waiting for all tasks to stop "
echo
while true
do
    task_count=$(dcos task | grep -e hbase- | wc -l)

    if [ "$task_count" -eq 0 ]
    then
        # no tasks are running, safe to remove metadata from zk
        break
    else
        printf "."
    fi
    sleep 10
done

# remove hbase marathon applciation group
dcos marathon group remove /hbase

if [ "$CLEANUP" == "true" ]
then
    echo
    echo " ### Removing Metadata in Zookeeper"
    sleep 5
    dcos marathon app add marathon/zookeeper-cleanup-commands.json

    echo 
    echo " ### Removing the /hbase directory in HDFS "
    dcos marathon app add marathon/hdfs-remove-hbase-dir-marathon.json
    sleep 15
    dcos marathon app remove hdfs-remove-hbase-dir
fi

# End of Script
