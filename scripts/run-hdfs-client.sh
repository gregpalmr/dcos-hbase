#!/bin/bash
#
# SCRIPT: run-hdfs-client.sh

dcos node ssh --master-proxy --leader "docker run -it mesosphere/hdfs-client:1.0.0-2.6.0 bash"

# end of script
