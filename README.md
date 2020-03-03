docker-omd
==========

[Dockerfile](https://www.docker.com) for [Open Monitoring Distribution (OMD)](http://omdistro.org).

Run from Docker Hub
-------------------

A pre-built image is available on [Docker Hub](https://registry.hub.docker.com/u/neffets/omd) and can be run as follows:

    docker run -t -i neffets/omd

This will internally monitor the omd status and if fails then stop the container, so that "docker stack" can restart it.

OMD will become available on [http://172.X.X.X/default](http://172.X.X.X/default).
The default login is `omdadmin` with password `omd`.
To find out the IP address, run `ip addr` in the container shell.

Environment Variables
---------------------

    SITENAME = set your own sitename (default: "monitor")
    OMD_*    = set omd config settings via environment

e.g. -e SITENAME=monitor -e OMD_APACHE_TCP_ADDR="0.0.0.0" -e OMD_TMPFS="off"

Default is TMPFS=off, because tmpfs would require escalated privileges from docker,
if You want it, you have to use docker with parameter --privileged

Volumes
-------

You can overlay-mount the /opt/omd/sites directory to preserve your site configs

    docker run -d -n monitor -e SITENAME=monitor -v /volumes/omd:/opt/omd/sites neffets/omd

Build from Source
-----------------

The Docker image can be built as follows:

    git clone https://github.com/neffets/docker-omd
    cd docker-omd
    docker build -t="neffets/omd" .

Last changed: 2020-03-04
