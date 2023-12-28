#!/usr/bin/env bash
GREEN="\e[32m"
NC="\e[0m"

#Uninstall old versions
sudo apt-get remove docker docker-engine docker.io containerd runc

#Update the apt package index
sudo apt-get update
sudo apt-get install \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release -y

#Add Docker’s official GPG key if it the docker.gpg file does not exist
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    printf "${GREEN}Adding docker gpg key...${NC}\n"
    #Create the keyrings directory if it does not exist
    if [ ! -d /etc/apt/keyrings ]; then
        sudo mkdir -p /etc/apt/keyrings
    fi
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
fi

#Add Docker apt repository if it does not exist
if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
    printf "${GREEN}Adding docker apt repository...${NC}\n"
    #Create the sources.list.d directory if it does not exist
    if [ ! -d /etc/apt/sources.list.d ]; then
        sudo mkdir -p /etc/apt/sources.list.
    fi

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
fi

#Install the docker engine
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io -y

#Setup permissions for the current user to run docker commands
sudo usermod -aG docker $USER

#Add a command to start docker in the /etc/wsl.conf file if it does not exist inside the file using sed
#This will ensure that docker is started everytime the WSL is started
if ! grep "command=" /etc/wsl.conf; then
    printf "${GREEN}Setting docker to start automatically...${NC}\n"
    echo 'command= service docker start' | sudo tee -a /etc/wsl.conf > /dev/null
fi

#if the docker service is not running, start it
if ! sudo service docker status | grep "active (running)"; then
    printf "${GREEN}Starting docker...${NC}"
    sudo service docker start
fi

#Wait until the docker service is running
while ! sudo service docker status | grep "active (running)"; do
    printf "${GREEN}Waiting for docker to start...${NC}\n"
    sleep 2
done

#Test docker installation
sudo docker run hello-world

printf "${GREEN}You will need to restart your WSL session for the changes to take effect${NC}\n"