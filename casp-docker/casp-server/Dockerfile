FROM centos:7

# Important! To optimize docker layer size and reuse, try to keep the instructions and
# their order in similar images as much as possible. 

# Install OpenJDK 11. Reduce size by removing unnecessary stuff and optimize image size
RUN curl -O# https://download.oracle.com/java/GA/jdk11/9/GPL/openjdk-11.0.2_linux-x64_bin.tar.gz ;\
    tar zxvf openjdk-11.0.2_linux-x64_bin.tar.gz ;\
    mv jdk-11.0.2 /usr/local/ ; \
    ln -s /usr/local/jdk-11.0.2/bin/java /usr/bin/java ; \
    rm /openjdk-11.0.2_linux-x64_bin.tar.gz; \
    rm /usr/local/jdk-11.0.2/lib/src.zip; 
ENV JAVA_HOME="/usr/local/jdk-11.0.2"
ENV PATH=$PATH:$JAVA_HOME/bin

# Common utilities and clean
RUN echo 'alias ll="ls -l"' >> ~/.bashrc; \
    yum install -y which wget policycoreutils unzip nano initscripts openssl sudo; \
    yum clean all; rm -rf /var/cache/yum;

# NodeJs required for wallets
RUN curl -L# https://rpm.nodesource.com/setup_10.x | bash -; \
    yum install -y nodejs; \
    yum clean all; rm -rf /var/cache/yum

# Apache 
RUN yum -y install httpd httpd-tools mod_ssl;\
    yum clean all; rm -rf /var/cache/yum; \
    systemctl enable httpd;\
    echo "ServerName localhost" >> /etc/httpd/conf/httpd.conf

# Postgres client for psql commands
RUN yum -y install postgresql; \
    yum clean all; rm -rf /var/cache/yum


# Download and install CASP
ARG CASP_SERVER_INSTALLER_URL
RUN echo "Downloading ${CASP_SERVER_INSTALLER_URL}..."; \
    curl -O# "${CASP_SERVER_INSTALLER_URL}"; \
    echo "Installing $(basename ${CASP_SERVER_INSTALLER_URL})"; \
    rpm -i $(basename "${CASP_SERVER_INSTALLER_URL}"); \
    rm $(basename "${CASP_SERVER_INSTALLER_URL}")

COPY data/start_casp.sh /unbound/
RUN chmod +x /unbound/start_casp.sh

COPY data/casp-apache-redirect.conf /etc/httpd/conf.d/

EXPOSE 443

ENTRYPOINT ["/unbound/start_casp.sh", "start"]