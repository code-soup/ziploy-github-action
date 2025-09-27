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
            unique_id) ZIPLOY_ID="$value" ;;
            user) ZIPLOY_APP_USER="$value" ;;
            password) ZIPLOY_APP_PASS="$value" ;;
            origin) ZIPLOY_ORIGIN="$value" ;;
            verbose) ZIPLOY_VERBOSE="$value" ;;
            working-directory) ZIPLOY_WORKING_DIRECTORY="$value" ;;
        esac
    done < "$CONFIG_FILE"

    # Override username and password if provided via GitHub Actions (they take precedence)
    if [ -n "$ZIPLOY_WP_APP_USER" ]; then
        ZIPLOY_APP_USER="$ZIPLOY_WP_APP_USER"
    fi

    if [ -n "$ZIPLOY_WP_APP_PASS" ]; then
        ZIPLOY_APP_PASS="$ZIPLOY_WP_APP_PASS"
    fi
}

# Download and run the Ziploy CLI.
run_ziploy() {

    url="https://github.com/code-soup/ziploy-cli/raw/refs/heads/new/v2/dist/x86_64/ziploy-cli"
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

    # Build CLI arguments - only pass username and password as overrides
    CLI_ARGS=""

    # Add username if provided (from GitHub Actions)
    if [ -n "$ZIPLOY_WP_APP_USER" ]; then
        CLI_ARGS="$CLI_ARGS --user=$ZIPLOY_APP_USER"
    fi

    # Add password if provided (from GitHub Actions)
    if [ -n "$ZIPLOY_WP_APP_PASS" ]; then
        CLI_ARGS="$CLI_ARGS --password=$ZIPLOY_APP_PASS"
    fi

    # Execute the CLI binary with arguments.
    # The CLI will read other settings from .ziployconfig file
    echo "Running: ./${dest} $CLI_ARGS"
    stdbuf -oL "./${dest}" $CLI_ARGS
}


# Main execution: load configuration, setup SSH, and run the Ziploy CLI.
load_config
run_ziploy
