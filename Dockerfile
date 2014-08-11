# Use Ubuntu Trusty as our base
FROM ubuntu:14.04

RUN echo "APT::Get::Assume-Yes true;" >>/etc/apt/apt.conf

# Install sandstorm dependencies
RUN apt-get update

RUN apt-get install pkg-config git subversion build-essential autoconf libtool
RUN apt-get install libcap-dev libseccomp-dev xz-utils clang-3.4
RUN apt-get install nodejs-legacy npm
RUN apt-get install curl strace zip imagemagick
RUN apt-get install default-jre-headless
RUN curl https://install.meteor.com | /bin/sh
RUN npm install -g meteorite jsontool

RUN cd /tmp && git clone https://github.com/kentonv/capnproto.git && cd capnproto/c++ && ./setup-autotools.sh && autoreconf -i && ./configure && make -j4 check && make install

RUN cd /tmp && git clone https://github.com/jedisct1/libsodium.git && cd libsodium && ./autogen.sh && ./configure && make -j4 check && make install

RUN adduser --disabled-password --gecos "" sandstorm
USER sandstorm
ENV HOME /home/sandstorm
ENV USER sandstorm
RUN meteor update

ADD . /opt/src
USER root
RUN chown -R sandstorm /opt/src
USER sandstorm

RUN cd /opt/src && make -j4 XZ_FLAGS='-0' && ./install.sh -d -u sandstorm-*.tar.xz

RUN echo 'SERVER_USER=sandstorm\n\
PORT=6080\n\
MONGO_PORT=6081\n\
BIND_IP=0.0.0.0\n\
BASE_URL=http://localhost:6080\n\
WILDCARD_HOST=*.local.sandstorm.io:6080\n\
ALLOW_DEMO_ACCOUNTS=true\n\
MAIL_URL=\n' > $HOME/sandstorm/sandstorm.conf

RUN echo 'export PATH=$PATH:$HOME/sandstorm' >> $HOME/.bashrc

EXPOSE 6080
# Now you can build the container with `docker build -t sandstorm .` and run the docker container with `docker run -p 6080:6080 -i -t sandstorm /bin/bash -c '$HOME/sandstorm/sandstorm start && sleep infinity'`
