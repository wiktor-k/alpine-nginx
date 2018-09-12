# Alpine Nginx

[![Build Status](https://travis-ci.org/wiktor-k/alpine-nginx.svg?branch=master)](https://travis-ci.org/wiktor-k/alpine-nginx)

Latest Nginx on latest Alpine with latest LibreSSL.

For exact versions see the Dockerfile.

To run it locally on port `8080` use:

    docker run --rm -it -p 8080:80 wiktork/alpine-nginx:latest

Use a named tag instead of `latest` to pin versions.

## Configuration

Nginx inside this container is without configuration.
To supply your own configuration files add a volume and explicit option.

Below is a sample Docker Compose file:

```yaml
web:
    image: "wiktork/alpine-nginx:1.15.3-3.8-1.1.1"
    command: ["/nginx/sbin/nginx", "-g", "daemon off;", "-c", "/configuration/nginx.conf"]
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /configuration:/configuration
    restart: unless-stopped
```

This image on [Docker Hub][HUB].

[HUB]: https://hub.docker.com/r/wiktork/alpine-nginx
