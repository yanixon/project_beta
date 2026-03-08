# lib/yaml_parse.sh — source this file, do not execute directly

parse_deploy_yml() {
    local yaml_file="$1"

    if [[ ! -f "$yaml_file" ]]; then
        echo "Error: YAML file not found: $yaml_file" >&2
        return 1
    fi

    # Initialize all variables to empty string
    PROJECT_NAME=""
    REPO_URL=""
    REPO_BRANCH=""
    SERVER_HOST=""
    SERVER_USER=""
    SERVER_SSH_KEY=""
    SERVER_BASE_DIR=""
    APP_DJANGO_SETTINGS=""
    APP_DB_NAME=""
    APP_DB_USER=""
    APP_PYTHON_VERSION=""
    APP_URL_PREFIX=""
    GUNICORN_SOCKET=""
    GUNICORN_WORKERS=""
    GUNICORN_TIMEOUT=""
    NGINX_SERVER_NAME=""
    DATABASE_INIT_MODE=""

    # Parse YAML using awk: flatten 2-level YAML to SECTION_KEY=value lines
    while IFS='=' read -r key value; do
        printf -v "$key" '%s' "$value"
    done < <(awk '
        /^[[:space:]]*$/ { next }
        /^[[:space:]]*#/ { next }
        /^[[:alpha:]][^:]*:[[:space:]]*$/ {
            gsub(/:.*/, "", $0)
            gsub(/[[:space:]]/, "", $0)
            section = toupper($0)
            next
        }
        /^[[:alpha:]][^:]*:/ {
            split($0, parts, /:[[:space:]]*/)
            key = parts[1]
            value = substr($0, index($0, ":") + 1)
            gsub(/^[[:space:]]+/, "", value)
            gsub(/[[:space:]]+$/, "", value)
            gsub(/^["'"'"']|["'"'"']$/, "", value)
            varname = toupper(key)
            gsub(/-/, "_", varname)
            print varname "=" value
            next
        }
        /^[[:space:]]+[[:alpha:]][^:]*:/ {
            gsub(/^[[:space:]]+/, "", $0)
            split($0, parts, /:[[:space:]]*/)
            key = parts[1]
            value = substr($0, index($0, ":") + 1)
            gsub(/^[[:space:]]+/, "", value)
            gsub(/[[:space:]]+$/, "", value)
            gsub(/^["'"'"']|["'"'"']$/, "", value)
            varname = section "_" toupper(key)
            gsub(/-/, "_", varname)
            print varname "=" value
            next
        }
    ' "$yaml_file")

    # Apply tilde expansion to SERVER_SSH_KEY
    SERVER_SSH_KEY="${SERVER_SSH_KEY/#\~/$HOME}"

    # Compute derived variables
    WSGI_MODULE="${APP_DJANGO_SETTINGS%%.*}.wsgi"
    SETTINGS_FILE_PATH="$(echo "$APP_DJANGO_SETTINGS" | tr '.' '/').py"
    WSGI_FILE_PATH="$(echo "$WSGI_MODULE" | tr '.' '/').py"
    PROJECT_DIR="${SERVER_BASE_DIR}/${PROJECT_NAME}"
    RELEASES_DIR="${PROJECT_DIR}/releases"
    SHARED_DIR="${PROJECT_DIR}/shared"
    CURRENT_LINK="${PROJECT_DIR}/current"
}
