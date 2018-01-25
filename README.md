# dcos-hbase
Apache HBase running on DC/OS and Mesos without Docker containers

     *** NOTE: The artifacts in this repo are provided for convenience ***
     *** and are not directly supported by Mesosphere, Inc.            ***

# Quickstart

##Requirements: 
- At least 7 private nodes in your DC/OS cluster.
     - (See: https://docs.mesosphere.com/1.10/installing/ent/custom/system-requirements)
- A running HDFS service (it will be started by the script, if not already running).
     - (See: https://docs.mesosphere.com/services/hdfs/2.0.4-2.6.0-cdh5.11.0) 
- The DC/OS Command Line Interface (CLI) installed, configured and logged in to your cluster.
     - (See: https://docs.mesosphere.com/1.10/cli)

## Steps

## 1. Clone this repository

     $ git clone https://github.com/gregpalmr/dcos-hbase

     $ cd dcos-hbase

## 2. Run the start script with 2 HBase masters and 3 regionservers

     $ scripts/start-hbase.sh 3

## 3. Run the HBase Shell

     $ dcos task exec --interactive --tty hbase_hbase-shell-session bash

       #> source hbase_env.sh

       #> $HBASE_HOME/bin/hbase shell

           hbase(main):001:0> status
           hbase(main):002:0> version
           hbase(main):003:0> create 't1', 'f1', 'f2', 'f3'
           hbase(main):004:0> list

## 4. View the shared HBase directories in HDFS

     $ dcos node ssh --master-proxy --leader "docker run -it mesosphere/hdfs-client:1.0.0-2.6.0 bash"

          #> bin/hadoop fs -ls /hbase

## 5. Shutdown the HBase service

     $ scripts/stop-hbase.sh

     or

     $ scripts/stop-hbase.sh cleanup   # remove the HBase Zookeeper znodes and HBase HDFS dirs too


# Advanced

## Modifying the HBase configuration in hbase-site.xml

TBD

## Bulk loading data into HBase tables

TBD
