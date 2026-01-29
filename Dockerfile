FROM eclipse-temurin:21-jre

ARG PUID=1000
ARG PGID=1000

ENV PUID=${PUID}
ENV PGID=${PGID}

RUN id ubuntu > /dev/null 2>&1 && deluser ubuntu

COPY app /app
RUN chmod +x /app/*.sh

WORKDIR /data

ENTRYPOINT [ "/app/entrypoint.sh" ]
CMD [ "/app/start.sh" ]
