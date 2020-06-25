FROM centos:7
RUN yum install -y epel-release && \
    yum makecache && \
    yum install -y gawk make wget tar bzip2 gzip python unzip perl patch \
    diffutils diffstat git cpp gcc gcc-c++ glibc-devel texinfo chrpath socat \
    perl-Data-Dumper perl-Text-ParseWords perl-Thread-Queue python3-pip xz \
    which SDL-devel xterm file tmux screen libunwind strace && \
    pip3 install GitPython jinja2 bc && \
    yum clean all && \
    adduser yocto && \
    cd /tmp && \
    wget http://downloads.yoctoproject.org/releases/yocto/yocto-3.1/buildtools/x86_64-buildtools-nativesdk-standalone-3.1.sh && \
    chmod +x x86_64-buildtools-nativesdk-standalone-3.1.sh && \
    ./x86_64-buildtools-nativesdk-standalone-3.1.sh -y
RUN echo ". /opt/poky/3.1/environment-setup-x86_64-pokysdk-linux" >> /home/yocto/.bashrc && \
	echo "export LANG=en_US.UTF-8" >> /home/yocto/.bashrc
RUN	yum -y install centos-release-scl && \
	yum -y install devtoolset-7
RUN mkdir /home/yocto/bin && \
	curl http://commondatastorage.googleapis.com/git-repo-downloads/repo  > /home/yocto/bin/repo && \
	chmod a+x /home/yocto/bin/repo && \
	echo "export PATH=\$PATH:/home/yocto/bin" >> /home/yocto/.bashrc
RUN echo -en "[user]\n\temail = you@example.com\n\tname = Your Name\n[color]\n\tui = auto\n" > /home/yocto/.gitconfig && \
	chown yocto.yocto /home/yocto/.gitconfig
COPY enable-scl-devtoolset-7.sh /etc/profile.d

# TODO: create ~/.gitconfig
# [user]
#	email = you@example.com
#	name = Your Name

#COPY docker-entrypoint.sh /usr/local/bin/
#RUN ln -s /usr/local/bin/docker-entrypoint.sh / # backwards compat
#ENTRYPOINT ["docker-entrypoint.sh"]
USER yocto:yocto
CMD ["bash"]
