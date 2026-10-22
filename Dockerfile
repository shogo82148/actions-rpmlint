FROM almalinux:10@sha256:838c2fafefb1a8a0d7f8cdbc3b0551c2a2b1eb0cd87aad6d62aecadb18311f1b

# Build Python

# ensure local python is preferred over distribution python
ENV PATH=/usr/local/bin:$PATH

# runtime dependencies
RUN set -eux; \
  dnf install -y \
  bluez-libs-devel \
  tk-devel \
  libuuid-devel; \
  dnf clean all; \
  rm -rf /var/cache/dnf

ENV PYTHON_VERSION=3.15.1
ENV PYTHON_SHA256=673ae7232d84c894729882c8257d300ef2d26523911bfd3917ec8ce7f526f99b

RUN set -eux; \
  savedDnfMark="$(dnf repoquery \
  --userinstalled \
  --queryformat '%{name}')"; \
  \
  buildDeps='wget gcc gcc-c++ make pkg-config glibc-devel libstdc++-devel openssl-devel readline-devel zlib-devel libzstd-devel libffi-devel bzip2-devel xz-devel sqlite-devel libuuid-devel gdbm-devel expat-devel'; \
  dnf install -y $buildDeps; \
  \
  wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz"; \
  echo "$PYTHON_SHA256 *python.tar.xz" | sha256sum -c -; \
  mkdir -p /usr/src/python; \
  tar --extract --directory /usr/src/python --strip-components=1 --file python.tar.xz; \
  rm python.tar.xz; \
  cd /usr/src/python; \
  gnuArch="$(rpm --eval '%{_build}')"; \
  ./configure \
  --build="$gnuArch" \
  --enable-loadable-sqlite-extensions \
  --enable-optimizations \
  --enable-option-checking=fatal \
  --enable-shared \
  --with-lto \
  --with-ensurepip \
  ; \
  nproc="$(nproc)"; \
  EXTRA_CFLAGS="$(rpm --eval '%{build_cflags}')"; \
  LDFLAGS="$(rpm --eval '%{?build_ldflags}')"; \
  # add "-mno-omit-leaf"
  EXTRA_CFLAGS="${EXTRA_CFLAGS:-} -fno-omit-frame-pointer -mno-omit-leaf-frame-pointer"; \
  make -j "$nproc" \
  "EXTRA_CFLAGS=${EXTRA_CFLAGS:-}" \
  "LDFLAGS=${LDFLAGS:-}" \
  ; \
  # https://github.com/docker-library/python/issues/784
  # prevent accidental usage of a system installed libpython of the same version
  rm python; \
  make -j "$nproc" \
  "EXTRA_CFLAGS=${EXTRA_CFLAGS:-}" \
  "LDFLAGS=${LDFLAGS:-} -Wl,-rpath='\$\$ORIGIN/../lib'" \
  python \
  ; \
  make install; \
  \
  cd /; \
  rm -rf /usr/src/python; \
  \
  dnf mark remove $buildDeps; \
  dnf mark install $savedDnfMark; \
  dnf autoremove -y; \
  dnf clean all; \
  rm -rf /var/cache/dnf; \
  export PYTHONDONTWRITEBYTECODE=1; \
  python3 --version; \
  pip3 --version

# install rpmlint
# some dependencies (e.g. zstandard) may not ship pre-built wheels for the latest Python,
# so install a C compiler temporarily to build them from source.
# NOTE: this must run before installing rpm-build; its redhat-rpm-config pulls in annobin
# whenever gcc is installed, which prevents `dnf autoremove` from removing gcc.
RUN set -eux; \
  savedDnfMark="$(dnf repoquery \
  --userinstalled \
  --queryformat '%{name}')"; \
  \
  buildDeps='gcc glibc-devel'; \
  dnf install -y $buildDeps; \
  \
  pip3 install --no-cache-dir rpmlint; \
  \
  dnf mark remove $buildDeps; \
  dnf mark install $savedDnfMark; \
  dnf autoremove -y; \
  dnf clean all; \
  rm -rf /var/cache/dnf; \
  rpmlint --version

# dependencies for rpmlint
RUN set -eux; \
  dnf install -y \
    rpm-build \
    glibc-langpack-en; \
  dnf clean all; \
  rm -rf /var/cache/dnf

COPY entrypoint.sh /entrypoint.sh
COPY post-pr-comment.py /post-pr-comment.py

ENTRYPOINT ["/entrypoint.sh"]
