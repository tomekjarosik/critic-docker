# OperaCritic
#
# VERSION               0.1.0

FROM      ubuntu:14.04
MAINTAINER Tomasz Jarosik <tomek.jarosik@gmail.com>

LABEL Description="This image is used to start OperaCritic review system based on git repositories. More info: https://github.com/jensl/critic"

# Packages
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install git openssh-server \
    postgresql postgresql-client \
    apache2 libapache2-mod-wsgi \
    python python-passlib python-psycopg2 python-pip python-pygments


# Clean Up packages
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    find /var/log -type f | while read f; do echo -ne '' > $f; done;

# add sample users


# sshd service
RUN mkdir /var/run/sshd
RUN echo 'root:adminpass' | chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
#
# ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile


# CRITIC installation

RUN mkdir /home/devel/
WORKDIR /home/devel
RUN git clone https://github.com/jensl/critic.git

WORKDIR /home/devel/critic

RUN /etc/init.d/postgresql start && \
    python install.py \
    --headless \
    --smtp-host mail \
    --smtp-port 25 \
    --git-dir "/var/git" \
    --system-hostname="mail.tomaszjarosik.net" \
    --system-username="critic" \
    --system-email="critic@mail.tomaszjarosik.net" \
    --skip-testmail \
    --skip-testmail-check \
    --system-groupname="critic" \
    --admin-username="admin" \
    --admin-fullname="Critic Administrator" \
    --admin-password="adminpass" \
    --web-server-integration="apache" \
    --admin-email="admin@critic.tomaszjarosik.net"

# create volume for git repositories
VOLUME /var/git

RUN useradd aaa
RUN useradd bbb
RUN useradd ccc

RUN echo 'aaa:aaapass' | chpasswd
RUN echo 'bbb:bbbpass' | chpasswd
RUN echo 'ccc:cccpass' | chpasswd

RUN usermod -a -G critic aaa
RUN usermod -a -G critic bbb
RUN usermod -a -G critic ccc

CMD /etc/init.d/apache2 restart && \
    /etc/init.d/postgresql restart && \
    /etc/init.d/critic-main restart && \
    /etc/init.d/ssh restart && \
     criticctl adduser --name aaa --email 'aaa@email' --fullname 'aaa test user' --password 'aaapass' && \
     criticctl adduser --name bbb --email 'bbb@email' --fullname 'bbb test user' --password 'bbbpass' && \
     criticctl adduser --name ccc --email 'ccc@email' --fullname 'ccc test user' --password 'cccpass' && \
     tail -f /var/log/critic/main/servicemanager.log

#directory where the Critic system configuration is stored
#parser.add_argument("--install-dir", help="directory where the Critic source code is installed", action="store")
#parser.add_argument("--data-dir", help="directory where Critic's persistent data files are stored", action="store")
#parser.add_argument("--cache-dir", help="directory where Critic's temporary data files are stored", action="store")
#parser.add_argument("--git-dir", help="directory where the main Git repositories are stored", action="store")
#parser.add_argument("--log-dir", help="directory where Critic's log files are stored", action="store")
#parser.add_argument("--run-dir", help="directory where Critic's runtime files are stored", action="store")
#parser.add_argument("--smtp-host", help="SMTP server hostname (or IP)")
#parser.add_argument("--smtp-port", help="SMTP server port")
#parser.add_argument("--smtp-no-auth", action="store_true", help="no SMTP authentication required")
#parser.add_argument("--smtp-username", help="SMTP authentication username")
#parser.add_argument("--smtp-password", help="SMTP authentication password")


# optionally
# RUN apt-get install -y vim
# https://github.com/git/git.git
# Add this to ~/.bashrc:
# source ~/devel/git/contrib/completion/git-prompt.sh
# PS1='[\u@\h \W$(__git_ps1 " (%s)")]\$ '
