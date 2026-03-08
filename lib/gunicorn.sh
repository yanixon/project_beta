# lib/gunicorn.sh — source this file, do not execute directly

configure_gunicorn() {
    echo "Configuring Gunicorn systemd service..."

    run_ssh "
        cat > /etc/systemd/system/gunicorn-${PROJECT_NAME}.service << 'EOF'
[Unit]
Description=Gunicorn daemon for ${PROJECT_NAME}
After=network.target

[Service]
Type=notify
User=root
Group=www-data
WorkingDirectory=${CURRENT_LINK}
EnvironmentFile=${SHARED_DIR}/env/.env
ExecStart=${SHARED_DIR}/venv/bin/gunicorn ${WSGI_MODULE}:application \
    --workers ${GUNICORN_WORKERS} \
    --bind unix:${GUNICORN_SOCKET} \
    --timeout ${GUNICORN_TIMEOUT} \
    --access-logfile - \
    --error-logfile -
ExecReload=/bin/kill -s HUP \$MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
    "

    if [[ $? -ne 0 ]]; then
        echo "Failed to write gunicorn-${PROJECT_NAME}.service unit file." >&2
        return 1
    fi

    run_ssh "systemctl daemon-reload"

    if [[ $? -ne 0 ]]; then
        echo "systemctl daemon-reload failed." >&2
        return 1
    fi

    run_ssh "systemctl enable gunicorn-${PROJECT_NAME}"

    if [[ $? -ne 0 ]]; then
        echo "Failed to enable gunicorn-${PROJECT_NAME}." >&2
        return 1
    fi

    run_ssh "systemctl restart gunicorn-${PROJECT_NAME}"

    if [[ $? -ne 0 ]]; then
        echo "Failed to restart gunicorn-${PROJECT_NAME}." >&2
        return 1
    fi

    if ! run_ssh "systemctl is-active gunicorn-${PROJECT_NAME}"; then
        echo "gunicorn-${PROJECT_NAME} is not active after restart." >&2
        return 1
    fi

    echo "Gunicorn service gunicorn-${PROJECT_NAME} is active."
}
