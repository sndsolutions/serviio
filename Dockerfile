FROM    alpine:3.10

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
ARG FFMPEG_VERSION
ARG SERVIIO_VERSION

RUN     echo "Buikd date: $BUILD_DATE" \
        echo "VCF_REF: $VCF_REF" \
        echo "Version: $VERSION" \
        echo "Version: $FFMPEG_VERSION" \
        echo "Version: $SERVIIO_VERSION"

LABEL   org.label-schema.build-date=$BUILD_DATE \
        org.label-schema.name="DLNA Serviio Container" \
        org.label-schema.description="DLNA Serviio Container" \
        org.label-schema.url="https://sndsolutions.be/schemas/serviio" \
        org.label-schema.vcs-ref=$VCS_REF \
        org.label-schema.vcs-url="https://github.com/sndsolutions/serviio" \
        org.label-schema.vendor="SnD Solutions" \
        org.label-schema.version=$VERSION \
        org.label-schema.schema-version="1.0" \
        maintainer="SnD Solutions Fitch <fitch@outlook.be>"

ENV JAVA_HOME="/usr"

RUN     echo "http://dl-cdn.alpinelinux.org/alpine/v3.10/main" >> /etc/apk/repositories; \
        echo "http://dl-cdn.alpinelinux.org/alpine/v3.10/community" >> /etc/apk/repositories; \
        echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories; \
        echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories; \
        echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories; \
        apk update && apk upgrade  && \
        apk add --no-cache --update \
                alsa-lib \
                bzip2 \
                expat \
                fdk-aac \
                lame \
                libbz2 \
                libdrm \
                libffi \
                libjpeg-turbo \
                libtheora \
                libogg \
                libpciaccess \
                librtmp \
                libstdc++ \
                libtasn1 \
                libva \
                libvorbis \
                libvpx \
                mesa-gl \
                mesa-glapi \
                musl \
                opus \
                openjdk8-jre \
                p11-kit \
                sdl \
                x264-libs \
                x264 \
                x265 \
                jasper-dev \
                libass-dev \
                gnutls-dev \
                libwebp-dev \
                lame-dev \
                v4l-utils-libs \
                xvidcore && \
        apk add --no-cache --update --virtual=build-dependencies \
                alsa-lib-dev \
                bzip2-dev \
                coreutils \
                curl \
                fdk-aac-dev \
                freetype-dev \
                g++ \
                gcc \
                git \
                imlib2-dev \
                lcms2-dev \
                libgcc \
                libjpeg-turbo-dev \
                libtheora-dev \
                libogg-dev \
                libva-dev \
                libvorbis-dev \
                libvpx-dev \
                libx11 \
                libxau \
                libxcb \
                libxcb-dev \
                libxdamage \
                libxdmcp \
                libxext \
                libxfixes \
                libxfixes-dev \
                libxshmfence \
                libxxf86vm \
                make \
                musl-dev \
                nasm \
                nettle \
                opus-dev \
                pkgconf \
                pkgconf-dev \
                rtmpdump-dev \
                sdl-dev \
                tar \
                ttf-dejavu \
                v4l-utils-dev \
                x264-dev \
                x265-dev \
                xvidcore-dev \
                yasm-dev \
                zlib-dev && \
        DIR=$(mktemp -d) && cd ${DIR} && \
	curl -s http://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz | tar zxf - -C . && \
	cd ffmpeg-${FFMPEG_VERSION} && ./configure \
                --disable-doc \
                --disable-debug \
                --disable-shared \
                --enable-avfilter \
                --enable-avresample \
                --enable-gnutls \
                --enable-gpl \
                --enable-libass \
                --enable-libfdk-aac \
                --enable-libfreetype \
                --enable-libmp3lame \
                --enable-libopus \
                --enable-librtmp \
                --enable-libtheora \
                --enable-libv4l2 \
                --enable-libvorbis \
                --enable-libvpx \
                --enable-libwebp \
                --enable-libx264 \
                --enable-libx265 \
                --enable-libxcb \
                --enable-libxvid \
                --enable-nonfree \
                --enable-pic \
                --enable-pthreads \
                --enable-postproc \
                --enable-static \
                --enable-version3 \
                --enable-vaapi \
                --prefix=/usr && \
	make -j4 && \
	make install && \
	gcc -o tools/qt-faststart $CFLAGS tools/qt-faststart.c && \
	install -D -m755 tools/qt-faststart /usr/bin/qt-faststart && \
	make distclean && \
	cd ${DIR} && \
	wget https://www.dechifro.org/dcraw/dcraw.c && \
	gcc -o dcraw -O4 dcraw.c -lm -ljasper -ljpeg -llcms2 && \
	cp dcraw /usr/bin/dcraw && \
	chmod +x /usr/bin/dcraw  && \
	cd ${DIR} && \
	curl -s http://download.serviio.org/releases/serviio-${VERSION}-linux.tar.gz | tar zxvf - -C . && \
	mkdir -p /opt/serviio && \
	mkdir -p /media/serviio && \
	mv ./serviio-${VERSION}/* /opt/serviio && \
	chmod +x /opt/serviio/bin/serviio.sh && \
	mkdir -p /opt/serviio/log && \
	touch /opt/serviio/log/serviio.log && \
	rm -rf ${DIR} && \
	apk del --purge build-dependencies && \
	rm -rf /var/cache/apk/*

VOLUME [ "/opt/serviio/config", "/opt/serviio/library",  "/opt/serviio/log", "/opt/serviio/plugins", "/media/serviio"]

EXPOSE 1900/udp
EXPOSE 8895/tcp
# HTTP/1.1 /console /rest
EXPOSE 23423/tcp 
# HTTPS/1.1 /console /rest
EXPOSE 23523/tcp
# HTTP/1.1 /cds /mediabrowser
EXPOSE 23424/tcp
# HTTPS/1.1 /cds /mediabrowser
EXPOSE 23524/tcp

CMD tail -f /opt/serviio/log/serviio.log & /opt/serviio/bin/serviio.sh