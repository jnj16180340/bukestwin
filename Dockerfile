# Buke's Twin deployment image
# Can sample RNN, but can't train it.

# this is basically copied from tiangolo/uwsgi-nginx
# except from python3.4
# and some additional stuff, e.g. redis rq torch-rnn etc

FROM python:3.4

MAINTAINER nobody important <root@goatse.cx>
#############################################################################
# Install uWSGI
RUN pip3 install uwsgi

##############################################################################
# Standard set up Nginx
ENV NGINX_VERSION 1.9.11-1~jessie

RUN apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62 \
	&& echo "deb http://nginx.org/packages/mainline/debian/ jessie nginx" >> /etc/apt/sources.list \
	&& apt-get update \
	&& apt-get install -y ca-certificates nginx=${NGINX_VERSION} gettext-base \
	&& rm -rf /var/lib/apt/lists/*
# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log
EXPOSE 80 443
# Finished setting up Nginx

# Make NGINX run on the foreground
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
# Remove default configuration from Nginx
RUN rm /etc/nginx/conf.d/default.conf

##############################################################################
# Install Redis.
#RUN \
#  cd /tmp && \
#  wget http://download.redis.io/redis-stable.tar.gz && \
#  tar xvzf redis-stable.tar.gz && \
#  cd redis-stable && \
#  make && \
#  make install && \
#  cp -f src/redis-sentinel /usr/local/bin && \
#  mkdir -p /etc/redis && \
#  cp -f *.conf /etc/redis && \
#  rm -rf /tmp/redis-stable* && \
#  sed -i 's/^\(bind .*\)$/# \1/' /etc/redis/redis.conf && \
#  sed -i 's/^\(daemonize .*\)$/# \1/' /etc/redis/redis.conf && \
#  sed -i 's/^\(dir .*\)$/# \1\ndir \/data/' /etc/redis/redis.conf && \
#  sed -i 's/^\(logfile .*\)$/# \1/' /etc/redis/redis.conf

# Hopefully this works?
RUN apt-get update && apt-get install -y redis-server

# Expose Redis port, this may not be necessary for intra-container communication
EXPOSE 6379:6379
###############################################################################

# Install Supervisord
RUN apt-get update && apt-get install -y supervisor \
&& rm -rf /var/lib/apt/lists/*
# Custom Supervisord config

###############################################################################
# Install flask and other python dependencies of the flask app
RUN pip3 install flask
RUN pip3 install flask-wtf itsdangerous flask-bootstrap simplejson
RUN pip3 install rq rq-dashboard
#Jinja2==2.8
#MarkupSafe==0.23
#WTForms==2.1
#Werkzeug==0.11.4
#arrow==0.7.0
#click==6.3
#coverage==4.0.3
#dominate==2.1.17
#flipflop==1.0
#itsdangerous==0.24
#python-dateutil==2.5.1
#redis==2.10.5
#rq==0.5.6
#rq-dashboard==0.3.6
#simplejson==3.8.2
#six==1.10.0
#visitor==0.1.2

###############################################################################
# Install torch-rnn and all that stuff
# don't bother with the preprocessing script (+py2.7 venv) because we don't need to train

###############################################################################
###############################################################################
# CUDA
# is NOT happening right now.
###############################################################################
# torch-rnn and lua stuff
RUN apt-get update && apt-get install -y luarocks
RUN git clone https://github.com/torch/distro.git /root/torch --recursive
# fake /etc/lsb-release file because torch installer doesn't like debian
# this should be changed!
RUN echo -e 'DISTRIB_ID=Ubuntu\nDISTRIB_RELEASE=14.04\nDISTRIB_CODENAME=trusty\nDISTRIB_DESCRIPTION="Ubuntu 14.04.4 LTS"' > /etc/lsb-release
RUN echo -e 'NAME="Ubuntu"\nVERSION="14.04.4 LTS, Trusty Tahr"\nID=ubuntu\nID_LIKE=debian\nPRETTY_NAME="Ubuntu 14.04.4 LTS"\nVERSION_ID="14.04"\nHOME_URL="http://www.ubuntu.com/"\nSUPPORT_URL="http://help.ubuntu.com/"\nBUG_REPORT_URL="http://bugs.launchpad.net/ubuntu/"' > /etc/os-release
RUN apt-get install -y python-software-properties software-properties-common
# fake sudo command to make the installer happy
RUN echo -e '#!/bin/bash\n"$@"' > /usr/local/bin/sudo
RUN chmod +x /usr/local/bin/sudo
# install add-apt-repository to make the installer happy
RUN apt-get update
# the requirements are really unnecessary, maybe should not use the installer
# it's installing qt4 and all this other shit
WORKDIR /root/torch
RUN cat /etc/lsb-release
RUN cat /etc/os-release
RUN lsb_release -a
#RUN apt-get remove -y lsb-release
#RUN apt-get install -y software-properties-common python-software-properties
# Normally echo needs -e to insert newlines. BUT in Docker build more, -e inserts itself into the output and echo works fine without -e
RUN echo 'DISTRIB_ID=Ubuntu\nDISTRIB_RELEASE=14.04\nDISTRIB_CODENAME=trusty\nDISTRIB_DESCRIPTION="Ubuntu 14.04.4 LTS"' > /etc/lsb-release
RUN echo 'NAME="Ubuntu"\nVERSION="14.04.4 LTS, Trusty Tahr"\nID=ubuntu\nID_LIKE=debian\nPRETTY_NAME="Ubuntu 14.04.4 LTS"\nVERSION_ID="14.04"\nHOME_URL="http://www.ubuntu.com/"\nSUPPORT_URL="http://help.ubuntu.com/"\nBUG_REPORT_URL="http://bugs.launchpad.net/ubuntu/"' > /etc/os-release

#RUN echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
#RUN cat /etc/lsb-release
#RUN cat /etc/os-release
#RUN echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

RUN bash install-deps
RUN ./install.sh -b
#RUN source /root/.bashrc
# equivalent of source .bashrc
RUN bash -c 'source /root/.bashrc'
#this stuff might be unnecessary
RUN /root/torch/install/bin/luarocks config --rock-trees
RUN /root/torch/install/bin/luarocks install torch
RUN /root/torch/install/bin/luarocks install nn
RUN /root/torch/install/bin/luarocks install optim
RUN /root/torch/install/bin/luarocks install lua-cjson
RUN /root/torch/install/bin/luarocks install lua-cjson # doubled because the first time it sometimes removes itself
RUN apt-get install -y libhdf5-dev #libhdf5-serial-dev hdf5-tools
RUN git clone https://github.com/deepmind/torch-hdf5
WORKDIR torch-hdf5
RUN /root/torch/install/bin/luarocks make hdf5-0-0.rockspec
WORKDIR /root/
#no CUDA support for now
# RUN luarocks install cutorch
# RUN luarocks install cunn
# this will make ~/torch-rnn. No further building necessary(?)
RUN git clone https://github.com/jcjohnson/torch-rnn

###############################################################################
# Copy config files and the webapp.
# All at the end, so rebuilding image w/ modified config files doesn't rebuild deps
# TODO: Split into separate containers+networking
# Copy trained models
COPY checkpoints/* /root/cv_0/
# Copy nginx config file
COPY nginx.conf /etc/nginx/conf.d/
# Copy supervisord config file
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
# Copy the Flask app
# NB this can't be above the build path! so ./bukestwin is a symlink to ../Buke/Website/bukestwin
COPY ./bukestwin /bukestwin
###############################################################################
# for debugging
RUN apt-get install -y nano
# do ENV instead of RUN export ...
ENV TERM=xterm

# working directory
WORKDIR /bukestwin

CMD ["/usr/bin/supervisord"]

