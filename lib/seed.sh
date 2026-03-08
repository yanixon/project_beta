# lib/seed.sh — source this file, do not execute directly

run_seed() {
    local seed_cmd="${APP_SEED_COMMAND:-seed_data}"

    echo "Running database seed command '$seed_cmd'..."

    run_ssh "
        set -a && source ${SHARED_DIR}/env/.env && set +a
        if ${SHARED_DIR}/venv/bin/python ${CURRENT_LINK}/manage.py help ${seed_cmd} >/dev/null 2>&1; then
            ${SHARED_DIR}/venv/bin/python ${CURRENT_LINK}/manage.py ${seed_cmd} \
                --settings=${APP_DJANGO_SETTINGS}
        else
            echo \"Seed command '${seed_cmd}' not found. Skipping database seeding.\"
        fi
    "

    if [[ $? -ne 0 ]]; then
        echo "Database seeding failed on server." >&2
        return 1
    fi
}
