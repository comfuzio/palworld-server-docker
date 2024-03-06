FROM golang:1.22.0-alpine as rcon-cli_builder

ARG RCON_VERSION="0.10.3"
ARG RCON_TGZ_SHA1SUM=33ee8077e66bea6ee097db4d9c923b5ed390d583

WORKDIR /build

# install rcon
SHELL ["/bin/ash", "-o", "pipefail", "-c"]

ENV CGO_ENABLED=0
RUN wget -q https://github.com/gorcon/rcon-cli/archive/refs/tags/v${RCON_VERSION}.tar.gz -O rcon.tar.gz \
    && echo "${RCON_TGZ_SHA1SUM}" rcon.tar.gz | sha1sum -c - \
    && tar -xzvf rcon.tar.gz \
    && rm rcon.tar.gz \
    && mv rcon-cli-${RCON_VERSION}/* ./ \
    && rm -rf rcon-cli-${RCON_VERSION} \
    && go build -v ./cmd/gorcon

FROM cm2network/steamcmd:root as base-amd64
# Ignoring --platform=arm64 as this is required for the multi-arch build to continue to work on amd64 hosts
# hadolint ignore=DL3029
FROM --platform=arm64 sonroyaalmerol/steamcmd-arm64:root-2024-02-29 as base-arm64

ARG TARGETARCH
# Ignoring the lack of a tag here because the tag is defined in the above FROM lines
# and hadolint isn't aware of those.
# hadolint ignore=DL3006
FROM base-${TARGETARCH}

LABEL maintainer="thijs@loef.dev" \
      name="thijsvanloef/palworld-server-docker" \
      github="https://github.com/thijsvanloef/palworld-server-docker" \
      dockerhub="https://hub.docker.com/r/thijsvanloef/palworld-server-docker" \
      org.opencontainers.image.authors="Thijs van Loef" \
      org.opencontainers.image.source="https://github.com/thijsvanloef/palworld-server-docker"

# set envs
# SUPERCRONIC: Latest releases available at https://github.com/aptible/supercronic/releases
# RCON: Latest releases available at https://github.com/gorcon/rcon-cli/releases
# NOTICE: edit RCON_MD5SUM SUPERCRONIC_SHA1SUM when using binaries of another version or arch.
ARG SUPERCRONIC_SHA1SUM_ARM64="512f6736450c56555e01b363144c3c9d23abed4c"
ARG SUPERCRONIC_SHA1SUM_AMD64="cd48d45c4b10f3f0bfdd3a57d054cd05ac96812b"
ARG SUPERCRONIC_VERSION="0.2.29"

# update and install dependencies
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
    procps=2:4.0.2-3 \
    wget \ 
    gettext-base=0.21-12 \
    xdg-user-dirs=0.18-1 \
    jo=1.9-1 \
    netcat-traditional=1.10-47 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# install rcon and supercronic
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY --from=rcon-cli_builder /build/gorcon /usr/bin/rcon-cli

ARG TARGETARCH
RUN case ${TARGETARCH} in \
        "amd64") SUPERCRONIC_SHA1SUM=${SUPERCRONIC_SHA1SUM_AMD64} ;; \
        "arm64") SUPERCRONIC_SHA1SUM=${SUPERCRONIC_SHA1SUM_ARM64} ;; \
    esac \
    && wget --progress=dot:giga https://github.com/aptible/supercronic/releases/download/v${SUPERCRONIC_VERSION}/supercronic-linux-${TARGETARCH} -O supercronic \
    && echo "${SUPERCRONIC_SHA1SUM}" supercronic | sha1sum -c - \
    && chmod +x supercronic \
    && mv supercronic /usr/local/bin/supercronic

ENV HOME=/home/steam \
    PORT= \
    PUID=1000 \
    PGID=1000 \
    PLAYERS= \
    MULTITHREADING=false \
    COMMUNITY=false \
    PUBLIC_IP= \
    PUBLIC_PORT= \
    SERVER_PASSWORD= \
    SERVER_NAME= \
    ADMIN_PASSWORD= \
    UPDATE_ON_BOOT=true \
    RCON_ENABLED=true \
    RCON_PORT=25575 \
    QUERY_PORT=27015 \
    TZ=UTC \
    SERVER_DESCRIPTION= \
    BACKUP_ENABLED=true \
    DELETE_OLD_BACKUPS=false \
    OLD_BACKUP_DAYS=30 \
    BACKUP_CRON_EXPRESSION="0 0 * * *" \
    AUTO_UPDATE_ENABLED=false \
    AUTO_UPDATE_CRON_EXPRESSION="0 * * * *" \
    AUTO_UPDATE_WARN_MINUTES=30 \
    AUTO_REBOOT_ENABLED=false \
    AUTO_REBOOT_WARN_MINUTES=5 \
    AUTO_REBOOT_EVEN_IF_PLAYERS_ONLINE=false \
    AUTO_REBOOT_CRON_EXPRESSION="0 0 * * *" \
    DISCORD_WEBHOOK_URL= \
    DISCORD_CONNECT_TIMEOUT=30 \
    DISCORD_MAX_TIMEOUT=30 \
    DISCORD_PRE_UPDATE_BOOT_MESSAGE="Server is updating..." \
    DISCORD_PRE_UPDATE_BOOT_MESSAGE_URL= \
    DISCORD_PRE_UPDATE_BOOT_MESSAGE_ENABLED=true \
    DISCORD_POST_UPDATE_BOOT_MESSAGE="Server update complete!" \
    DISCORD_POST_UPDATE_BOOT_MESSAGE_URL= \
    DISCORD_POST_UPDATE_BOOT_ENABLED=true \
    DISCORD_PRE_START_MESSAGE="Server has been started!" \
    DISCORD_PRE_START_MESSAGE_URL= \
    DISCORD_PRE_START_MESSAGE_ENABLED=true \
    DISCORD_PRE_SHUTDOWN_MESSAGE="Server is shutting down..." \
    DISCORD_PRE_SHUTDOWN_MESSAGE_URL= \
    DISCORD_PRE_SHUTDOWN_MESSAGE_ENABLED=true \
    DISCORD_POST_SHUTDOWN_MESSAGE="Server has been stopped!" \
    DISCORD_POST_SHUTDOWN_MESSAGE_URL= \
    DISCORD_POST_SHUTDOWN_MESSAGE_ENABLED=true \
    DISCORD_PLAYER_JOIN_MESSAGE="\${player_name} has joined Palworld!" \
    DISCORD_PLAYER_JOIN_MESSAGE_URL= \
    DISCORD_PLAYER_JOIN_MESSAGE_ENABLED=true \
    DISCORD_PLAYER_LEAVE_MESSAGE="\${player_name} has left Palworld." \
    DISCORD_PLAYER_LEAVE_MESSAGE_URL= \
    DISCORD_PLAYER_LEAVE_MESSAGE_ENABLED=true \
    DISCORD_PRE_BACKUP_MESSAGE="Creating backup..." \
    DISCORD_PRE_BACKUP_MESSAGE_URL= \
    DISCORD_PRE_BACKUP_MESSAGE_ENABLED=true \
    DISCORD_POST_BACKUP_MESSAGE="Backup created at \${FILE_PATH}" \
    DISCORD_POST_BACKUP_MESSAGE_URL= \
    DISCORD_POST_BACKUP_MESSAGE_ENABLED=true \
    DISCORD_PRE_BACKUP_DELETE_MESSAGE="Removing backups older than \${OLD_BACKUP_DAYS} days" \
    DISCORD_PRE_BACKUP_DELETE_URL= \
    DISCORD_PRE_BACKUP_DELETE_ENABLED=true \
    DISCORD_POST_BACKUP_DELETE_MESSAGE="Removed backups older than \${OLD_BACKUP_DAYS} days" \
    DISCORD_POST_BACKUP_DELETE_URL= \
    DISCORD_POST_BACKUP_DELETE_ENABLED=true \
    DISCORD_ERR_BACKUP_DELETE_MESSAGE="Unable to delete old backups, OLD_BACKUP_DAYS is not an integer. OLD_BACKUP_DAYS=\${OLD_BACKUP_DAYS}" \
    DISCORD_ERR_BACKUP_DELETE_URL= \
    DISCORD_ERR_BACKUP_DELETE_ENABLED=true \
    ENABLE_PLAYER_LOGGING=true \
    PLAYER_LOGGING_POLL_PERIOD=5 \
    ARM_COMPATIBILITY_MODE=false \
    DISABLE_GENERATE_ENGINE=true

COPY ./scripts /home/steam/server/

RUN chmod +x /home/steam/server/*.sh && \
    mv /home/steam/server/backup.sh /usr/local/bin/backup && \
    mv /home/steam/server/update.sh /usr/local/bin/update && \
    mv /home/steam/server/restore.sh /usr/local/bin/restore

WORKDIR /home/steam/server
RUN touch rcon.yaml crontab && \
    mkdir -p /home/steam/Steam/package && \
    chown steam:steam /home/steam/Steam/package && \
    rm -rf /tmp/dumps && \
    chmod o+w rcon.yaml crontab /home/steam/Steam/package && \
    chown steam:steam -R /home/steam/server

HEALTHCHECK --start-period=5m \
    CMD pgrep "PalServer-Linux" > /dev/null || exit 1

EXPOSE ${PORT} ${RCON_PORT}
ENTRYPOINT ["/home/steam/server/init.sh"]
