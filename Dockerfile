FROM ubuntu
RUN apt-get update && \
    apt-get install -y wget curl cron && \
    wget -qO- https://binaries.cockroachdb.com/cockroach-v2.0.6.linux-amd64.tgz | tar  xvz && \
    cp -i cockroach-v2.0.6.linux-amd64/cockroach /usr/local/bin
RUN mkdir /backup

ENV CRON_TIME="0 0 * * *" \
    PG_DB="--all-databases"

ADD run.sh /run.sh
RUN chmod +x /run.sh
VOLUME ["/backup"]

CMD ["/bin/bash", "run.sh"]
