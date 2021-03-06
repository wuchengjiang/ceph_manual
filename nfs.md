# NFS简介
NFS(Network File System）即网络文件系统。它的主要功能是通过网络让不同主机系统之间可以共享文件或目录。   
NFS与Samba服务类似，但一般Samba服务常用于办公局域网共享，而NFS常用于互联网中小型网站集群架构后端的数据共享。    
NFS客户端将NFS服务端设置好的共享目录挂载到本地某个挂载点，对于客户端来说，共享的资源就相当于在本地的目录下。   
NFS在传输数据时使用的端口是随机选择的，依赖RPC服务来与外部通信，要想正常使用NFS,就必须保证RPC正常。    

# RPC简介   
RPC（Remote Procedure Call Protocol）远程过程调用协议。它是一种通过网络从远程计算机程序上请求服务，而不需要了解底层网络技术的协议。   
在NFS服务端和NFS客户端之间，RPC服务扮演一个中介角色，NFS客户端通过RPC服务得知NFS服务端使用的端口，从而双方可以进行数据通信。      

# 流程     
当NFS服务端启动服务时会随机取用若干端口，并主动向RPC服务注册取用相关端口及功能信息，这样，RPC服务就知道NFS每个端口对应的的NFS功能了，然后RPC服务使用固定的111端口来监听NFS客户端提交的请求，并将正确的NFS端口信息回复给请求的NFS客户端。这样，NFS客户就可以与NFS服务端进行数据传输了。

# 搭建NFS服务器端：
```
安装 nfs 与 rpc 相关软件包：
    yum install nfs-utils rpcbind -y
NFS默认的配置文件是 /etc/exports ,配置格式为：  
        NFS共享目录绝对路径    NFS客户端地址（参数）

常用参数：
    rw             read-write   读写
    ro             read-only    只读
    sync           请求或写入数据时，数据同步写入到NFS server的硬盘后才返回。数据安全，但性能降低了
    async          优先将数据保存到内存，硬盘有空档时再写入硬盘，效率更高，但可能造成数据丢失。
    root_squash    当NFS 客户端使用root 用户访问时，映射为NFS 服务端的匿名用户
    no_root_squash 当NFS 客户端使用root 用户访问时，映射为NFS 服务端的root 用户
    all_squash     不论NFS 客户端使用任何帐户，均映射为NFS 服务端的匿名用户

配置 /etc/exports：
    /sharedir 192.168.239.0/24(rw,sync,root_squash)
    
创建共享目录以及测试文件：
    mkdir -p /sharedir
    touch /sharedir/Welcom.file
    echo "Welcome to onlylink.top" >/sharedir/Welcom.file
给共享目录添加权限：
    chown -R nfsnobody.nfsnobody /sharedir/
把NFS共享目录赋予 NFS默认用户nfsnobody用户和用户组权限，如不设置，会导致NFS客户端无法在挂载好的共享目录中写入数据

启动 rpc服务并设置成开机自启动：
    /etc/init.d/rpcbind start
    chkconfig rpcbind on
启动 nfs服务并设置成开机自启动：
    /etc/init.d/nfs start
    chkconfig nfs on
```

# 客户端   

```
安装nfs 与 rpc 相关软件包：
    yum install nfs-utils rpcbind -y
启动 rpc服务并设置成开机自启动（不需要启动 NFS服务）：
    /etc/init.d/rpcbind start
    chkconfig rpcbind on

查询远程NFS 服务端中可用的共享资源：
    showmount -e 192.168.239.131
如果报如下的错误多数是防火墙导致：
    lnt_create: RPC: Port mapper failure - Unable to receive: errno 113 (No route to host)
到服务端清空 iptables默认规则 或关闭 iptables：
    iptables -F    或    service iptables stop

再次查询：
[root@test ~]# showmount -e 192.168.239.131
Export list for 192.168.239.131:
/sharedir 192.168.239.0/24

创建挂载目录，并挂载 NFS共享目录 /sharedir
    mkdir -p /sharedir
    mount -t nfs 192.168.239.131:/sharedir/ /sharedir/
如果想要开机自动将共享目录挂载到本地,往/etc/fstab 中追加：
    192.168.239.131:/sharedir/ /sharedir/ nfs defaults 0 0

验证是否有 rw 权限：
    [root@test ~]# cat /sharedir/Welcom.file 
    Welcome to onlylink.top                
    [root@test ~]# mkdir -p /sharedir/hello
    [root@test ~]# echo "Hello" >> /sharedir/Welcom.file 
    [root@test ~]# cat /share/Welcom.file
    Welcome to onlylink.top
    Hello
```

NFS服务可以让不同的客户端挂载使用同一个共享目录，将其作为共享存储使用，这样可以保证不同节点端数据一致性，在集群中经常会用到，如是Windows与Linux的混合集群,就用Samba实现。如果在大型网站可能会用到Moosefs，GlusterFS,FastDFS来代替NFS。

# 参考
1. 搭建 NFS 网络文件共享服务 . https://www.jianshu.com/p/380afd870d50
=======

生产环境：

服务端：

	1.两个主要的程序：portmap、nfs-utils

	2.网络访问正常，假设IP地址192.168.1.98/24

客户端：

	1.主要的程序：portmap

	2.网络访问正常，假设IP地址192.168.1.99/24



配置过程：

服务端：

1.检查portmap和nfs-utils是否安装
```
rmp -aq portmap nfs-utils
```
2.首先启动portmap服务，然后启动nfs服务 ，一般情况下设置开机自动启动
```
/etc/rc.d/init.d/portmap start  (or:service portmap start)

/etc/rc.d/init.d/nfs start   (or:service nfs start)

chkconfig portmap on

chkconfig nfs on
```
3.建立共享文件目录/tmp/serverdir，修改满足最大需求的最小权限
```
mkdir -p /tmp/serverdir
```
4.nfs配置文件/etc/exports，设定满足最大需求的最小权限
```
vi /etc/exports
```
添加一段内容：

格式：共享目录绝对路径 共享给那些主机(设定的权限)

eg：将/tmp/serverdir共享给192.168.1.0/24这个网段的主机可读写、同步写到磁盘、默认的匿名访问
```
/tmp/serverdir 192.168.1.0/24(rm,sync)
```
5.让配置文件/etc/exports生效方法：
```
方法1.exportfs -rv (推荐使用)

方法2./etc/rc.d/init.d/nfs reload   (or:service nfs reload) (推荐使用)

方法3./etc/rc.d/init.d/nfs restart   (or:service nfs restart) (不推荐使用)

```

客户端：

1.检查portmap是否安装
```
rmp -aq portmap 
```
2.启动portmap服务，一般情况下设置开机自动启动
```
/etc/rc.d/init.d/portmap start  (or:service portmap start)

chkconfig portmap on
```
3.建立挂载目录/tmp/clientdir，修改满足最大需求的最小权限
```
mkdir -p /tmp/clientdir
```
4.使用/usr/bin/showmount -e 服务器的IP地址，查看服务器机导出的所有远程目录的列表
```
/usr/bin/showmount -e 192.168.1.98
```
5.使用/bin/mount挂载服务器共享的目录到本地/tmp/clientdir目录
```
/bin/mount -t nfs 192.168.1.98:/tmp/serverdir /tmp/clientdir
```
6.挂载后情况使用命令dh -h查看挂载的情况
```
df -h
```


NFS文件系统的优缺点：
```
	优点：
	1.简单：配置简单，容易上手掌握
	2.方便：部署非常快速，维护简单
	3.可靠：在软件层面上看，数据比较可靠，经久耐用
```
缺点：
```
	a.容易发生单点故障，及server机宕机了所有客户端都不能访问
	b.在高并发下NFS效率/性能有限
	c.客户端没用用户认证机制，且数据是通过明文传送，安全性一般（一般建议在局域网内使用）
	d.NFS的数据是明文的，对数据完整性不做验证
	e.多台机器挂载NFS服务器时，连接管理维护麻烦
```
 参考
http://blog.51cto.com/crazyday/1705176
