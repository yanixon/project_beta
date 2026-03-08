# lib/validate.sh — source this file, do not execute directly

validate_project() {
    local errors=0

    # Check 1 — deploy.yml exists
    if [[ ! -f deploy.yml ]]; then
        echo "deploy.yml not found in current directory. Create one from the template (see deploy.yml.template)." >&2
        ((errors++))
    fi

    # Check 2 — Required fields present
    local -A field_map=(
        [project_name]=PROJECT_NAME
        [repo_url]=REPO_URL
        [repo_branch]=REPO_BRANCH
        [server.host]=SERVER_HOST
        [server.user]=SERVER_USER
        [server.ssh_key]=SERVER_SSH_KEY
        [server.base_dir]=SERVER_BASE_DIR
        [app.django_settings]=APP_DJANGO_SETTINGS
        [app.db_name]=APP_DB_NAME
        [app.db_user]=APP_DB_USER
        [app.python_version]=APP_PYTHON_VERSION
        [gunicorn.socket]=GUNICORN_SOCKET
        [gunicorn.workers]=GUNICORN_WORKERS
        [gunicorn.timeout]=GUNICORN_TIMEOUT
        [nginx.server_name]=NGINX_SERVER_NAME
        [database.init_mode]=DATABASE_INIT_MODE
    )
    local field_path var_name
    for field_path in "${!field_map[@]}"; do
        var_name="${field_map[$field_path]}"
        if [[ -z "${!var_name}" ]]; then
            echo "deploy.yml missing required field: $field_path" >&2
            ((errors++))
        fi
    done

    # Check 3 — manage.py exists
    if [[ ! -f manage.py ]]; then
        echo "manage.py not found in current directory." >&2
        ((errors++))
    fi

    # Check 4 — requirements.txt or pyproject.toml exists
    if [[ ! -f requirements.txt ]] && [[ ! -f pyproject.toml ]]; then
        echo "Neither requirements.txt nor pyproject.toml found in current directory." >&2
        ((errors++))
    fi

    # Check 5 — Settings file exists
    if [[ ! -f "$SETTINGS_FILE_PATH" ]]; then
        echo "Production settings module not found at $SETTINGS_FILE_PATH (from app.django_settings: $APP_DJANGO_SETTINGS)." >&2
        ((errors++))
    fi

    # Check 6 — WSGI file exists
    if [[ ! -f "$WSGI_FILE_PATH" ]]; then
        echo "WSGI module not found at $WSGI_FILE_PATH (derived from app.django_settings: $APP_DJANGO_SETTINGS)." >&2
        ((errors++))
    fi

    # Check 7 — SSH key exists
    if [[ ! -f "$SERVER_SSH_KEY" ]]; then
        echo "SSH key not found at $SERVER_SSH_KEY (from server.ssh_key)." >&2
        ((errors++))
    fi

    # Check 8 — .git/ directory exists
    if [[ ! -d .git ]]; then
        echo "No git repository found. Run 'git init' and commit your code first." >&2
        ((errors++))
    fi

    # Check 9 — Git remote matches repo_url (normalize SSH and HTTPS formats before comparing)
    _normalize_git_url() {
        echo "$1" | sed -e 's|.*github.com[:/]||' -e 's|\.git$||'
    }
    local normalized_repo_url
    normalized_repo_url=$(_normalize_git_url "$REPO_URL")
    local remote_match=0
    while IFS= read -r remote_line; do
        local remote_url
        remote_url=$(echo "$remote_line" | awk '{print $2}')
        if [[ "$(_normalize_git_url "$remote_url")" == "$normalized_repo_url" ]]; then
            remote_match=1
            break
        fi
    done < <(git remote -v 2>/dev/null)
    if [[ $remote_match -eq 0 ]]; then
        echo "No git remote matches repo_url '$REPO_URL' from deploy.yml. Add it with 'git remote add origin $REPO_URL'." >&2
        ((errors++))
    fi

    return $errors
}
