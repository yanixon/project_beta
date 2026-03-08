# lib/static.sh — source this file, do not execute directly

collect_static() {
    echo "Collecting static files..."

    run_ssh "
        set -a && source ${SHARED_DIR}/env/.env && set +a
        ${SHARED_DIR}/venv/bin/python ${CURRENT_LINK}/manage.py collectstatic \
            --settings=${APP_DJANGO_SETTINGS} \
            --noinput
    "

    if [[ $? -ne 0 ]]; then
        echo "Failed to collect static files on server." >&2
        return 1
    fi

    echo "Static files collected."
}
