#!/bin/sh -l

# Load configuration from the .ziployconfig file.
# If ZIPLOY_WORKING_DIRECTORY is set, the script uses the .ziployconfig file within that directory
# and prepends the "working-directory" key (with a new line) to the configuration file before loading it.
load_config() {
    if [ -n "$ZIPLOY_WORKING_DIRECTORY" ]; then
        # Remove any leading and trailing slashes from ZIPLOY_WORKING_DIRECTORY inline.
        STRIPPED_WORKING_DIRECTORY=$(echo "$ZIPLOY_WORKING_DIRECTORY" | sed 's|^/*||; s|/*$||')
        CONFIG_FILE="${STRIPPED_WORKING_DIRECTORY}/.ziployconfig"

        # Append the working-directory key (followed by a new line) to the config file.
        # printf "\nworking-directory = %s\n" "$STRIPPED_WORKING_DIRECTORY" >> "$CONFIG_FILE"
    else
        CONFIG_FILE=".ziployconfig"
    fi

    if [ ! -f "$CONFIG_FILE" ]; then
        echo "$CONFIG_FILE not found" >&2
        exit 1
    fi

    # Read and parse the configuration file line by line.
    while IFS="=" read -r key value; do
        # Remove spaces from the key.
        key=$(echo "$key" | sed 's/ //g')
        # Trim leading and trailing whitespace from the value.
        value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        case "$key" in
            \#*|'') continue ;;  # Skip comments and empty lines.
            id) ZIPLOY_ID="$value" ;;
            origin) ZIPLOY_ORIGIN="$value" ;;
            method) ZIPLOY_METHOD="$value" ;;
            ssh-host) ZIPLOY_SSH_HOST="$value" ;;
            ssh-user) ZIPLOY_SSH_USER="$value" ;;
            ssh-port) ZIPLOY_SSH_PORT="$value" ;;
            verbose) ZIPLOY_VERBOSE="$value" ;;
            working-directory) ZIPLOY_WORKING_DIRECTORY="$value" ;;
        esac
    done < "$CONFIG_FILE"
}

# Setup SSH directory by creating the .ssh folder, installing the provided key, and generating the known_hosts file.
setup_ssh_dir() {
    # Only proceed if the deployment method is SSH.
    if [ "$ZIPLOY_METHOD" = "SSH" ]; then
        # Define the SSH directory path.
        SSH_PATH="${HOME}/.ssh"
        mkdir -p "${SSH_PATH}"
        chmod 700 "${SSH_PATH}"

        # DEBUG: print the SSH directory path.
        # echo "SSH_PATH: ${SSH_PATH}"

        # Define the file path for the SSH private key.
        ZIPLOY_SSH_KEY_PATH="${SSH_PATH}/ziploy_id_ed25519"
        # Write the SSH key to the file; remove any carriage returns (CR) for compatibility.
        printf "%s\n" "$ZIPLOY_SSH_KEY" | sed 's/\r//g' > "$ZIPLOY_SSH_KEY_PATH"
        chmod 600 "$ZIPLOY_SSH_KEY_PATH"

        # Verify that the SSH key file was successfully created and is not empty.
        if [ ! -s "$ZIPLOY_SSH_KEY_PATH" ]; then
            echo "❌ ERROR: SSH key file is empty or not created!" >&2
            exit 1
        fi

        # Define the path for the known_hosts file.
        KNOWN_HOSTS_PATH="${SSH_PATH}/known_hosts"
        # Remove the known_hosts file if it already exists.
        [ -f "$KNOWN_HOSTS_PATH" ] && rm "$KNOWN_HOSTS_PATH"

        # Use ssh-keyscan to obtain the host keys (ed25519 and rsa) for the target SSH host.
        ssh-keyscan -t ed25519,rsa "$ZIPLOY_SSH_HOST" >> "$KNOWN_HOSTS_PATH"
        chmod 644 "$KNOWN_HOSTS_PATH"

        # Start the ssh-agent with a specific socket and add the SSH key.
        export SSH_AUTH_SOCK="${SSH_PATH}/ssh-agent.sock"
        eval "$(ssh-agent -a ${SSH_AUTH_SOCK})"
        ssh-add "$ZIPLOY_SSH_KEY_PATH"
        
        # Append the SSH key and known_hosts file paths to the configuration file.
        printf "\nssh-key = %s\n" "$ZIPLOY_SSH_KEY_PATH" >> "$CONFIG_FILE"
        printf "\nssh-known-hosts = %s\n" "$KNOWN_HOSTS_PATH" >> "$CONFIG_FILE"
    fi
}

# Download and run the Ziploy CLI.
run_ziploy() {

    url="https://raw.githubusercontent.com/code-soup/ziploy-cli/master/dist/x86_64/ziploy-cli"
    dest="ziploy-cli"

    # If ZIPLOY_WORKING_DIRECTORY is set, change into that directory.
    if [ -n "$ZIPLOY_WORKING_DIRECTORY" ]; then
        cd "$ZIPLOY_WORKING_DIRECTORY" || { 
            echo "Error: Failed to change directory to $ZIPLOY_WORKING_DIRECTORY" >&2 
            return 1
        }
    fi
    
    # Download the CLI binary using curl.
    if ! curl -fsSL -o "${dest}" "${url}"; then
        echo "Error: Failed to download Ziploy CLI" >&2
        return 1
    fi

    # Make the downloaded binary executable.
    chmod u+x "${dest}"
    
    echo "Deploying code. This can take few minutes, please wait."

    # Execute the CLI binary.
    stdbuf -oL "./${dest}"
}


# Main execution: load configuration, setup SSH, and run the Ziploy CLI.
load_config
setup_ssh_dir
run_ziploy
