# Nova-Controller
# VERSION               0.0.1
# Tested on RHEL7 and OSP5 (i.e. Icehouse)

FROM      systemd_rhel7
MAINTAINER Daneyon Hansen "daneyonhansen@gmail.com"

WORKDIR /root

# Uses Cisco Internal Mirror. Follow the OSP 5 Repo documentation if you are using subscription manager.
RUN curl --url http://173.39.232.144/repo/redhat.repo --output /etc/yum.repos.d/redhat.repo
RUN yum -y update; yum clean all

# Required Utilities. Note: Nova API would error and not start without iptables.
RUN yum -y install openssl ntp iptables

# Cinder Client. Note: Nova API would error and not start without python-cinderclient.
RUN yum -y install python-cinderclient

# Nova Controller
RUN yum -y install openstack-nova-api openstack-nova-cert openstack-nova-conductor \
  openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler \
  python-novaclient
RUN mv /etc/nova/nova.conf /etc/nova/nova.conf.save
ADD nova.conf /etc/nova/nova.conf
RUN chown -R nova:nova /var/log/nova
RUN chown nova:nova /etc/nova/nova.conf
RUN systemctl enable openstack-nova-api
RUN systemctl enable openstack-nova-cert
RUN systemctl enable openstack-nova-consoleauth
RUN systemctl enable openstack-nova-conductor
RUN systemctl enable openstack-nova-novncproxy
RUN systemctl enable openstack-nova-scheduler

# Initialize the Nova MySQL DB
RUN nova-manage db sync

# Expose Nova Controller TCP ports
EXPOSE 6080 6081 8773 8774 8775

CMD ["/usr/sbin/init"]
