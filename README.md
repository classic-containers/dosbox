# Dosbox

## Introduction

This project is Dosbox in an Alpine Linux container, complete with sound support.
It was largely inspired by https://github.com/h6w/dosbox-docker and includes
a handful of improvements over that project:

- Multi-Stage Build (retain only what is necessary in final image)
- Use Alpine 3 (rather than Edge)
- Use native alsa packages, instead of building them
- Updated version of dosbox (which is obtained directly through SourceForge)
- After build, run as non-root user
- Provide canned dosbox.conf, to mount C and D drives (see below)

## Running

In order to use, you'll need to provide X11 and Pulse audio support
to the container.

### Linux

Audio for Linux is currently untested; I'm not sure if the asound.conf
supplied to the container will negate the ability to use /dev/snd.

```shell
$ docker run \
    -e DISPLAY=unix$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    --device /dev/snd
    classiccontainers/dosbox
```

### Docker for Windows

After installing Docker for Windows,

1. Install X11 Server, such as [VcXsrv](https://sourceforge.net/projects/vcxsrv/).
    - Make sure to turn [Access Control Off](https://skeptric.com/wsl2-xserver/).
2. Install and configure [Windows port](https://tomjepp.uk/2015/05/31/streaming-audio-from-linux-to-windows.html) of Pulse Audio
    - In `config.pa`, set `auth-ip-acl` to the Docker bridge network
      (or full private subnet `172.16.0.0/12`);
      see [Pulse Audio Docs](https://wiki.archlinux.org/index.php/PulseAudio/Examples#PulseAudio_over_network) for examples.
3. Enable X11 and Pulse Audio through [Windows firewall](https://skeptric.com/wsl2-xserver/#allow-wsl-access-via-windows-firewall)
    - I enabled them for Public and Private networks and set the Remote IP addresses to `172.16.0.0/12`
    - The need for this step might depend on whether you use the WSL2 backend for Docker.
    [Currently](https://github.com/microsoft/WSL/issues/4139),
    Windows considers the WSL2 network interface "Public", so you'll need to
    allow both programs on public networks and then you'll probably want to
    lock it down to the Private 172 CIDR for security
    - Pulse Audio has firewall rules for both TCP and UDP; make sure to update both
4. Run the docker container, exporting appropriate variables
   ```shell
   $ docker run \
       -e DISPLAY=host.docker.internal:0 \
       -e PULSE_SERVER=host.docker.internal \
       classiccontainers/dosbox
    ```

## Saving Games

At startup, DOSBox is configured to mount the A drive to /var/games/dosbox.
If you would like to retain game data between container runs, simply mount
a local directory to /var/games/dosbox inside the container.

```shell
$ docker run \
    -v /home/user1/savedata:/var/games/dosbox
```

Anything you or the game saves to the A drive should then be available on your
local machine, and you should be able to load data from the same location on future
runs of the container.

I was originally going to use the D drive for the save mount, but I imagine
some things out there expect the D drive to be a CD-ROM, and people probably
more commonly used the floppy drive at A for transferring saves (and other
random stuff) anyway. Hopefully your downstream game/whatever won't barf
when it sees a large drive or files on the A drive.

## Configuring DOSBox & Extending

This image comes with a canned dosbox.conf which is loaded via the ENTRYPOINT
when the container runs; included in the file are autoexec commands to mount
the C drive to /home/dosbox and the A drive to /var/games/dosbox (as above).

Since the A and C drives are already in use, you'll need to put elsewhere any
image mounts (for floppy or CD-ROM images) you need. See documentation on
[MOUNT](https://www.dosbox.com/wiki/MOUNT)

DOSBox will automatically load a `~/.dosbox/dosbox-{version}.conf` file or
a `./dosbox.conf` file if found. In an attempt to be future-proof about DOSBox
version, this image uses `./dosbox.conf`, but explicitly loads it with the
`-conf` parameter.

It's [not well documented](https://www.dosbox.com/DOSBoxManual.html#ConfigFile),
but DOSBox [supports](https://www.vogons.org/viewtopic.php?p=172469#p172469)
multiple `-conf` directives, which is why this image explicitly loads
`./dosbox.conf`. For regular settings, the one found in the last conf file
wins, and autoexec directives are merged.
This means that you should be able to construct a downstream image, `ADD`
or `COPY` your own conf file, and use `CMD` to add additional `-conf filename`
directives are required.

*NOTE* Remember to chown (or chmod) the file so that the dosbox user can read it!

Example dosbox conf:

```ini
[autoexec]
c:
mygame.exe
```

Example Dockerfile:

```dockerfile
FROM classiccontainers/dosbox

# fetch game zip
ADD --chown=dosbox:dosbox https://oldgame.net/oldgame.zip oldgame.zip

RUN unzip mygame.zip

COPY --chown=dosbox:dosbox dosbox_oldgame.conf dosbox_oldgame.conf

CMD ["-conf", "dosbox_oldgame.conf"]
```
