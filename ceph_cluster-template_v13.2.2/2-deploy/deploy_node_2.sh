#!/bin/bash
hosts=$@
#创建集群信息
pub_net=$(cat /etc/hosts |grep ${hosts[0]} |cut -d ' ' -f 1)
ceph-deploy new ${hosts[*]}
echo "osd pool default size = 2">>ceph.conf
echo "public network = $pub_net/16" >> ceph.conf
cat ceph.conf

#初始化集群信息
ceph-deploy mon create-initial
# ceph-deploy --overwrite-conf mon create-initial
ceph-deploy gatherkeys ${hosts[*]}
for h in $hosts; do
 sh -c "ceph-deploy admin $h"
done 

#修改 ceph.conf 的读权限
for h in $hosts; do
 sh -c "ssh $h sudo chmod -R  a+r /etc/ceph/"
done 

exit 0