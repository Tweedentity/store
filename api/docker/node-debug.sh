#!/usr/bin/env bash

docker run -it --rm \
  --name tweedentity-debug \
  -p 3132 \
  -v $PWD:/usr/src/app \
  -v $PWD/log:/var/log/tweedentity \
  -w /usr/src/app node:carbon npm run start
