FROM almalinux:9.1-20221117

RUN dnf install -y rpmlint

# install reviewdog
ENV REVIEWDOG_VERSION=v0.14.1
RUN wget -O - -q https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b /usr/local/bin/ ${REVIEWDOG_VERSION}

COPY entrypoint.sh /entrypoint.sh
COPY rpmlint.py /rpmlint.py

ENTRYPOINT ["/entrypoint.sh"]
