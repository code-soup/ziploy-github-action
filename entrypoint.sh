#!/bin/sh -l

# Include validation script
. /utils/validate.sh

# Download latest CLI
curl -o ziploy https://raw.githubusercontent.com/code-soup/ziploy-cli/master/ziploy

# Make executable
chmod u+x ./ziploy

setup_env() {
    ZIPLOY_MODE="${ZIPLOY_MODE:-SSH}"
    ZIPLOY_ID="${ZIPLOY_ID}"
    ZIPLOY_HOST="${ZIPLOY_HOST}"
    
    if [ "$ZIPLOY_MODE" = "SSH" ]; then
        SSH_HOST="${ZIPLOY_SSH_HOST}"
        SSH_USER="${ZIPLOY_SSH_USER}"
        SSH_PORT="${ZIPLOY_SSH_PORT:-22}"
        SSH_KEY="${ZIPLOY_SSH_KEY}"
    fi
}

setup_ssh_dir() {
    if [ "$ZIPLOY_MODE" = "SSH" ]; then
        echo "Setting up SSH"

        SSH_PATH="${HOME}/.ssh"

        # Create SSH directory if not exists
        if [ ! -d "${SSH_PATH}" ]; then
            mkdir -p "${SSH_PATH}/ctl/"
            chmod 700 "${SSH_PATH}"
        fi

        # Copy secret key to container
        ZIPLOY_SSH_KEY_PATH="${SSH_PATH}/ziploy_id_rsa"
        umask 077
        echo "${SSH_KEY}" > "${ZIPLOY_SSH_KEY_PATH}"
        chmod 600 "${ZIPLOY_SSH_KEY_PATH}"

        # Establish known_hosts
        KNOWN_HOSTS_PATH="${SSH_PATH}/known_hosts"
        ssh-keyscan -t rsa "${SSH_HOST}" >> "${KNOWN_HOSTS_PATH}"
        chmod 644 "${KNOWN_HOSTS_PATH}"

        # Configure SSH for key-based authentication
        export SSH_AUTH_SOCK="${SSH_PATH}/ssh-agent.sock"
        eval "$(ssh-agent -a ${SSH_AUTH_SOCK})"
        ssh-add "${ZIPLOY_SSH_KEY_PATH}"
    fi
}

run_ziploy() {
    echo "✅ Running Ziploy with mode: ${ZIPLOY_MODE}"

    if [ "$ZIPLOY_MODE" = "SSH" ]; then
        # Construct SSH connection string
        SSH_CONNECTION="${SSH_USER}@${SSH_HOST} -p ${SSH_PORT}"

        # Run Ziploy CLI for SSH
        ./ziploy "${ZIPLOY_MODE}" "${ZIPLOY_ID}" "${SSH_CONNECTION}" "${ZIPLOY_SSH_KEY_PATH}"
    
    elif [ "$ZIPLOY_MODE" = "JWT" ]; then
        # Run Ziploy CLI for REST API (JWT Mode)
        ./ziploy "${ZIPLOY_MODE}" "${ZIPLOY_ID}" "${ZIPLOY_HOST}"

    elif [ "$ZIPLOY_MODE" = "FTP" ]; then
        # Run Ziploy CLI for FTP
        ./ziploy "${ZIPLOY_MODE}" "${ZIPLOY_ID}" "${ZIPLOY_HOST}"
    fi
}

# Execute functions
validate_inputs  # Validate inputs first
setup_env
setup_ssh_dir
run_ziploy