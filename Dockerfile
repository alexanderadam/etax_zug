FROM ubuntu:20.04

ENV ETAX_YEAR 2019

ENV HOST_GID 1000
ENV HOST_UID 1000
ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-amd64/
ENV ETAX_INSTALLER_SCRIPT eTaxInstaller.sh
ENV ETAX_INSTALL_DIR /home/taxpayer/etax_zug
ENV LOG_LEVEL DEBUG

RUN apt-get update && \
    apt-get install -y --no-install-suggests --no-install-recommends wget curl iputils-ping \
    gnupg2 apt-transport-https libx11-xcb1 ca-certificates \
    ca-certificates-java libgtk-3-0 openjdk-11-jdk ant && \
    apt-get upgrade -y --no-install-suggests --no-install-recommends && \
    update-ca-certificates -f && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/oracle-jdk11-installer

COPY entrypoint.sh /bin/entrypoint.sh

RUN groupadd -r taxpayer --gid $HOST_GID && \
    useradd --no-log-init --create-home --uid $HOST_UID --gid taxpayer taxpayer && \
    mkdir -p $ETAX_INSTALL_DIR && \
    chown -R taxpayer:taxpayer /home/taxpayer
USER "taxpayer"
WORKDIR "/home/taxpayer"

RUN ln -s $ETAX_INSTALL_DIR "/home/taxpayer/eTax.zug_${ETAX_YEAR}_nP" && \
    ln -s $ETAX_INSTALL_DIR /home/taxpayer/eTax.zug

VOLUME /home/taxpayer/etax_zug

ENTRYPOINT ["/bin/bash", "/bin/entrypoint.sh"]
# CMD ["/home/taxpayer/entrypoint.sh"]
