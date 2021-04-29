#!/usr/bin/env bash
# This script setups dockerized Redash on Ubuntu 18.04.
set -eu

BASE_PATH=/opt/lms

install_docker(){
    # Install Docker
    export DEBIAN_FRONTEND=noninteractive
    sudo apt-get -qqy update
    DEBIAN_FRONTEND=noninteractive sudo -E apt-get -qqy -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade 
    sudo apt-get -yy install apt-transport-https ca-certificates curl software-properties-common wget pwgen
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update && sudo apt-get -y install docker-ce

    # Install Docker Compose
    sudo curl -L https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    # Allow current user to run Docker commands
    sudo usermod -aG docker $USER
}

create_directories() {
    if [[ ! -e $BASE_PATH ]]; then
        sudo mkdir -p $BASE_PATH
        sudo chown $USER:$USER $BASE_PATH
    fi

    if [[ ! -e $BASE_PATH/postgres-data ]]; then
        mkdir $BASE_PATH/postgres-data
    fi
}

create_config() {
    if [[ -e $BASE_PATH/env ]]; then
        rm $BASE_PATH/env
        touch $BASE_PATH/env
    fi

    COOKIE_SECRET=$(pwgen -1s 32)
    SECRET_KEY=$(pwgen -1s 32)
    POSTGRES_PASSWORD=$(pwgen -1s 32)
    DATABASE_URL="postgresql://postgres:${POSTGRES_PASSWORD}@postgres/postgres"

    echo "PYTHONUNBUFFERED=0" >> $BASE_PATH/env
    echo "LOG_LEVEL=INFO" >> $BASE_PATH/env
    echo "REDIS_URL=redis://redis:6379/0" >> $BASE_PATH/env
    echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD" >> $BASE_PATH/env
    echo "COOKIE_SECRET=$COOKIE_SECRET" >> $BASE_PATH/env
    echo "SECRET_KEY=$SECRET_KEY" >> $BASE_PATH/env
    echo "DATABASE_URL=$DATABASE_URL" >> $BASE_PATH/env
}

setup_compose() {
    cd $BASE_PATH

    wget https://raw.githubusercontent.com/Bllyth/Packer-Server-Setup/master/data/docker-compose.yml
    echo "export COMPOSE_PROJECT_NAME=lms" >> ~/.profile
    echo "export COMPOSE_FILE=/opt/lms/docker-compose.yml" >> ~/.profile
    export COMPOSE_PROJECT_NAME=lms
    export COMPOSE_FILE=/opt/lms/docker-compose.yml
    sudo docker-compose run --rm server create_db
    sudo docker-compose up -d
}

install_docker
create_directories
create_config
setup_compose