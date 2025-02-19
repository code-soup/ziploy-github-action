#!/bin/sh

validate_inputs() {
    ERRORS=""

    # Check required variables
    [ -z "$ZIPLOY_MODE" ] && ERRORS="${ERRORS}\n❌ ZIPLOY_MODE is required (Valid values: SSH, FTP, JWT)"
    [ -z "$ZIPLOY_ID" ] && ERRORS="${ERRORS}\n❌ ZIPLOY_ID is required"
    [ -z "$ZIPLOY_HOST" ] && ERRORS="${ERRORS}\n❌ ZIPLOY_HOST is required"
    
    # SSH-specific validations
    if [ "$ZIPLOY_MODE" = "SSH" ]; then
        [ -z "$ZIPLOY_SSH_HOST" ] && ERRORS="${ERRORS}\n❌ ZIPLOY_SSH_HOST is required for SSH mode"
        [ -z "$ZIPLOY_SSH_USER" ] && ERRORS="${ERRORS}\n❌ ZIPLOY_SSH_USER is required for SSH mode"
        [ -z "$ZIPLOY_SSH_PORT" ] && ZIPLOY_SSH_PORT=22  # Default to 22 if not provided
        [ -z "$ZIPLOY_SSH_KEY" ] && ERRORS="${ERRORS}\n❌ ZIPLOY_SSH_KEY is required for SSH mode"
    fi

    # Validate ZIPLOY_MODE values
    case "$ZIPLOY_MODE" in
        SSH|FTP|JWT) ;;  # Valid values
        *) ERRORS="${ERRORS}\n❌ ZIPLOY_MODE must be SSH, FTP, or JWT";;
    esac

    # Display errors and exit if any validation failed
    if [ -n "$ERRORS" ]; then
        echo -e "\n⚠️  INPUT VALIDATION FAILED ⚠️"
        echo -e "$ERRORS"
        exit 1
    fi
}