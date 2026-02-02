FROM eclipse-temurin:21-jre

ARG PUID=1000
ARG PGID=1000
ARG SC_VERSION=v0.2.42

ENV PUID=${PUID}
ENV PGID=${PGID}

RUN id ubuntu > /dev/null 2>&1 && deluser ubuntu

RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates procps jq && rm -rf /var/lib/apt/lists/*

# Install yq
RUN set -ex; \
    ARCH=$(dpkg --print-architecture); \
    case "${ARCH}" in \
        amd64) YQ_ARCH="yq_linux_amd64" ;; \
        arm64) YQ_ARCH="yq_linux_arm64" ;; \
        *) echo "Unsupported architecture: ${ARCH}"; exit 1 ;; \
    esac; \
    curl -fsSL "https://github.com/mikefarah/yq/releases/latest/download/${YQ_ARCH}" -o /usr/local/bin/yq; \
    chmod +x /usr/local/bin/yq

# Install Supercronic
RUN set -ex; \
    ARCH=$(dpkg --print-architecture); \
    case "${ARCH}" in \
        amd64) SC_ARCH="amd64" ;; \
        arm64) SC_ARCH="arm64" ;; \
        *) echo "Unsupported architecture: ${ARCH}"; exit 1 ;; \
    esac; \
    SC_TAG="${SC_VERSION}"; \
    if [ "${SC_TAG}" = "latest" ]; then \
        SC_TAG=$(curl -s https://api.github.com/repos/aptible/supercronic/releases/latest | jq -r .tag_name); \
    fi; \
    echo "TARGETARCH: ${TARGETARCH}"; \
    echo "Downloading supercronic version ${SC_TAG} for ${SC_ARCH}"; \
    curl -fsSL "https://github.com/aptible/supercronic/releases/download/${SC_TAG}/supercronic-linux-${SC_ARCH}" -o /usr/local/bin/supercronic; \
    chmod +x /usr/local/bin/supercronic; \
    ln -s /usr/local/bin/supercronic /usr/local/bin/crond

COPY app /app
RUN chmod +x /app/*.sh

WORKDIR /data

ENTRYPOINT [ "/app/entrypoint.sh" ]
CMD [ "/app/start.sh" ]
