FROM almalinux:10.2-minimal-20260602

RUN microdnf install -y rpmlint wget git

# install reviewdog
ENV REVIEWDOG_VERSION=v0.14.1
RUN wget -O - -q https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b /usr/local/bin/ ${REVIEWDOG_VERSION}

COPY entrypoint.sh /entrypoint.sh
COPY rpmlint.py /rpmlint.py

ENTRYPOINT ["/entrypoint.sh"]
