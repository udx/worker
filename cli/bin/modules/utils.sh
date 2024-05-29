declare -A colors
colors[error]='\033[0;31m'
colors[warning]='\033[1;33m'
colors[info]='\033[0;36m'
colors[success]='\033[0;32m'
colors[white]='\033[1;37m'
NC='\033[0m' # No Color

function loading_icon() {
    local load_interval="${1}"
    local loading_message="${2}"
    local elapsed=0
    local loading_animation=( '—' "\\" '|' '/' )
    
    message "success" "$loading_message"
    
    # This part is to make the cursor not blink
    # on top of the animation while it lasts
    tput civis
    trap "tput cnorm" EXIT
    limit=$(( load_interval - 1 ))
    while [ $elapsed -le $limit ]
    do
        for frame in "${loading_animation[@]}" ; do
            printf "%s\b" "${frame}"
            sleep 0.1
        done
        elapsed=$(( elapsed + 1 ))
    done
    printf " \b\n"
}

# Define a single function for all message types
message() {
    local type=$1
    local text=$2
    local arg=${3:-""}
    if [ "$arg" = "-n" ]; then
        printf "${colors[$type]}%s${NC}" "$text"
    else
        echo -e "${colors[$type]}$text${NC}"
    fi
}
