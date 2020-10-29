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

### Don't change or add above this unless necessery to keep docker layer optimization and reuse

#Install CASP BOT
ARG CASP_SDK_URL
RUN echo "Downloading ${CASP_SDK_URL}..."; \
    curl -O# "${CASP_SDK_URL}"; \
    echo "Installing $(basename ${CASP_SDK_URL})"; \
    mkdir /bot; \
    tar -xf $(basename "${CASP_SDK_URL}") -C /bot; \
    rm $(basename "${CASP_SDK_URL}"); \
    mkdir /bot-ks

COPY data/start_bot.sh /
RUN chmod +x /start_bot.sh
EXPOSE 80
ENTRYPOINT ["/start_bot.sh"]
CMD [ "start" ]

