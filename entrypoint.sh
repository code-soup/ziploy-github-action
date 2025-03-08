#!/bin/sh -l

# Load configuration from .ziployconfig file.
load_config() {
    CONFIG_FILE=".ziployconfig"

    if [ ! -f "$CONFIG_FILE" ]; then
        echo "$CONFIG_FILE not found" >&2
        exit 1
    fi

    while IFS="=" read -r key value; do
        key=$(echo "$key" | sed 's/ //g')
        value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        case "$key" in
            \#*|'') continue ;;
            id) ZIPLOY_ID="$value" ;;
            origin) ZIPLOY_ORIGIN="$value" ;;
            method) ZIPLOY_METHOD="$value" ;;
            ssh-host) ZIPLOY_SSH_HOST="$value" ;;
            ssh-user) ZIPLOY_SSH_USER="$value" ;;
            ssh-port) ZIPLOY_SSH_PORT="$value" ;;
            verbose) ZIPLOY_VERBOSE="$value" ;;
        esac
    done < "$CONFIG_FILE"
}


# Setup SSH directory: create .ssh folder, save private key and build known_hosts.
setup_ssh_dir() {
    if [ "$ZIPLOY_METHOD" = "SSH" ]; then
        # Create the SSH directory with secure permissions.
        SSH_PATH="${HOME}/.ssh"
        mkdir -p "${SSH_PATH}"
        chmod 700 "${SSH_PATH}"

        # Save the provided SSH key to a file.
        ZIPLOY_SSH_KEY_PATH="${SSH_PATH}/ziploy_id_ed25519"
        printf "%s\n" "$SSH_KEY" > "$ZIPLOY_SSH_KEY_PATH"
        chmod 600 "$ZIPLOY_SSH_KEY_PATH"

        if [ ! -s "$ZIPLOY_SSH_KEY_PATH" ]; then
            echo "❌ ERROR: SSH key file is empty or not created!" >&2
            exit 1
        fi

        # Create the known_hosts file by scanning for host keys (ed25519 and rsa).
        KNOWN_HOSTS_PATH="${SSH_PATH}/known_hosts"
        if [ -f "$KNOWN_HOSTS_PATH" ]; then
            rm "$KNOWN_HOSTS_PATH"
        fi

        ssh-keyscan -t ed25519,rsa "$ZIPLOY_SSH_HOST" >> "$KNOWN_HOSTS_PATH"
        chmod 644 "$KNOWN_HOSTS_PATH"

        # Start the ssh-agent and add the SSH key.
        export SSH_AUTH_SOCK="${SSH_PATH}/ssh-agent.sock"
        eval "$(ssh-agent -a ${SSH_AUTH_SOCK})"
        ssh-add "$ZIPLOY_SSH_KEY_PATH"
        
        # Append the SSH key and known_hosts paths to the configuration file.
        echo "ssh-key = ${ZIPLOY_SSH_KEY_PATH}" >> .ziployconfig
        echo "ssh-known-hosts = ${KNOWN_HOSTS_PATH}" >> .ziployconfig
    fi
}


# Download and run the Ziploy CLI.
run_ziploy() {
    url="https://raw.githubusercontent.com/code-soup/ziploy-cli/master/dist/x86_64/ziploy-cli"
    dest="ziploy-cli"
    
    if ! curl -fsSL -o "${dest}" "${url}"; then
        echo "Error: Failed to download Ziploy CLI" >&2
        return 1
    fi

    chmod u+x "${dest}"
    "./${dest}"
}


# Execute the steps.
load_config

setup_ssh_dir

run_ziploy
