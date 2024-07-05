#!/bin/sh

# Function to display the logo animation
show_logo() {
    cat << "EOF"

        _|            _   _ |   _  _
__ |_| (_| )( .  \)/ (_) |  |( (- |  __

EOF
}

# Include utility functions, environment configuration, and authentication
. /usr/local/lib/utils.sh

# Display the logo animation
show_logo

nice_logs "info" "Here you go, welcome to UDX Worker Container."
nice_logs "info" "Init the environment..."

. /usr/local/lib/environment.sh

nice_logs "success" "Environment configuration completed."
