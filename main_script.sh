#!/bin/bash

#Installation of Docker & Docker-Compose
echo "$(tput setaf 1)$(tput setab 7) $(echo -e "\x1b[1m INSTALLING DOCKER & DOCKER-COMPOSE ON YOUR SYSTEM")$(tput sgr 0)"
sh install_docker.sh

#Docker-Hub login with credentials
echo "$(tput setaf 1)$(tput setab 7) $(echo -e "\x1b[1m CONNECTING TO DOCKER REPOSITORY")$(tput sgr 0)"
/usr/bin/docker login dockerhub.kensium.com --username=mohankrishnav --password='Krish123%'
#Download the image & bring up the container
echo "$(tput setaf 1)$(tput setab 7) $(echo -e "\x1b[1m DOWNLOADING THE MAGENTO 2.2.5 IMAGE FROM DOCKER HUB")$(tput sgr 0)"
docker-compose up -d

#Set sudo user permission for docker
echo "$(tput setaf 1)$(tput setab 7) $(echo -e "\x1b[1m SETTING USER PERMISSION TO RUN DOCKER COMMANDS")$(tput sgr 0)"
usermod -aG docker ubuntu

#Findout the ip to add it into /etc/hosts
PVTIP=$(ip route get 8.8.8.8 | sed -n '/src/{s/.*src *\([^ ]*\).*/\1/p;q}')
PUBIP=$(curl ifconfig.me)
echo ""
echo "$(tput setaf 1)$(tput setab 7) $(echo -e "\x1b[1m TO ACCESS DOMAIN NAME devops.magento225.com, PLEASE ADD THE BELOW LINE IN YOUR HOST FILE")$(tput sgr 0)"
echo ""
echo "$(tput setaf 1)$(tput setab 7) $(echo -e "\x1b[1m Entry for Private IP Address")$(tput sgr 0)"
echo $PVTIP devops.magento225.com

echo ""
echo ""
echo "$(tput setaf 1)$(tput setab 7) $(echo -e "\x1b[1m Entry for Public IP Address")$(tput sgr 0)"
echo $PUBIP devops.magento225.com
echo ""

docker cp magento225:/home/magento225.tar.gz ./magento225/
cd ./magento225/ && sudo tar -xvf magento225.tar.gz
rm -rf magento225.tar.gz
