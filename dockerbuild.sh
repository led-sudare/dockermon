#!/bin/sh
cname=`cat ./cname`
docker build ./ -t $cname

docker container stop $cname
docker container rm $cname

docker run -t --init --name $cname -p 3001:3001 -v `pwd`:/work/ $cname