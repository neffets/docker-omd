# Open Monitoring Distribution
#
# Forked from https://github.com/fstab/docker-omd and https://github.com/m-kraus/docker-omd
#
FROM ubuntu:26.04
LABEL org.opencontainers.image.authors="software@neffets.de"

# Var for first config
ENV DEBIAN_FRONTEND="noninteractive" \
    SITENAME="sp" \
    OMD_APACHE_TCP_ADDR="0.0.0.0" \
    OMD_APACHE_TCP_PORT="5000" \
    OMD_TMPFS="off" \
    VERSION="5.70"

RUN mkdir -p /omd/sites && ln -sf /omd /opt/omd

RUN  echo 'net.ipv6.conf.default.disable_ipv6 = 1' > /etc/sysctl.d/20-ipv6-disable.conf; \
echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.d/20-ipv6-disable.conf; \
echo 'net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.d/20-ipv6-disable.conf; \
cat /etc/sysctl.d/20-ipv6-disable.conf; sysctl --system

# Make sure package repository is up to date
# ubuntu18.04 libpython2.7 / 20.04 libpython3.8 / 24.04 libpython3.12 / 26.04 libpython3.14
RUN apt-get update -y \
	&& apt-get upgrade -y \
	&& apt-get install -y libpython3.14 libapache2-mod-python \
		python3-setuptools python3-setuptools-git python3-wheel python3-pip \
		net-tools netcat-openbsd wget iputils-ping \
		postfix mutt \
        gnupg2 sudo curl lsb-release \
    && apt-get clean all

# Install OMD, see http://labs.consol.de/OMD/
RUN \
    curl -fsS "https://labs.consol.de/repo/stable/monitoring-repo-consol-de-gpg-2026.asc" -o /etc/apt/trusted.gpg.d/monitoring-repo-consol-de-gpg-2026.asc \
    && echo "deb [signed-by=/etc/apt/trusted.gpg.d/monitoring-repo-consol-de-gpg-2026.asc] http://labs.consol.de/repo/stable/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/labs-consol-stable.list \
    && apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install -y omd \
		monitoring-plugins \
    && apt-get clean all \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
#RUN pip3 install check_docker \
#	&& apt-get clean all

# Fix some stuff in apache: no change ulimit and give the server a name
RUN echo "APACHE_ULIMIT_MAX_FILES=true" >> /etc/apache2/envvars \
	&& echo ServerName docker-omd > /etc/apache2/conf-available/docker-servername.conf \
	&& a2enconf docker-servername \
    && sed -i 's|echo "on"$|echo "off"|' /opt/omd/versions/default/lib/omd/hooks/TMPFS

RUN omd create sp && \
su - sp -c "ssh-keygen -b 2048 -t rsa -N '' -f /omd/sites/sp/.ssh/id_rsa" && \
mv /omd/sites/sp/local /omd/sites/sp/local.docker && \
mv /omd/sites/sp/etc /omd/sites/sp/etc.docker && \
mv /omd/sites/sp/var /omd/sites/sp/var.docker

VOLUME /omd/sites/sp/local
VOLUME /omd/sites/sp/etc
VOLUME /omd/sites/sp/var

# Add watchdog script
COPY entrypoint.sh /entrypoint.sh
RUN chmod a+rx /entrypoint.sh

# Set up runtime options
EXPOSE 5000
ENTRYPOINT ["/entrypoint.sh"]
