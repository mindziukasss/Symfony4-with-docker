# Docker Symfony (PHP7.2-FPM - NGINX - MySQL - ELK)


Docker-symfony gives you everything you need for developing Symfony application. This complete stack run with docker and [docker-compose (1.7 or higher)](https://docs.docker.com/compose/).

## Installation

1. Create a `.env` from the `.env.dist` file. Adapt it according to your symfony application

    ```bash
    cp .env.dist .env
    ```

2. (OS X only) Setup docker-sync
    2. Install docker-sync
        ```
        $ gem install docker-sync
        ```
    
    3. Configure docker-sync
        1. Rename app-sync (e.g projectname-sync).
        
        ```yml
        # ./docker/docker-sync.yml
        version: '3'
        syncs:
           # IMPORTANT: this name must be unique! 
           app-sync:
             src: ${SYMFONY_APP_PATH}
        ```
         
        2. Update docker-compose.sync.yml to match your new docker-sync.yml container name.
         
         ```yml
         # ./docker/docker-compose.sync.yml
         version: '3'
          
         services:
             php:
                 volumes:
                     # IMPORTANT: this name must match docker-sync.yml sync name (e.g projectname-sync).
                     - app-sync:/var/www/symfony
                     - ./logs/symfony:/var/www/symfony/var/logs
                     - ./key/ssh/id_rsa:/root/.ssh/id_rsa:ro
         volumes:
           # IMPORTANT: this name must match docker-sync.yml sync name (e.g projectname-sync).
           app-sync:
             external: true
         ```
        3. Update start-dev.sh script. Rename --name parameter to match docker-sync.yml container name (e.g projectname-sync).
        
        ```bash
        #!/bin/bash
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
           # IMPORTANT: --name must match docker-sync.yml sync name (e.g projectname-sync).
           docker volume create --name=app-sync
           docker-compose -f docker-compose.yml -f docker-compose.sync.yml up -d
           docker-sync start
        else
           docker-compose up -d
        fi
        ```

3. Build/run containers

    ```bash
    $ ./start-dev.sh
    ```

4. Update your system host file (add app_name.dev)

    ```bash
    # UNIX only: get containers IP address and update host (replace IP according to your configuration) (on Windows, edit C:\Windows\System32\drivers\etc\hosts)
    $ sudo echo $(docker network inspect bridge | grep Gateway | grep -o -E '[0-9\.]+') "app_name.dev" >> /etc/hosts
    ```

    **Note:** For **OS X**, please take a look [here](https://docs.docker.com/docker-for-mac/networking/) and for **Windows** read [this](https://docs.docker.com/docker-for-windows/#/step-4-explore-the-application-and-run-examples) (4th step).

5. Prepare Symfony app
    1. Composer install & create database

        ```bash
        $ docker-compose exec php bash
        $ composer install
        # Symfony4
        $ sf doctrine:database:create
        $ sf doctrine:schema:update --force
        # Only if you have `doctrine/doctrine-fixtures-bundle` installed
        $ sf doctrine:fixtures:load --no-interaction
        ```

6. Enjoy :-)

## Usage

Just run `./start-dev.sh`, then:

* Symfony app: visit [app_name.dev:8080](http://app_name.dev:8080)  
* Symfony dev mode: visit [app_name.dev:8080/app_dev.php](http://app_name.dev:8080/app_dev.php)  
* Logs (Kibana): [app_name.dev:81](http://app_name.dev:81)
* Logs (files location): logs/nginx and logs/symfony

## Customize

If you want to add optionnals containers like Redis, PHPMyAdmin... take a look on [doc/custom.md](doc/custom.md).

## How it works?

Have a look at the `docker-compose.yml` file, here are the `docker-compose` built images:

* `db`: This is the MySQL database container,
* `php`: This is the PHP-FPM container in which the application volume is mounted,
* `nginx`: This is the Nginx webserver container in which application volume is mounted too,
* `elk`: This is a ELK stack container which uses Logstash to collect logs, send them into Elasticsearch and visualize them with Kibana.

This results in the following running containers:

```bash
$ docker-compose ps
           Name                          Command               State              Ports            
--------------------------------------------------------------------------------------------------
dockersymfony_db_1            /entrypoint.sh mysqld            Up      0.0.0.0:3307->3306/tcp      
dockersymfony_elk_1           /usr/bin/supervisord -n -c ...   Up      0.0.0.0:81->80/tcp          
dockersymfony_nginx_1         nginx                            Up      443/tcp, 0.0.0.0:8080->80/tcp
dockersymfony_php_1           php-fpm                          Up      0.0.0.0:9000->9000/tcp      
```

## Useful commands

```bash
# bash commands
$ docker-compose -f ./docker/docker-compose.yml exec php bash

# Composer (e.g. composer update)
$ docker-compose -f ./docker/docker-compose.yml exec php composer update

# SF commands (Tips: there is an alias inside php container)
$ docker-compose -f ./docker/docker-compose.yml exec php php /var/www/symfony/bin/console cache:clear # Symfony3
# Same command by using alias
$ docker-compose -f ./docker/docker-compose.yml exec php bash
$ sf cache:clear

# Retrieve an IP Address (here for the nginx container)
$ docker inspect --format '{{ .NetworkSettings.Networks.dockersymfony_default.IPAddress }}' $(docker ps -f name=nginx -q)
$ docker inspect $(docker ps -f name=nginx -q) | grep IPAddress

# MySQL commands
$ docker-compose -f ./docker/docker-compose.yml exec db mysql -uroot -p"root"

# Check CPU consumption
$ docker stats $(docker inspect -f "{{ .Name }}" $(docker ps -q))

# Delete all containers
$ docker rm $(docker ps -aq)

# Delete all images
$ docker rmi $(docker images -q)
```

## FAQ

* Permission problem? See [this doc (Setting up Permission)](http://symfony.com/doc/current/book/installation.html#checking-symfony-application-configuration-and-setup)

* How to config Xdebug?
Xdebug is configured out of the box!
Just config your IDE to connect port  `9001` and id key `PHPSTORM`