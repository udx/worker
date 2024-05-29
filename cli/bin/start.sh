# Resolve the directory of this script
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Source the utils.sh script using the resolved path and ensure it's executed with bash
source "$SCRIPT_DIR/modules/utils.sh"

# Check if dialog is installed
if ! command -v dialog &> /dev/null
then
    echo "Dialog is not installed. Attempting to install..."
    case "$(uname -s)" in
        Darwin)
            if ! command -v brew &> /dev/null
            then
                echo "Homebrew is not installed. Please install Homebrew and then run this script again."
                exit 1
            fi
            brew install dialog || { echo "Failed to install dialog. Please install it manually and then run this script again."; exit 1; }
        ;;
        Linux)
            if ! command -v apt-get &> /dev/null
            then
                echo "apt-get is not available. Please install dialog manually and then run this script again."
                exit 1
            fi
            sudo apt-get update && sudo apt-get install -y dialog || { echo "Failed to install dialog. Please install it manually and then run this script again."; exit 1; }
        ;;
        CYGWIN*|MINGW32*|MSYS*|MINGW*)
            echo "Dialog is not supported on Windows. Please run this script on a Unix-based system or install a Unix-like environment such as Cygwin or WSL."
            exit 1
        ;;
        *)
            echo "Unsupported platform. Please install dialog manually and then run this script again."
            exit 1
        ;;
    esac
fi

loading_icon 1 "."
loading_icon 1 ".."
loading_icon 1 "..."

function start_interface() {
    HEIGHT=15
    WIDTH=40
    CHOICE_HEIGHT=4
    BACKTITLE="UDX Worker CLI"
    TITLE="UDX Worker"
    MENU="Please select the interface you want to use:"

    OPTIONS=(1 "Visual Studio Code"
             2 "CLI Terminal"
             3 "GitHub Action"
             4 "Azure DevOps")

    CHOICE=$(dialog --clear \
                    --backtitle "$BACKTITLE" \
                    --title "$TITLE" \
                    --menu "$MENU" \
                    $HEIGHT $WIDTH $CHOICE_HEIGHT \
                    "${OPTIONS[@]}" \
                    2>&1 >/dev/tty)

    clear
    case $CHOICE in
        1)
            case "$(uname -s)" in
                Darwin)
                    open -a "Visual Studio Code" "${1:-.}"
                    message "success" "Visual Studio Code has been opened."
                ;;
                Linux)
                    code "${1:-.}"
                    message "success" "Visual Studio Code has been opened."
                ;;
                CYGWIN*|MINGW32*|MSYS*|MINGW*)
                    start code "${1:-.}"
                    message "success" "Visual Studio Code has been opened."
                ;;
                *)
                    message "error" "unsupported platform"
                ;;
            esac
        ;;
        2)
            source "$SCRIPT_DIR/help.sh"
            message "success" "CLI Terminal has been opened."
        ;;
        3)
            echo "echo '##[set-env name=WORKSPACE;value=${1:-.}]'"
            message "success" "GitHub Action has been set."
        ;;
        4)
            echo "echo '##vso[task.setvariable variable=workspace]${1:-.}'"
            message "success" "Azure DevOps variable has been set."
        ;;
        *)
            message "error" "unsupported interface"
        ;;
    esac
}

########
#      #
# Logo #
#      #
########

# Define the logo string
str=$'
        _|            _   _ |   _  _ 
__ |_| (_| )( .  \)/ (_) |  |( (- |  __
\n'

# Print the logo with a delay after each character
for (( i=0; i<${#str}; i++ )); do
  message "success" "${str:$i:1}" "-n"
  # Add a pause only if the current character is not a space or newline
  if [[ "${str:$i:1}" != " " && "${str:$i:1}" != $'\n' ]]; then
    sleep 0.01
  fi
done

sleep 1

start_interface "../udx-worker.ipynb"
