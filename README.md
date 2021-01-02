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

## Using

In order to use, you'll need to provide X11 and Pulse audio support
to the container.

### Linux

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
2. Install and configure [Windows port](https://x410.dev/cookbook/wsl/enabling-sound-in-wsl-ubuntu-let-it-sing/) of Pulse Audio
    - In `etc\pulse\default.pa`, set `auth-ip-acl` to the Docker bridge network
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
