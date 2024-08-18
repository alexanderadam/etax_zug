FROM ubuntu:22.04

ARG HOST_GID=1000
ARG HOST_UID=1000

ENV ETAX_YEAR 2023
ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-amd64/
ENV ETAX_INSTALLER_SCRIPT eTaxInstaller.sh
ENV ETAX_INSTALL_DIR /home/taxpayer/etax_zug
ENV LOG_LEVEL DEBUG
ENV GDK_SCALE 2
ENV TIME_ZONE Zurich

RUN apt-get update && \
    apt-get install -y --no-install-suggests --no-install-recommends wget curl iputils-ping \
    gnupg2 apt-transport-https libx11-xcb1 ca-certificates expect \
    ca-certificates-java libgtk-3-0 openjdk-11-jdk ant locales \
    libwayland-client0 libwayland-cursor0 libwayland-egl1 libwayland-server0 sudo && \
    apt-get upgrade -y --no-install-suggests --no-install-recommends && \
    update-ca-certificates -f && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/oracle-jdk11-installer && \
    locale-gen de_CH.UTF-8 && \
    update-locale LANG=de_CH.UTF-8

RUN echo '127.0.0.1 etax-zug' >> /etc/hosts

COPY entrypoint.sh /bin/entrypoint.sh

RUN groupadd -r taxpayer --gid $HOST_GID && \
    useradd --no-log-init --create-home --uid $HOST_UID --gid taxpayer taxpayer && \
    mkdir -p $ETAX_INSTALL_DIR && \
    chown -R taxpayer:taxpayer /home/taxpayer && \
    echo "taxpayer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/taxpayer && \
    chmod 0440 /etc/sudoers.d/taxpayer

RUN echo "alias taxpayer='su - taxpayer'" >> /root/.bashrc

RUN echo "alias taxpayer='echo You are already that user 😉'" >> /home/taxpayer/.bashrc

WORKDIR "/home/taxpayer"

RUN echo "Xft.dpi: 140" > /home/taxpayer/.Xresources && \
    ln -s $ETAX_INSTALL_DIR "/home/taxpayer/eTax.zug_${ETAX_YEAR}_nP" && \
    ln -s $ETAX_INSTALL_DIR /home/taxpayer/eTax.zug && \
    chown taxpayer:taxpayer /home/taxpayer/.Xresources && \
    chown -h taxpayer:taxpayer "/home/taxpayer/eTax.zug_${ETAX_YEAR}_nP" && \
    chown -h taxpayer:taxpayer /home/taxpayer/eTax.zug

VOLUME /home/taxpayer/etax_zug

ENTRYPOINT ["/bin/bash", "/bin/entrypoint.sh"]
