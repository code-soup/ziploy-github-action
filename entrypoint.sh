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
        # Use printf to correctly preserve key formatting and newlines
        printf "%s\n" "$ZIPLOY_SSH_KEY" > "$ZIPLOY_SSH_KEY_PATH"
        chmod 600 "$ZIPLOY_SSH_KEY_PATH"

        if [ ! -s "$ZIPLOY_SSH_KEY_PATH" ]; then
            echo "❌ ERROR: SSH key file is empty or not created!"
            exit 1
        fi

        KNOWN_HOSTS_PATH="${SSH_PATH}/known_hosts"
        # Scan and add the host key for the remote host to avoid host key verification issues
        ssh-keyscan -t ed25519 "$ZIPLOY_SSH_HOST" >> "$KNOWN_HOSTS_PATH" 2>/dev/null
        chmod 644 "$KNOWN_HOSTS_PATH"

        # Optionally, create an SSH config file to disable strict host key checking globally
        CONFIG_PATH="${SSH_PATH}/config"
        cat > "$CONFIG_PATH" <<EOF
Host *
    StrictHostKeyChecking no
EOF
        chmod 600 "$CONFIG_PATH"

        # Start ssh-agent and add the SSH key
        export SSH_AUTH_SOCK="${SSH_PATH}/ssh-agent.sock"
        eval "$(ssh-agent -a "${SSH_AUTH_SOCK}")"
        ssh-add "$ZIPLOY_SSH_KEY_PATH"
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
validate_inputs  # Validate inputs first
setup_env
setup_ssh_dir
run_ziploy