docker-nova-controller
=============

Docker Image for OpenStack Nova Controller

Overview
--------

Run OpenStack Nova Controller Services in a Docker container.


Caveats
-------

The container does **NOT** include nova-compute. The container only includes Nova Controller services.

The systemd_rhel7 base image used by the Nova container is a private image.
Use the [Get Started with Docker Containers in RHEL 7](https://access.redhat.com/articles/881893)
to create your base rhel7 image. Then enable systemd within the rhel7 base image.
Use [Running SystemD within a Docker Container](http://rhatdan.wordpress.com/2014/04/30/running-systemd-within-a-docker-container/) to enable SystemD.

The container does not setup Keystone endpoints for Nova. This is a task the Keystone service is responsible for.

Although the container does initialize the database used by Nova, it does not create the database, permissions, etc.. These are responsibilities of the database service.

The container does not include any OpenStack clients. After the Nova container is running, issue Nova commands from a host running the python-novaclient.

Installation
------------

This guide assumes you have Docker installed on your host system. Use the [Get Started with Docker Containers in RHEL 7](https://access.redhat.com/articles/881893] to install Docker on RHEL 7) to setup your Docker on your RHEL 7 host if needed.

### From Github

Clone the Github repo and change to the project directory:
```
yum install -y git
git clone https://github.com/danehans/docker-nova-controller.git
cd docker-nova-controller
```
Edit the nova.conf file according to your deployment needs then build the Nova image. Refer to the OpenStack [Icehouse installation guide](http://docs.openstack.org/icehouse/install-guide/install/yum/content/nova-controller.html) for details. Next, build your Docker Nova Controller image.
```
# docker build -t nova-controller .
```
The image should now appear in your image list:
```
# docker images
REPOSITORY       TAG       IMAGE ID            CREATED             VIRTUAL SIZE
nova-controller  latest    d280a0d8e4c5        14 minutes ago      765.9 MB
```
Run the Nova container. The example below uses the -h flag to configure the hostame as nova-controller within the container, exposes TCP ports 6080-6081 and 8773-8775 on the Docker host, names the container nova-controller, uses -d to run the container as a daemon.
```
# docker run --privileged -d -h nova-controller -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
-p 8773:8773 -p 8774:8774 -p 8775:8775 -p 6080:6080 -p 6081:6081 -p 5672:5672 \
--name="nova-controller" nova-controller
```
**Note:** SystemD requires CAP_SYS_ADMIN capability and access to the cgroup file system within a container. Therefore, --privileged and -v /sys/fs/cgroup:/sys/fs/cgroup:ro are required flags.

Verification
------------

Verify your Nova Controller container is running:
```
# docker ps
CONTAINER ID        IMAGE                    COMMAND             CREATED             STATUS              PORTS                                                                                                                    NAMES
5d1b7163e67f        nova-controller:latest   /usr/sbin/init      5 minutes ago       Up 5 minutes        0.0.0.0:6080->6080/tcp, 0.0.0.0:6081->6081/tcp, 0.0.0.0:8773->8773/tcp, 0.0.0.0:8774->8774/tcp, 0.0.0.0:8775->8775/tcp   nova-controller
```
Access the shell from your container:
```
# docker inspect --format='{{.State.Pid}}' nova-controller
```
The command above will provide a process ID of the Nova container that is used in the following command:
```
# nsenter -m -u -n -i -p -t <PROCESS_ID> /bin/bash
bash-4.2#
```
From here you can perform limited functions such as viewing the installed RPMs, Nova services, the nova.conf file, etc..

Spawn a Nova Instance
--------------------

Since the container does not include the nova-compute service, you will need an existing nova-compute host or use the [official OpenStack documentation](http://docs.openstack.org/icehouse/install-guide/install/yum/content/nova-compute.html) to deploy a nova-compute host.

After the nova-compute host is deployed, use these steps [here](http://docwiki.cisco.com/wiki/OpenStack_Havana_Release:_High-Availability_Manual_Deployment_Guide#Configuring_OpenStack_Networking_.28Neutron.29_and_Deploying_the_First_VM) to continue validating Nova functionality.

Troubleshooting
---------------

Can you connect to the OpenStack API endpints from your Docker host and container? Verify connectivity with tools such as ping and curl.

IPtables may be blocking you. Check IPtables rules on the host(s) running the other OpenStack services:
```
# iptables -L
```
To change iptables rules:
```
# vi /etc/sysconfig/iptables
# systemctl restart iptables.service
```
