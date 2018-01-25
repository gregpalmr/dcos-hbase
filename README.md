# dcos-hbase
Apache HBase running on DC/OS and Mesos 

     *** NOTE: The artifacts in this repo are provided for convenience ***
     *** and are not directly supported by Mesosphere, Inc.            ***

# Quickstart

## Requirements: 
- At least 7 private agent nodes in your DC/OS cluster and at least 1 public agent node.
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

## 3. View the HBase Web UI via the custom UI Proxy

     a. Get the public IP address of the public agent node on which the 
        hbase-master-ui-proxy service is running

     b. Point your web browser to the Master UI proxy port on the public agent node:

          http://<public agent public ip addr>:16010
        
## 4. Run the HBase Shell

     $ dcos task exec --interactive --tty hbase_hbase-shell-session bash

       #> source hbase_env.sh

       #> $HBASE_HOME/bin/hbase shell

           hbase(main):001:0> status
           hbase(main):002:0> version
           hbase(main):003:0> create 'customers', 'profile_data', 'usage_data'
           hbase(main):004:0> list
           hbase(main):003:0> put 'customers',1,'profile_data:userid','user1'
           hbase(main):003:0> put 'customers', 1 ,'profile_data:full_name','John Doe'
           hbase(main):003:0> put 'customers', 1 ,'usage_data:usage_datetime','2018-01-05T15:12:000'
           hbase(main):003:0> put 'customers', 1 ,'usage_data:module_accessed','shoppping_cart'
           hbase(main):003:0> scan 'customers'

     In the example above, HBase will place the table data in the HDFS filesystem at the location:

          hdfs://hdfs/hbase/data/default/customers

## 4. View the shared HBase directories in HDFS

     $ dcos node ssh --master-proxy --leader "docker run -it mesosphere/hdfs-client:1.0.0-2.6.0 bash"

          #> bin/hadoop fs -ls /hbase

          #> bin/hadoop fs -ls -R hdfs://hdfs/hbase/data/default/customers

## 5. Shutdown the HBase service

     $ scripts/stop-hbase.sh

     or

     $ scripts/stop-hbase.sh cleanup   # remove the HBase Zookeeper znodes and HBase HDFS dirs too


# Advanced

## 1. Modifying the HBase configuration in hbase-site.xml

TBD

## 2. Bulk loading data into HBase tables

TBD


## TODO

     - Get the native-hadoop libraries working

     - Create a customer package and framework using the DC/OS Service SDK


