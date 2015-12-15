# docker-letsencrypt

Docker lightweight letsencrypt image with `build` and `run` interactive scripts using [docker-shell](https://github.com/olegstepura/docker-shell).
Uses [cool tiny python scipt for updating certificates via letsencrypt](https://github.com/diafygi/acme-tiny) from [Daniel Roesler](https://github.com/diafygi).
Repository also contains shell script to issue ssl certificates with letsencrypt (to be run on the host machine via cron).

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

