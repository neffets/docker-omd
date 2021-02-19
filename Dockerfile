# Open Monitoring Distribution
#
# Forked from https://github.com/fstab/docker-omd
#
FROM ubuntu:18.04
MAINTAINER Steffen Schüssler, software@neffets.de

# Var for first config
ENV DEBIAN_FRONTEND="noninteractive" \
    SITENAME="monitor" \
    OMD_APACHE_TCP_ADDR="0.0.0.0" \
    OMD_APACHE_TCP_PORT="5000" \
    OMD_TMPFS="off" \
    VERSION="4.00"

RUN mkdir -p /opt/omd && ln -sf /opt/omd /omd

# Make sure package repository is up to date
# ubuntu18.04 libpython2.7 / ubuntu20.04 libpython3.8 \
RUN apt-get update \
	&& apt-get upgrade -y \
	&& apt-get install -y libpython2.7 \
		python3-setuptools python3-setuptools-git python3-wheel python3-pip \
		net-tools netcat wget iputils-ping \
		postfix mutt \
        gpg sudo curl lsb-release \
    && apt-get clean all

# Install OMD, see http://labs.consol.de/OMD/
RUN curl -s "https://labs.consol.de/repo/stable/RPM-GPG-KEY" | sudo apt-key add - \
	&& echo "deb http://labs.consol.de/repo/stable/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/labs-consol-stable.list \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y omd \
		check-mk-agent \
    && apt-get clean all
#RUN pip3 install check_docker \
#	&& apt-get clean all

# Fix some stuff in apache: no change ulimit and give the server a name
RUN echo "APACHE_ULIMIT_MAX_FILES=true" >> /etc/apache2/envvars \
	&& echo ServerName docker-omd > /etc/apache2/conf-available/docker-servername.conf \
	&& a2enconf docker-servername

VOLUME /opt/omd/sites

# Add watchdog script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod a+rx /usr/local/bin/entrypoint.sh

# Set up runtime options
EXPOSE 5000
ENTRYPOINT ["entrypoint.sh"]
