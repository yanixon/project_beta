# lib/health.sh — source this file, do not execute directly

run_health_checks() {
    local url_prefix
    if [[ -n "$APP_URL_PREFIX" ]]; then
        url_prefix="$APP_URL_PREFIX"
    else
        url_prefix="${PROJECT_NAME#project_}"
    fi

    echo "Running health checks..."

    # Check 1 — Gunicorn service active
    local service_status
    service_status=$(run_ssh "systemctl is-active gunicorn-${PROJECT_NAME}" 2>/dev/null || true)
    if [[ "$service_status" == "active" ]]; then
        echo "  [PASS] Gunicorn service gunicorn-${PROJECT_NAME} is active"
    else
        echo "  [FAIL] Gunicorn service gunicorn-${PROJECT_NAME} is not active (status: ${service_status})"
    fi

    # Check 2 — HTTP responds (not 5xx)
    local http_code
    http_code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "http://${SERVER_HOST}/${url_prefix}/" 2>/dev/null || true)
    if [[ "${http_code:0:1}" != "5" ]] && [[ -n "$http_code" ]]; then
        echo "  [PASS] HTTP response code ${http_code} from http://${SERVER_HOST}/${url_prefix}/"
    else
        echo "  [FAIL] HTTP response code ${http_code} from http://${SERVER_HOST}/${url_prefix}/"
    fi

    # Check 3 — Database connected
    local db_check_output
    db_check_output=$(run_ssh "
        set -a && source ${SHARED_DIR}/env/.env && set +a
        ${SHARED_DIR}/venv/bin/python ${CURRENT_LINK}/manage.py check --database default \
            --settings=${APP_DJANGO_SETTINGS} 2>&1
    " 2>/dev/null || true)
    if echo "$db_check_output" | grep -q "System check identified no issues"; then
        echo "  [PASS] Database connection check passed"
    else
        echo "  [FAIL] Database connection check failed"
    fi
}
