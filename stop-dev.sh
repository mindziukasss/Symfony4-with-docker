#!/bin/bash

if [[ "$OSTYPE" == "darwin"* ]]; then
	docker-compose stop
	docker-sync stop
else
    docker-compose stop
fi