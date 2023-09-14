#!/bin/bash

docker stop civetweb_hello || true
docker rm -f civetweb_hello || true
docker build -t civetweb_hello -f civetweb.dockerfile .
docker run -d -p 3001:8080 --name civetweb_hello civetweb_hello

docker stop shelf_hello || true
docker rm -f shelf_hello || true
docker build -t shelf_hello -f shelf.dockerfile .
docker run -d -p 3002:8080 --name shelf_hello shelf_hello

docker stop node_hello || true
docker rm -f node_hello || true
docker build -t node_hello -f node.dockerfile .
docker run -d -p 3003:8080 --name node_hello node_hello

docker stop csharp_hello || true
docker rm -f csharp_hello || true
docker build -t csharp_hello -f csharp.dockerfile .
docker run -d -p 3004:80 --name csharp_hello csharp_hello

docker stop go_hello || true
docker rm -f go_hello || true
docker build -t go_hello -f go.dockerfile .
docker run -d -p 3005:8080 --name go_hello go_hello

rm -f benchmark.txt

# Sleep 5 seconds to wait for the server to start
sleep 5

# Warm up
ab -n 1000 -c 100 -m GET http://127.0.0.1:3001/ > /dev/null
ab -n 1000 -c 100 -m GET http://127.0.0.1:3002/ > /dev/null
ab -n 1000 -c 100 -m GET http://127.0.0.1:3003/ > /dev/null
ab -n 1000 -c 100 -m GET http://127.0.0.1:3004/ > /dev/null
ab -n 1000 -c 100 -m GET http://127.0.0.1:3005/ > /dev/null

sleep 5

echo "CivetWeb" >> benchmark.txt
ab -n 100000 -c 1000 -m GET http://127.0.0.1:3001/ | grep -E "Time taken for tests|Complete requests|Failed requests|Requests per second|Time per request|Transfer rate" >> benchmark.txt

sleep 1
echo "----- ----- ----- ----- -----" >> benchmark.txt

echo "Dart + Shelf" >> benchmark.txt
ab -n 100000 -c 1000 -m GET http://127.0.0.1:3002/ | grep -E "Time taken for tests|Complete requests|Failed requests|Requests per second|Time per request|Transfer rate" >> benchmark.txt

sleep 1
echo "----- ----- ----- ----- -----" >> benchmark.txt

echo "Node.js" >> benchmark.txt
ab -n 100000 -c 1000 -m GET http://127.0.0.1:3003/ | grep -E "Time taken for tests|Complete requests|Failed requests|Requests per second|Time per request|Transfer rate" >> benchmark.txt

sleep 1
echo "----- ----- ----- ----- -----" >> benchmark.txt

echo "C# Asn.Net.Core" >> benchmark.txt
ab -n 100000 -c 1000 -m GET http://127.0.0.1:3004/ | grep -E "Time taken for tests|Complete requests|Failed requests|Requests per second|Time per request|Transfer rate" >> benchmark.txt

sleep 1
echo "----- ----- ----- ----- -----" >> benchmark.txt

echo "Go fasthttp" >> benchmark.txt
ab -n 100000 -c 1000 -m GET http://127.0.0.1:3005/ | grep -E "Time taken for tests|Complete requests|Failed requests|Requests per second|Time per request|Transfer rate" >> benchmark.txt