#!/bin/bash
docker run --name helpa -p 80:80 -p 222:22 -v helpavol:/data -v /home/nik/helpa/:/data/www_root oas/helpav1
