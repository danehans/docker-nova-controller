docker-nova-controller
=============

Docker Image for OpenStack Nova Controller

Overview
--------

Run OpenStack Nova Controller Services in a Docker container.

Introduction
------------

The container does **NOT** include nova-compute. The container only includes Nova Controller services.

This guide assumes you have Docker installed on your host system. Use the [Get Started with Docker Containers in RHEL 7](https://access.redhat.com/articles/881893] to install Docker on RHEL 7) to setup your Docker on your RHEL 7 host if needed. Reference the [Getting images from outside Docker registries](https://access.redhat.com/articles/881893#images) section of the the guide to pull your base rhel7 image from Red Hat's private registry. This is required to build the rhel7-systemd base image used by the nova-controller container.

Make sure your Docker host has been configured with the required [OSP 5 channels and repositories](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux_OpenStack_Platform/5/html/Installation_and_Configuration_Guide/chap-Prerequisites.html#sect-Software_Repository_Configuration)

After following the [Get Started with Docker Containers in RHEL 7](https://access.redhat.com/articles/881893) guide, verify your Docker Registry is running:
```
# systemctl status docker-registry
docker-registry.service - Registry server for Docker
   Loaded: loaded (/usr/lib/systemd/system/docker-registry.service; enabled)
   Active: active (running) since Mon 2014-05-05 13:42:56 EDT; 601ms ago
 Main PID: 21031 (gunicorn)
   CGroup: /system.slice/docker-registry.service
           ├─21031 /usr/bin/python /usr/bin/gunicorn --access-logfile - --debug ...
            ...
```
Now that you have the rhel7 base image, follow the instructions in the [docker-rhel7-systemd project](https://github.com/danehans/docker-rhel7-systemd/blob/master/README.md) to build your rhel7-systemd image.

Although the container does initialize the database used by nova-controller, it does not create the database, permissions, etc.. These are responsibilities of the database service.

The container does not setup nova-controller endpoints for Nova. This is a task the nova-controller service is responsible for.

Installation
------------

From your Docker Registry, set the environment variables used to automate the image building process

Required. Name of the Github repo. Change danehans to your Github repo name if you forked this project. Otherwise set REPO_NAME to danehans.
```
export REPO_NAME=danehans
```
Required. The branch from the REPO_NAME repo. Unless you are using a different branch, set the REPO_BRANCH to master.
```
export REPO_BRANCH=master
```
Optional. Name of the Docker base image in your Docker Registry. This should be the image that includes systemd. Defaults to rhel7-systemd.
```
export BASE_IMAGE=ouruser/rhel7-systemd
```
Optional. Name to use for the nova-controller Docker image. Defaults to nova-controller.
```
export IMAGE_NAME=ouruser/nova-controller
```
Required. IP address/hostname of the Database server.
```
export DB_HOST=10.10.10.200
```
Optional. Password used to connect to the nova-controller database on the DB_HOST server. Defaults to changeme.
```
export DB_PASSWORD=changeme
```
Required. IP address/hostname of the RabbitMQ server.
```
export RABBIT_HOST=10.10.10.200
```
Optional. Username/Password to connect to the RabbitMQ server. Defaults to guest/guest
```
export RABBIT_USER=guest
export RABBIT_PASSWORD=guest
```
Required. IP address/hostname of Keystone. This address should resolve to the IP used by the Host and not the container.
```
export KEYSTONE_HOST=10.10.10.100
```
Optional. TCP Port used by the Keystone Admin API. Defaults to 35357.
```
export KEYSTONE_ADMIN_HOST_PORT=35357
```
Optional. TCP Port used by the Keystone Public API. Defaults to 5000
```
export KEYSTONE_PUBLIC_HOST_PORT=5001
```
Optional. The name and password of the service tenant within the nova-controller service catalog. Defaults to service/changeme
```
export SERVICE_TENANT=services
export SERVICE_PASSWORD=changeme
```
Optional. Credentials used in the nova-controller RC files. Defaults to changeme.
```
export ADMIN_USER_PASSWORD=changeme
export DEMO_USER_PASSWORD=changeme
```
Required. IP address/hostname of API endpoints. Defaults to 127.0.0.1
```
export GLANCE_API_HOST=127.0.0.1
export NOVA_API_HOST=127.0.0.1
export NEUTRON_API_HOST=127.0.0.1
```
Optional. nova-controller Region used for the Neutron server endpoint. Defaults to RegionOne
```
export REGION=RegionOne
```
Optional. Password of the Nuetron service user. Defaults to $SERVICE_PASSWORD
```
export NEUTRON_ADMIN_PASSWORD=changeme
```
Optional. Have Neutron service metadata proxy requests from instances. Boolean, defaults to true.
```
export SERVICE_NEUTRON_METADATA_PROXY=true
```
Optional. Shared secret used between Nettron and Nova to secure metadata communication. Defaults to changeme.
```
export NEUTRON_METADATA_PROXY_SHARED_SECRET=changeme
```
Additional environment variables can be set as needed. You can reference the [build script](https://github.com/danehans/docker-nova-controller/blob/master/data/scripts/build) to review all the available environment variables options and their default settings.

Refer to the OpenStack [Icehouse installation guide](http://docs.openstack.org/icehouse/install-guide/install/yum/content/nova-controller.html) for more details on the .conf configuration parameters.

Run the build script.
```
bash <(curl \-fsS https://raw.githubusercontent.com/$REPO_NAME/docker-nova-controller/$REPO_BRANCH/data/scripts/build)
```
The image should now appear in your image list:
```
# docker images
REPOSITORY       TAG       IMAGE ID            CREATED             VIRTUAL SIZE
nova-controller  latest    d280a0d8e4c5        14 minutes ago      765.9 MB
```
Now you can run a nova-controller container from the newly created image. You can use the run script or run the container manually.

First, set your environment variables:
```
export IMAGE_NAME=ouruser/nova-controller
export NOVA_CONTROLLER_HOSTNAME=nova-controller.example.com
export DNS_SEARCH=example.com
```
Additional environment variables can be set as needed. You can reference the [run script](https://github.com/danehans/docker-nova-controller/blob/master/data/scripts/run) to review all the available environment variables options and their default settings.

**Option 1-** Use the run script:
```
# . $HOME/docker-nova-controller/data/scripts/run
```
**Option 2-** Manually:
Run the nova-controller container. The example below uses the -h flag to configure the hostame as nova-controller within the container, exposes TCP ports 8773-8775, 6080-6081 and 5672 on the Docker host, names the container nova-controller, uses -d to run the container as a daemon.
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
If you manually started the container, access the shell:
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
---------------------

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
