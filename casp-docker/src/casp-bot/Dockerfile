FROM centos:7

# Maintener
LABEL maintainer "Unbound Security"


RUN yum -y update;\
    yum -y install which ;\
    yum -y install wget ;\
    yum -y install sudo ;\
    yum -y install nano;\
    yum clean all;


#OpenJDK Java 11
RUN curl -sO https://download.oracle.com/java/GA/jdk11/9/GPL/openjdk-11.0.2_linux-x64_bin.tar.gz ;\
    tar zxvf openjdk-11.0.2_linux-x64_bin.tar.gz ;\
    mv jdk-11.0.2 /usr/local/
RUN ln -s /usr/local/jdk-11.0.2/bin/java /usr/bin/java
RUN rm /openjdk-11.0.2_linux-x64_bin.tar.gz

ENV JAVA_HOME=/usr/local/jdk-11.0.2
ENV PATH=$PATH:$JAVA_HOME/bin

RUN java -version

#Install CASP BOT
COPY data/casp-sdk-package.*.tar.gz /casp-sdk-package.tar.gz
RUN mkdir /bot
RUN tar -xf /casp-sdk-package.tar.gz -C /bot

COPY data/start.sh /
RUN chmod +x /start.sh
EXPOSE 80
ENTRYPOINT ["/start.sh"]
CMD [ "start" ]
