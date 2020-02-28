#! /bin/bash

# GLOBAL VARIABLES ###############################

# Directory for workbench configs
CONF="$HOME/.workbench"

# SSH key
KEY=""

# Git global preference
USER="MarinTailor"
EMAIL="marintailor@gmail.com"
EDITOR="code --wait"

# Git group of projects
GIT_DEV=()
GIT_FAV=(ansible bash python)
GIT_PROD=()

# Git directories
GITHUB="$HOME/git/github/"
GITLAB="$HOME/git/gitlab/"

# Base software and tools
SOFT="
curl \
firefox \
git \
net-tools \
terminator \
vlc \
wget \
tcpdump \
"


# PREPARE ########################################

# Create directory ".ssh" if is not present
if [ ! -d "${HOME}"/.ssh ]
then
    mkdir "${HOME}"/.ssh
fi

# TODO: Key should be stored encrypted
# Get SSH key
if [ ! -f "${HOME}"/.ssh/"${KEY}" ]
then
    cd "${HOME}"/.ssh
    wget https://gitlab/${USER}/workbench/raw/master/"${KEY}".tar --no-check-certificate
    tar xf "${KEY}".tar
    chmod 400 "${HOME}"/.ssh/"${KEY}"
    ssh-add "${HOME}"/.ssh/"${KEY}"
fi



# TODO: Is this directory needed? Run "venv" two times
# Make directory ".workbench" present
if [ ! -d "${CONF}" ]
then
    mkdir "${CONF}"
fi


# FUNCTIONS ######################################

# Deploy custom enviroment
all () {
    sudo apt update && sudo apt upgrade -y
    editor
    ide
    get-git
    soft
    sudo apt autoremove -y
}

# Git clone a project
clone () {
    check_git
    cd "${GITLAB}"
    git clone "ssh://git@gitlab/${USER}/$1"
    cd "${GITLAB}/$1"
    exec bash
}

# Git clone a group of projects
group () {
    check_git
    case "$1" in
        "dev")
            for dev in "${GIT_DEV[@]}"; do
                cd "${GITLAB}"
                git clone "ssh://git@gitlab/${USER}/${dev}"
            done
            ;;
        "fav")
            for fav in "${GIT_FAV[@]}"; do
                cd "${GITLAB}"
                git clone "ssh://git@gitlab/${USER}/${fav}"
            done
            ;;
        "prod")
            for prod in "${GIT_PROD[@]}"; do
                cd "${GITLAB}"
                git clone "ssh://git@gitlab/${USER}/${prod}"
            done
            ;;
    esac
}

check_git () {
    if [ ! -d "${GITLAB}"]
    then
        get-git
    fi
}

# Open project in VS Code
code () {
    check_git
    if [ ! -d "${GITLAB}${1}" ]
    then
        cd "${GITLAB}"
        git clone "ssh://git@gitlab/${USER}/${1}"
    fi
    exec code "${GITLAB}${1}"
}

# Install editor
editor () {
    # Install requirements
    sudo apt install -y shellcheck snapd git

    # Install VS Code
    sudo snap install code --classic

    # TODO: Clone ".vscode"
}

get-git () {
    # Install Git
    sudo apt install git

    # Global config
    git config --global user.name "${USER}"
    git config --global user.email "${EMAIL}"
    git config --global core.editor "${EDITOR}"
    git config --global url.ssh://git@gitlab/.insteadOf https://gitlab/

    # Create directories for Git
    if [ ! -d "${GITHUB}" ]
    then
        mkdir -p "${GITHUB}"
    fi

    if [ ! -d "${GITLAB}" ]
    then
        mkdir -p "${GITLAB}"
    fi
}

# Go to project directory
go () {
    check_git
    if [ ! -d "${GITLAB}${1}" ]
    then
        cd "${GITLAB}"
        git clone "ssh://git@gitlab/${USER}/${1}"
    fi
    cd "${GITLAB}${1}"
    exec bash
}

# Install IDE
ide () {
    # Install requirements
    sudo apt install -y snapd git python3 python3-pip python3-distutils
    pip3 install setuptools

    # Install PyCharm Community Edition
    sudo snap install pycharm-community --classic
}

# Base software and tools
soft () {
    sudo apt install -y ${SOFT}
}

venv () {
    # Install requirements
    sudo apt install -y build-essential libssl-dev libffi-dev python-dev
    sudo apt install -y python3-venv
    
    # Clone project if it is not present
    if [ ! -d "${GITLAB}$/ansible" ]
    then
        cd "${GITLAB}"
        git clone "ssh://git@gitlab/${USER}/ansible"
    fi

    # Create virtual enviroment for Ansible
    python3 -m venv "${GITLAB}"/ansible/venv

    cd "${GITLAB}"/ansible/venv

    # Install Ansible and suplements
    source bin/activate
    pip install --upgrade pip
    pip install ansible molecule docker
    deactivate

    # Add an alias to activate virtual enviroment
    echo -e "\nalias activate='source ${GITLAB}/ansible/venv/bin/activate'" >> ${HOME}/.bashrc
}


# ARGUMENTS ######################################
args=(
    all         # Deploy custom enviroment
    clone       # Clone a project
    group       # Clone a group of projects
    code        # Open project in VS Code
    editor      # Install VS Code
    get-git     # Install Git and set global configs
    go          # Go to project directory
    ide         # Install PyCharm
    soft        # Install base software and tools
    venv        # Create virtual enviroment
)

# TODO: Can for loop be used for every case?
case "$1" in
    "all")
    all
    ;;
    "clone")
    clone "$2"
    ;;
    "group")
    group "$2"
    ;;
    "code")
    code "$2"
    ;;
    "editor")
    editor
    ;;
    "get-git")
    get-git
    ;;
    "go")
    go "$2"
    ;;
    "ide")
    ide
    ;;
    "soft")
    soft
    ;;
    "venv")
    venv
    ;;
esac