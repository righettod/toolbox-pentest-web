FROM kalilinux/kali-rolling:latest
# Properties
LABEL description="Web Application Pentest customized toolbox based on a KALI image"
LABEL maintainer="dominique.righetto@gmail.com"
# Install system packages
## Always needed
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -y update
RUN apt-get install -y aha autoconf automake bsdmainutils build-essential cewl curl dnsutils ftp-ssl git golang-go highlight iproute2 iputils-ping john jq libauthen-pam-perl libcurl4 libcurl4-openssl-dev libffi-dev libgeoip-dev libgmp3-dev libimage-exiftool-perl libio-pty-perl libmpc-dev libnet-ssleay-perl libsqlite3-dev libssl-dev libtool libxml2-utils libyaml-dev locales nano ncat net-tools nmap nodejs npm openjdk-11-jdk openssl pdfgrep python2-dev perl python3 python3-dev python3-gmpy2 python3-pip python3-pystache python3-wheel python3-yaml rpcbind ruby ruby-dev rustc ssh telnet tmux unicornscan unzip vim wget whois wpscan zlib1g-dev zip zsh
## Remove unwanted packaged installed by default on KALI
RUN apt-get purge -y seclists
## Needed only for specific kind of assessments like internal network assessment
# RUN apt-get update install -y binwalk exploitdb exploitdb-bin-sploits ldap-utils metasploit-framework nfs-common smbclient smbmap
# Create the base folder of all tools
RUN mkdir /tools
# Install utility scripts
COPY scripts /tools/scripts
# Install utility templates
COPY templates /tools/templates
# Install static binaries folder
COPY static-binaries /tools/static-binaries
# Install docs folder
COPY docs /tools/docs
# Install misc folder
COPY misc /tools/misc
# Install dictionaries
COPY dictionaries /tools/dictionaries
# Install tools and extra materials
COPY build /tmp/build
RUN for f in $(ls /tmp/build/*.sh); do chmod +x $f;bash $f; done
# Install dependencies via PIP for tools as well as custom scripts
RUN BUILD_LIB=1 pip3 install ssdeep
RUN for f in $(ls /tools/*/requirements.txt); do pip3 install -r $f; done
RUN tldextract --update
# Misc
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
# Set execute access right
RUN chmod -R +x /tools/
# Build the local favicon DB
RUN mkdir /tools/favicon-db;cd /tools/favicon-db;bash /tools/scripts/generate-favicon-db.sh
# Set final settings of the toolbox
RUN cd /tools/jwt-tool; python3 jwt_tool.py eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJsb2dpbiI6InRpY2FycGkifQ.bsSwqj2c2uI9n7-ajmi3ixVGhPUiY7jO9SUn9dm15Po; echo 0
RUN cd /tools/jwt-tool; python3 jwt_tool.py eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJsb2dpbiI6InRpY2FycGkifQ.bsSwqj2c2uI9n7-ajmi3ixVGhPUiY7jO9SUn9dm15Po; echo 0
RUN /tools/kiterunner/kr scan http://righettod.eu/api -q -A=apiroutes-210328:10 --fail-status-codes 404 --preflight-depth 1
RUN date > /root/image-build-datetime
RUN echo "export PATH=$PATH:/tools/scripts:/root/go/bin:/root/.cargo/bin" >> /root/.zshrc
RUN echo "export NUCLEI_TPL_HOME=/root/nuclei-templates" >> /root/.zshrc
RUN echo "export JWTTOOL_CONFIG_HOME=/root/.jwt_tool" >> /root/.zshrc
RUN echo "alias list-http-scripts-nmap='ls /usr/share/nmap/scripts/http-*'" >> /root/.zshrc
RUN echo "alias list-jwttool-config='cat /root/.jwt_tool/jwtconf.ini'" >> /root/.zshrc
RUN echo "alias check-tls='bash /tools/testssl/testssl.sh -s -p -U --quiet '" >> /root/.zshrc
RUN echo "alias cat_colorized='highlight -O ansi --force'" >> /root/.zshrc
RUN touch /root/.hushlogin
# Setup SSH server for remove access
RUN echo "...:::TOOLBOX:::..." > /etc/motd
RUN rm -rf /etc/ssh/ssh_host_*
RUN dpkg-reconfigure openssh-server
COPY ssh-public-key.pem /root/.ssh/ 
RUN mv /root/.ssh/ssh-public-key.pem /root/.ssh/authorized_keys
RUN chmod -R 700 /root/.ssh;mkdir -p /run/sshd;sshd -t
# Final cleanup and tunning
RUN mkdir -p /root/.config/ookla
COPY speedtest-cli.json /root/.config/ookla/
RUN rm -rf /tmp/*
RUN apt-get -y clean
RUN apt-get -y autoremove
WORKDIR /tools
VOLUME /tools/reports
EXPOSE 80
EXPOSE 443
EXPOSE 22
CMD ["/usr/sbin/sshd","-e","-D"]
