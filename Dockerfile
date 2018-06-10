FROM alpine:3.6

# Uncomment if local sources
# COPY ./MTProxy /mtproxy/sources

COPY ./patches /mtproxy/patches

RUN apk add --no-cache --virtual .build-deps \
      git make gcc musl-dev linux-headers openssl-dev \
    && git clone --single-branch --depth 1 https://github.com/TelegramMessenger/MTProxy.git /mtproxy/sources \
    && cd /mtproxy/sources \
    && patch -p0 -i /mtproxy/patches/randr_compat.patch \
    && make -j$(getconf _NPROCESSORS_ONLN)
    # Let's skip all cleaning stuff for faster build
    # && cp /mtproxy/sources/objs/bin/mtproto-proxy /mtproxy/ \
    # && rm -rf /mtproxy/{sources,patches} \
    # && apk add --virtual .rundeps libcrypto1.0 \
    # && apk del .build-deps

FROM alpine:3.6
LABEL maintainer="Alex Doe <alex@doe.sh>" \
      description="Telegram Messenger MTProto zero-configuration proxy server."

RUN apk add --no-cache curl \
  && ln -s /usr/lib/libcrypto.so.41 /usr/lib/libcrypto.so.1.0.0
  # alpine:3.7 will need symlink to libcrypto.so.42

WORKDIR /mtproxy

COPY --from=0 /mtproxy/sources/objs/bin/mtproto-proxy .
COPY docker-entrypoint.sh /

VOLUME /data
EXPOSE 2398 443

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD [ \
  "--port", "2398", \
  "--http-ports", "443", \
  "--slaves", "2", \
  "--max-special-connections", "60000", \
  "--allow-skip-dh" \
]
