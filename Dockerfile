FROM elixir:1.4
MAINTAINER szymon.ciolkowski@gmail.com

#RUN useradd -d /home/docker -m -s /bin/bash docker \
#&& echo "docker:docker" | chpasswd \
#&& adduser docker sudo \
#&& chown -R docker:docker /home/docker \
#&& mkdir -p /home/docker/perseids \

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y locales

RUN sed -i -e 's/# pl_PL.UTF-8 UTF-8/pl_PL.UTF-8 UTF-8/' /etc/locale.gen && \
    echo 'LANG="pl_PL.UTF-8"'>/etc/default/locale && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=pl_PL.UTF-8

ENV LANG pl_PL.UTF-8
ENV TERM xterm

RUN curl -sL https://deb.nodesource.com/setup_6.x | bash - \
&& apt-get install -y -q nodejs inotify-tools inotify-hookable \
&& mix archive.install https://github.com/phoenixframework/archives/raw/master/phoenix_new.ez --force \
&& mix local.hex --force \
&& mix local.rebar --force \
&& mkdir webapps && cd webapps && mkdir perseids && cd .. \
&& chgrp www-data webapps/ -R \
&& chmod g+w webapps/ -R

WORKDIR /webapps/perseids
