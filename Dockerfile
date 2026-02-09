FROM eclipse-temurin:25-jre

RUN apt-get update && \
    apt-get install -y curl unzip ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create user/group
RUN userdel -r ubuntu 2>/dev/null || true && \
    groupadd -g 1000 hytale && \
    useradd -u 1000 -g 1000 -m -d /home/hytale -s /bin/bash hytale

ENV PUID=1000 \
    PGID=1000 \
    DOWNLOAD_ON_START=true

COPY ./scripts /home/hytale/scripts
COPY ./hytale_downloader /home/hytale/downloader/hytale_downloader

RUN chmod +x /home/hytale/scripts/*.sh && \
    chown -R 1000:1000 /home/hytale

WORKDIR /home/hytale

VOLUME ["/data"]

EXPOSE 5520

ENTRYPOINT ["/home/hytale/scripts/init.sh"]