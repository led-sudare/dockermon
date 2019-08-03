#!/bin/sh
cname=`cat ./cname`
docker build ./ -t $cname 

echo "stopping.. " && docker container stop $cname
echo "removing.. " && docker container rm $cname

echo "run and stating.. " && docker run -t --init --name $cname -p 3001:3001 -v `pwd`:/work/ $cname