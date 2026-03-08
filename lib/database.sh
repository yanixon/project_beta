# lib/database.sh — source this file, do not execute directly

provision_database() {
    echo "Provisioning PostgreSQL database..."

    run_ssh "
        # Read DB_PASSWORD from .env
        db_password=\$(grep '^DATABASE_URL=' ${SHARED_DIR}/env/.env | sed 's|.*://[^:]*:\([^@]*\)@.*|\1|')

        # Create role if it does not exist
        if ! sudo -u postgres psql -tAc \"SELECT 1 FROM pg_roles WHERE rolname='${APP_DB_USER}'\" | grep -q 1; then
            sudo -u postgres psql -c \"CREATE ROLE ${APP_DB_USER} WITH LOGIN PASSWORD '\${db_password}';\"
        fi

        # Create database if it does not exist
        if ! sudo -u postgres psql -tAc \"SELECT 1 FROM pg_database WHERE datname='${APP_DB_NAME}'\" | grep -q 1; then
            sudo -u postgres psql -c \"CREATE DATABASE ${APP_DB_NAME} OWNER ${APP_DB_USER};\"
        fi
    "

    if [[ $? -ne 0 ]]; then
        echo "Failed to provision PostgreSQL database on server." >&2
        return 1
    fi

    echo "Database ready."
}

run_migrations() {
    echo "Running database migrations..."

    run_ssh "
        set -a && source ${SHARED_DIR}/env/.env && set +a
        ${SHARED_DIR}/venv/bin/python ${CURRENT_LINK}/manage.py migrate \
            --settings=${APP_DJANGO_SETTINGS} \
            --noinput
    "

    if [[ $? -ne 0 ]]; then
        echo "Failed to run database migrations on server." >&2
        return 1
    fi

    echo "Migrations complete."
}
