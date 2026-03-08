# lib/env_file.sh — source this file, do not execute directly

generate_env_file() {
    echo "Generating environment file..."

    run_ssh "
        # Preserve existing SECRET_KEY and DB_PASSWORD if .env already exists
        if [[ -f ${SHARED_DIR}/env/.env ]]; then
            existing_secret_key=\$(grep '^SECRET_KEY=' ${SHARED_DIR}/env/.env | cut -d= -f2-)
            existing_db_password=\$(grep '^DATABASE_URL=' ${SHARED_DIR}/env/.env | sed 's|.*://[^:]*:\([^@]*\)@.*|\1|')
        fi

        # Generate new values only if not preserved
        if [[ -z \"\$existing_secret_key\" ]]; then
            existing_secret_key=\$(python3 -c \"import secrets; print(secrets.token_urlsafe(50))\")
        fi

        if [[ -z \"\$existing_db_password\" ]]; then
            # Generate a password that's already URL-safe (alphanumeric only)
            existing_db_password=\$(python3 -c \"import secrets; print(secrets.token_hex(16))\")
        fi

        # Write .env file
        cat > ${SHARED_DIR}/env/.env <<'ENVEOF'
DJANGO_SETTINGS_MODULE=${APP_DJANGO_SETTINGS}
DATABASE_URL=postgres://${APP_DB_USER}:\$existing_db_password@localhost:5432/${APP_DB_NAME}
ALLOWED_HOSTS=${NGINX_SERVER_NAME}
STATIC_ROOT=${SHARED_DIR}/static
SECRET_KEY=\$existing_secret_key
ENVEOF

        # Now use sed to substitute the remote variables
        sed -i \"s|\\\$existing_db_password|\$existing_db_password|g\" ${SHARED_DIR}/env/.env
        sed -i \"s|\\\$existing_secret_key|\$existing_secret_key|g\" ${SHARED_DIR}/env/.env

        # Symlink .env into current release
        ln -sf ${SHARED_DIR}/env/.env ${CURRENT_LINK}/.env
    "

    if [[ $? -ne 0 ]]; then
        echo "Failed to generate environment file on server." >&2
        return 1
    fi

    echo "Environment file ready."
}
