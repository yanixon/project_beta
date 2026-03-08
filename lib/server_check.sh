# lib/server_check.sh — source this file, do not execute directly

run_ssh() {
    ssh -i "$SERVER_SSH_KEY" \
        -o StrictHostKeyChecking=accept-new \
        "$SERVER_USER@$SERVER_HOST" \
        "$@"
}

test_ssh_connection() {
    if ! ssh -i "$SERVER_SSH_KEY" \
            -o ConnectTimeout=10 \
            -o BatchMode=yes \
            -o StrictHostKeyChecking=accept-new \
            "$SERVER_USER@$SERVER_HOST" \
            "exit 0" 2>/dev/null; then
        echo "Cannot connect to $SERVER_HOST via SSH. Check server.host and server.ssh_key in deploy.yml." >&2
        return 1
    fi
}

validate_server_software() {
    local python_bin="python${APP_PYTHON_VERSION}"
    local missing
    missing=$(run_ssh "
        missing=\"\"
        command -v $python_bin >/dev/null 2>&1 || missing=\"\${missing:+\$missing, }Python $APP_PYTHON_VERSION ($python_bin)\"
        command -v psql >/dev/null 2>&1 || missing=\"\${missing:+\$missing, }PostgreSQL (psql)\"
        command -v nginx >/dev/null 2>&1 || missing=\"\${missing:+\$missing, }Nginx (nginx)\"
        command -v systemctl >/dev/null 2>&1 || missing=\"\${missing:+\$missing, }systemd (systemctl)\"
        echo \"\$missing\"
    ")

    missing=$(echo "$missing" | xargs)  # trim leading/trailing whitespace

    if [[ -n "$missing" ]]; then
        echo "Server is missing required software: $missing" >&2
        return 1
    fi
}
