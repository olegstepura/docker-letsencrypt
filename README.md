# docker-letsencrypt

Docker lightweight letsencrypt image with `build` and `run` interactive scripts using [docker-shell](https://github.com/olegstepura/docker-shell). 
Can be used to issue free SSL certificates with letsencrypt without the need to stop web server during certificates reissue (expected web server is `nginx`).
Uses [cool tiny python scipt for updating certificates via letsencrypt](https://github.com/diafygi/acme-tiny) from [Daniel Roesler](https://github.com/diafygi).
Repository also contains shell script to issue SSL certificates with letsencrypt (to be run on the host machine via cron).

## Usage
Build using:
```bash
./build.sh
```

Run using:
```bash
./run.sh
```

Scripts will ask you for all details before running actual commands and will print what it's going to run. 
After you've setup one or several domains using `run.sh`, setup cron:
```bash
SHELL=/bin/bash
MAILTO=your@mail.address
#m  h    dom    mon   dow   user    command
0   0    1      */2   *     root    /usr/src/docker-letsencrypt/generate.sh domain.com letsencrypt-domain-com
0   0    1      */2   *     root    /usr/src/docker-letsencrypt/generate.sh otherdomain.org letsencrypt-otherdomain-org
```

`generate.sh` backups current certificates, tries to generate new ones in a temporary directory. If reissue runs without errors, certificates are moved to main dir. Nginx is then started in configcheck mode to test if configuration is ok to restart nginx. If everything is ok, nginx is restarted. If nginx configuration test fails, old certitificates are copied back to main dir. You will recieve email in case of an error (cron will send it if you set up everything).

## Nginx config:
Best way is to setup a separate snippet to be included in all your websites' `server` configuration sections. E.g. having `/etc/nginx/snippets/letsencrypt.conf`:
```nginx
location /.well-known/acme-challenge {
    alias /docker/letsencrypt/acme-challenge/;
    auth_basic off;
    default_type "text/plain";
}
```
and including it using
```nginx
server {
    listen *:80;
    # in case your server is accessible via ipv6
    listen [::]:80;

    server_name domain.com;
    # here comes the include directive
    include snippets/letsencrypt.conf;

    location / {
      return 302 https://$server_name$request_uri;
    }
}
```
