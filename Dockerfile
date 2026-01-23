FROM eclipse-temurin:21-jre

ARG UID=1000
ARG GID=1000

ENV UID=${UID}
ENV GID=${GID}

RUN id ubuntu > /dev/null 2>&1 && deluser ubuntu

COPY app /app
RUN chmod +x /app/*.sh

WORKDIR /data

ENTRYPOINT [ "/app/entrypoint.sh" ]
CMD [ "/app/start.sh" ]
