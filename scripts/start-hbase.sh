#!/bin/bash
#
# SCRIPT: start-hbase.sh
#

# Check if the number of region servers was specified on the command line
if [ "$1" == "" ]
then
    echo
    echo " Error: Please specify the number of regionservers to launch in this HBase cluster."
    echo 
    echo "        e.g.  $ scripts/start-hbase.sh 3"
    echo
    echo " Exiting."
    exit 1
else
    REQUESTED_REGIONSERVER_COUNT=$1
fi

echo
echo " #################################"
echo " ### Verifying DC/OS CLI Setup ###"
echo " #################################"
echo

# Make sure the DC/OS CLI is available
result=$(which dcos 2>&1)
if [[ "$result" == *"no dcos in"* ]]
then
        echo
        echo " ERROR: The DC/OS CLI program is not installed. Please install it."
        echo " Follow the instructions found here: https://docs.mesosphere.com/1.10/cli/install/"
        echo " Exiting."
        echo
        exit 1
fi

# Get DC/OS Master Node URL
MASTER_URL=$(dcos config show core.dcos_url 2>&1)
if [[ $MASTER_URL != *"http"* ]]
then
        echo
        echo " ERROR: The DC/OS Master Node URL is not set."
        echo " Please set it using the 'dcos cluster setup' command."
        echo " Exiting."
        echo
        exit 1
fi

# Check if the CLI is logged in
result=$(dcos node 2>&1)
if [[ "$result" == *"No cluster is attached"* ]]
then
    echo
    echo " ERROR: No cluster is attached. Please use the 'dcos cluster attach' command "
    echo " or use the 'dcos cluster setup' command."
    echo " Exiting."
    echo
    exit 1
fi
if [[ "$result" == *"Authentication failed"* ]]
then
    echo
    echo " ERROR: Not logged in. Please log into the DC/OS cluster with the "
    echo " command 'dcos auth login'"
    echo " Exiting."
    echo
    exit 1
fi
if [[ "$result" == *"is unreachable"* ]]
then
    echo
    echo " ERROR: The DC/OS master node is not reachable. Is core.dcos_url set correctly?"
    echo " Please set it using the 'dcos cluster setup' command."
    echo " Exiting."
    echo
    exit 1

fi

echo
echo "    DC/OS CLI Setup Correctly "
echo

echo
echo " #################################################"
echo " ###   Checking for at least 7 Private Agents ###"
echo " #################################################"
echo

# Get the number of private agent nodes (total nodes - 1)
PRIV_NODE_COUNT=$(dcos node | grep agent | wc -l)
if [ "$PRIV_NODE_COUNT" == "" ]
then
    echo " ERROR: Number of private agent nodes was not found."
    echo " Exiting."
    echo
    exit 1
fi
PRIV_NODE_COUNT=$((PRIV_NODE_COUNT-1))

if [ "$PRIV_NODE_COUNT" -lt 7 ]
then
    echo " ERROR: Number of private agent nodes must be 7 or more."
    echo "        Only showing $PRIV_NODE_COUNT private agent nodes."
    echo " Exiting."
    echo
    exit 1
fi
echo
echo "    DC/OS Agent Node Count is Sufficient."


###
### Check if the HDFS service is running. It is required.
###

echo
echo " #################################################"
echo " ### Checking if the HDFS service is running.  ###"
echo " #################################################"

# Get the number of data nodes
datanode_count=$(dcos task | grep data-.-node | wc -l)

# Check if all data nodes are "running"
if [ "$datanode_count" -gt 0 ]
then
    last_datanode=$(($datanode_count-1))

    task_status=$(dcos task |grep data-${last_datanode}-node | awk '{print $4}')

    if [ "$task_status" != "R" ]
    then
        printf "."
    else
        echo
        echo " HDFS service is running."
    fi
else

    echo
    echo " ##############################"
    echo " ###      Starting HDFS     ###"
    echo " ##############################"
    echo
    dcos package install --options=marathon/hdfs-package-options.json hdfs --yes

    # Wait for all HDFS data node task to show status of R for running
    echo
    echo " Waiting for HDFS service to start. "

    while true 
    do
        # Get the number of data nodes
        datanode_count=$(dcos task | grep data-.-node | wc -l)

        if [ "$datanode_count" -gt 0 ]
        then
            last_datanode=$(($datanode_count-1))

            task_status=$(dcos task |grep data-${last_datanode}-node | awk '{print $4}')

            if [ "$task_status" != "R" ]
            then
                printf "."
            else
                echo
                echo " HDFS service is running."
                break
            fi
        else
            printf "."
        fi
        sleep 10
    done
fi

echo
echo " #####################################"
echo " ### Starting HBase Masters        ###"
echo " #####################################"
echo

echo " Starting HBase masters"
echo

dcos marathon app add marathon/hbase-master-0-marathon.json

sleep 5

dcos marathon app add marathon/hbase-master-1-marathon.json

echo
echo " Waiting for HBase Masters to start. "

while true 
do
    running_task_count=$(dcos task |grep hbase-master- | awk '{print $4}' | grep R | wc -l)

    if [ "$running_task_count" -ne 2  ]
    then
        printf "."
    else
        echo " HBase Masters are running."
        break
    fi
    sleep 10
done


echo
echo " ###############################################"
echo " ### Starting HBase Regionservers            ###"
echo " ###############################################"
echo

regionserver_count=$((REQUESTED_REGIONSERVER_COUNT-1))
for i in $(eval echo "{0..$regionserver_count}")
do
    sed s/\{\{REGIONSERVER_NUMBER\}\}/$i/g marathon/hbase-regionserver-template-marathon.json > /tmp/hbase-regionserver-${i}-marathon.json

    echo " Starting hbase-regionserver-$i"
    dcos marathon app add /tmp/hbase-regionserver-${i}-marathon.json

    sleep 2
done

echo
echo " Waiting for HBase Regionservers to start. "

while true 
do
    running_task_count=$(dcos task |grep hbase-regionserver | awk '{print $4}' | grep R | wc -l)

    if [ "$running_task_count" -ne $REQUESTED_REGIONSERVER_COUNT ]
    then
        printf "."
    else
        echo " HBase Regionservers are running."
        break
    fi
    sleep 10
done

echo
echo " ###############################################"
echo " ### Starting the HBase Shell Task           ###"
echo " ###############################################"
echo

dcos marathon app add marathon/hbase-shell-marathon.json

echo
echo " ###############################################################################"
echo " ###                                                                         ###"
echo " ### HBase startup is complete.                                              ###"
echo " ###                                                                         ###"
echo " ### You can view the HBase Web Console at:                                  ###"
echo " ###                                                                         ###"
echo " ###   http://<public agent ip>:10010                                        ###"
echo " ###                                                                         ###"
echo " ### You can run hbase shell commands by using the                                     ###"
echo " ### following commands:                                                     ###"
echo " ###                                                                         ###"
echo " ### $ dcos task exec --interactive --tty hbase_hbase-shell-session bash     ###"
echo " ###    #> source hbase_env.sh                                                         ###"
echo " ###    #> $HBASE_HOME/bin/hbase shell                                       ###"
echo " ###        hbase(main):001:0> status                                        ###"
echo " ###        hbase(main):002:0> version                                       ###"
echo " ###        hbase(main):003:0> create 't1', 'f1', 'f2', 'f3'                 ###"
echo " ###        hbase(main):004:0> list                                          ###"
echo " ###                                                                         ###"
echo " ### You can run hdfs filesystem commands by using the                       ###"
echo " ### following commands:                                                     ###"
echo " ###                                                                         ###"
echo " ### $ dcos node ssh --master-proxy --leader \                               ###"
echo " ###       \"docker run -it mesosphere/hdfs-client:1.0.0-2.6.0 bash\"          ###"
echo " ###   #> bin/hadoop fs -ls /hbase                                           ###"
echo " ###                                                                         ###"
echo " ###############################################################################"
echo

# End of Script
