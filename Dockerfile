FROM centos:7

# Install base packages and some python packages
RUN yum install -y epel-release && \
    yum makecache && \
    yum install -y gawk make wget tar bzip2 gzip python unzip perl patch \
    diffutils diffstat git cpp gcc gcc-c++ glibc-devel texinfo chrpath socat \
    perl-Data-Dumper perl-Text-ParseWords perl-Thread-Queue python3-pip xz \
    which SDL-devel xterm file tmux screen libunwind strace bc ncurses-devel && \
    yum clean all && \
    pip3 install GitPython jinja2

# Install additional required dev tools
RUN	yum -y install centos-release-scl && \
	yum -y install devtoolset-7

# Add Yocto User
RUN adduser yocto && \
	echo -en "[user]\n\temail = you@example.com\n\tname = Your Name\n[color]\n\tui = auto\n" > /home/yocto/.gitconfig && \
	chown yocto.yocto /home/yocto/.gitconfig

# Install the official Yocto builtools for Yocto 3.0 Zeus
RUN cd /tmp && \
    wget http://downloads.yoctoproject.org/releases/yocto/yocto-3.0/buildtools/x86_64-buildtools-nativesdk-standalone-3.0.sh && \
    chmod +x x86_64-buildtools-nativesdk-standalone-3.0.sh && \
    ./x86_64-buildtools-nativesdk-standalone-3.0.sh -y && \
	echo ". /opt/poky/3.0/environment-setup-x86_64-pokysdk-linux" >> /home/yocto/.bashrc && \
	echo "export LANG=en_US.UTF-8" >> /home/yocto/.bashrc

# Add the 'repo' tool to the yocto user's $PATH
RUN mkdir /home/yocto/bin && \
	curl http://commondatastorage.googleapis.com/git-repo-downloads/repo  > /home/yocto/bin/repo && \
	chmod a+x /home/yocto/bin/repo && \
	echo "export PATH=\$PATH:/home/yocto/bin" >> /home/yocto/.bashrc

# Enable additional dev tools
COPY enable-scl-devtoolset-7.sh /etc/profile.d

# Entrypoint for automatic build environment setup
COPY docker-entrypoint.sh /usr/local/bin/
RUN ln -s /usr/local/bin/docker-entrypoint.sh / # backwards compat
ENTRYPOINT ["docker-entrypoint.sh"]

USER yocto:yocto
CMD ["bash"]
