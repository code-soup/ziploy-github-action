#!/bin/sh -l

# Include validation script
validate_inputs() {
    ERRORS=""

    # Check required variables
    [ -z "$ZIPLOY_METHOD" ] && ERRORS="${ERRORS}\n❌ ZIPLOY_METHOD is required (Valid values: SSH, FTP, JWT)"
    [ -z "$ZIPLOY_ID" ] && ERRORS="${ERRORS}\n❌ ZIPLOY_ID is required"
    [ -z "$ZIPLOY_HOST" ] && ERRORS="${ERRORS}\n❌ ZIPLOY_HOST is required"
    
    # SSH-specific validations
    if [ "$ZIPLOY_METHOD" = "SSH" ]; then
        [ -z "$ZIPLOY_SSH_HOST" ] && ERRORS="${ERRORS}\n❌ ZIPLOY_SSH_HOST is required for SSH mode"
        [ -z "$ZIPLOY_SSH_USER" ] && ERRORS="${ERRORS}\n❌ ZIPLOY_SSH_USER is required for SSH mode"
        [ -z "$ZIPLOY_SSH_PORT" ] && ZIPLOY_SSH_PORT=22  # Default to 22 if not provided
        [ -z "$ZIPLOY_SSH_KEY" ] && ERRORS="${ERRORS}\n❌ ZIPLOY_SSH_KEY is required for SSH mode"
    fi

    # Validate ZIPLOY_METHOD values
    case "$ZIPLOY_METHOD" in
        SSH|FTP|JWT) ;;  # Valid values
        *) ERRORS="${ERRORS}\n❌ ZIPLOY_METHOD must be SSH, FTP, or JWT";;
    esac

    # Display errors and exit if any validation failed
    if [ -n "$ERRORS" ]; then
        echo -e "\n⚠️  INPUT VALIDATION FAILED ⚠️"
        echo -e "$ERRORS"
        exit 1
    fi
}

setup_env() {
    ZIPLOY_METHOD="${ZIPLOY_METHOD:-SSH}"
    ZIPLOY_ID="${ZIPLOY_ID}"
    ZIPLOY_HOST="${ZIPLOY_HOST}"
    
    if [ "$ZIPLOY_METHOD" = "SSH" ]; then
        SSH_HOST="${ZIPLOY_SSH_HOST}"
        SSH_USER="${ZIPLOY_SSH_USER}"
        SSH_PORT="${ZIPLOY_SSH_PORT:-22}"
        SSH_KEY="${ZIPLOY_SSH_KEY}"
    fi
}

setup_ssh_dir() {
    if [ "$ZIPLOY_METHOD" = "SSH" ]; then
        echo "Setting up SSH with Ed25519 Key"

        SSH_PATH="${HOME}/.ssh"
        mkdir -p "${SSH_PATH}"
        chmod 700 "${SSH_PATH}"

        ZIPLOY_SSH_KEY_PATH="${SSH_PATH}/ziploy_id_ed25519"
        # Write the provided SSH key to the file
        printf "%s\n" "$ZIPLOY_SSH_KEY" > "$ZIPLOY_SSH_KEY_PATH"
        chmod 600 "$ZIPLOY_SSH_KEY_PATH"

        if [ ! -s "$ZIPLOY_SSH_KEY_PATH" ]; then
            echo "❌ ERROR: SSH key file is empty or not created!"
            exit 1
        fi

        # Create known_hosts file in the same directory as the private key.
        KNOWN_HOSTS_PATH="${SSH_PATH}/known_hosts"
        # Remove any existing known_hosts
        if [ -f "$KNOWN_HOSTS_PATH" ]; then
            rm "$KNOWN_HOSTS_PATH"
            echo "Deleted existing known_hosts file at $KNOWN_HOSTS_PATH"
        fi
        # Run ssh-keyscan and write its output to known_hosts
        ssh-keyscan -t ed25519 "$ZIPLOY_SSH_HOST" >> "$KNOWN_HOSTS_PATH"
        chmod 644 "$KNOWN_HOSTS_PATH"
        echo "Created new known_hosts file at $KNOWN_HOSTS_PATH"

        # Start SSH agent
        export SSH_AUTH_SOCK="${SSH_PATH}/ssh-agent.sock"
        eval "$(ssh-agent -a ${SSH_AUTH_SOCK})"
        ssh-add "$ZIPLOY_SSH_KEY_PATH"

        # Test the SSH connection (this will also be optionally shown below)
        echo "Testing SSH connection..."
        ssh -o StrictHostKeyChecking=no -i "$ZIPLOY_SSH_KEY_PATH" -p "$SSH_PORT" "$SSH_USER@$SSH_HOST" "echo 'Connection Successful'" > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "❌ SSH connection test failed!"
            exit 1
        else
            echo "✅ SSH connection test succeeded."
        fi

        # If test mode is enabled, show the known_hosts file and exit
        if [ "$TEST_SSH" = "true" ]; then
            echo "----- Known Hosts File -----"
            cat "$KNOWN_HOSTS_PATH"
            echo "----------------------------"
            echo "Test SSH mode enabled. Exiting without running Ziploy."
            exit 0
        fi
    fi
}

run_ziploy() {
    # Download latest CLI
    curl -o ziploy-cli https://raw.githubusercontent.com/code-soup/ziploy-cli/master/dist/x86_64/ziploy-cli

    # Make executable
    chmod u+x ./ziploy-cli

    echo "✅ Running Ziploy with mode: ${ZIPLOY_METHOD}"

    if [ "$ZIPLOY_METHOD" = "SSH" ]; then
        # Run Ziploy CLI for SSH
        ./ziploy-cli "${ZIPLOY_METHOD}" "${ZIPLOY_ID}" "${ZIPLOY_HOST}" "${SSH_USER}" "${SSH_HOST}" "${SSH_PORT}" "${ZIPLOY_SSH_KEY_PATH}"
    
    elif [ "$ZIPLOY_METHOD" = "JWT" ]; then
        # Run Ziploy CLI for REST API (JWT Mode)
        ./ziploy-cli "${ZIPLOY_METHOD}" "${ZIPLOY_ID}" "${ZIPLOY_HOST}"

    elif [ "$ZIPLOY_METHOD" = "FTP" ]; then
        # Run Ziploy CLI for FTP
        ./ziploy-cli "${ZIPLOY_METHOD}" "${ZIPLOY_ID}" "${ZIPLOY_HOST}"
    fi
}

# Execute functions
validate_inputs    # Validate inputs first
setup_env
setup_ssh_dir
run_ziploy
