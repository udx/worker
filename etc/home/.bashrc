#!/bin/bash

# Colorful bash prompt configuration

# Get environment information
HOSTNAME=$(hostname)
USERNAME=$(whoami)

# Set current directory to dynamically update with the current path
# Using \w which is a bash prompt special character that shows the current directory
CURRENT_DIR="\w"

# Get Git environment variables if available
GIT_NAME=$(worker env show 2>/dev/null | grep GIT_NAME | awk -F'=' '{print $2}')
GIT_BRANCH=$(worker env show 2>/dev/null | grep GIT_BRANCH | awk -F'=' '{print $2}')

# Color codes for exact matching
USERNAME_COLOR="\[\033[38;5;11m\]"
HOST_COLOR="\[\033[38;5;11m\]"
PATH_COLOR="\[\033[38;5;10m\]"
PROMPT_COLOR="\[\033[38;5;11m\]"
RESET="\[\033[0m\]"

# Set the PS1 prompt
export PS1="${USERNAME_COLOR}${USERNAME}@${HOST_COLOR}${HOSTNAME} ${PATH_COLOR}${CURRENT_DIR} ${PROMPT_COLOR} \$${RESET} "

# Set LS_COLORS for directory listing colors
export LS_COLORS="di=34:ln=35:so=32:pi=33:ex=1;40:bd=34;40:cd=34;40:su=0;40:sg=0;40:tw=0;40:ow=0;40:"

# Add some useful aliases
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi