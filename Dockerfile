# Build Container
FROM alpine:3 as dosbox-build

# install buildtime and runtime stuff
RUN apk add --no-cache sdl libxxf86vm libstdc++ libgcc build-base sdl-dev \
    linux-headers file pulseaudio-dev alsa-plugins-pulse

# set root's home directory for the build (not /, that's nasty...)
WORKDIR /root

# Download the source, which we'll build
ADD https://sourceforge.net/projects/dosbox/files/dosbox/0.74-3/dosbox-0.74-3.tar.gz/download dosbox.tar.gz

# extract, stripping off the first directory so we don't have to know what it is beforehand
RUN tar -xzv --strip-components=1 -f dosbox.tar.gz && \
    ./configure --prefix=/usr && \
    make && \
    make install

# Runtime Container
FROM alpine:3

# copy ALSA config
COPY asound.conf /etc/asound.conf
# copy built dosbox binary from build container
COPY --from=dosbox-build /usr/bin/dosbox /usr/bin/dosbox

# install runtime packages and add dosbox user
RUN apk add --no-cache sdl libxxf86vm libstdc++ libgcc alsa-plugins-pulse && \
    adduser -D dosbox

USER dosbox
WORKDIR /home/dosbox

ENTRYPOINT /bin/ash
