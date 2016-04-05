FROM ubuntu:12.04

RUN apt-get update -y
RUN apt-get install -y \
        busybox \
        libssl-dev \
        make \
        bison \
        flex \
        patch \
        shunit2 \
        mplayer2 \
        mediainfo \
        ffmpeg \
        gcc-multilib \
        g++-multilib \
        ncurses-dev \
        libwww-perl \
        original-awk \
        p7zip-full \
        mawk \
        gawk


ENV VAGRANT_HOME /home/vagrant

RUN useradd -m -U vagrant
RUN mkdir -p $VAGRANT_HOME/bin
RUN mkdir -p $VAGRANT_HOME/napi_bin
RUN ln -sf /bin/busybox $VAGRANT_HOME/bin/sh

WORKDIR $VAGRANT_HOME

ADD tests/prepare_gcc3.sh $VAGRANT_HOME
RUN chmod +x $VAGRANT_HOME/prepare_gcc3.sh
RUN $VAGRANT_HOME/prepare_gcc3.sh $VAGRANT_HOME
