# vim:set ft=dockerfile:
FROM debian:jessie

RUN export DEBIAN_FRONTEND=noninteractive && \
	apt-get update && \
	apt-get upgrade -y && \
	apt-get install -y \
		openssl \
		wget \
		git \
		python && \

	mkdir -p /usr/src/acme-tiny && \
	mkdir -p /srv/www && \
	git clone https://github.com/diafygi/acme-tiny.git /usr/src/acme-tiny && \

	apt-get remove -y git && \
	apt-get autoremove -y && \
	apt-get clean -qq && \
  	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY image-files/ /

CMD ["/gen-cert.sh"]
