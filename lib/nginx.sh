# lib/nginx.sh — source this file, do not execute directly

configure_nginx() {
    echo "Configuring Nginx..."

    local url_prefix
    if [[ -n "$APP_URL_PREFIX" ]]; then
        url_prefix="$APP_URL_PREFIX"
    else
        url_prefix="${PROJECT_NAME#project_}"
    fi

    run_ssh "
        # Create per-project locations directory if it doesn't exist
        mkdir -p /etc/nginx/sites-available/project-locations

        # Write per-project location block
        cat > /etc/nginx/sites-available/project-locations/${PROJECT_NAME}.conf << 'NGINXCONF'
location /${url_prefix}/ {
    proxy_pass http://unix:${GUNICORN_SOCKET};
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header SCRIPT_NAME /${url_prefix};
}

location /${url_prefix}/static/ {
    alias ${SHARED_DIR}/static/;
}
NGINXCONF

        # Create main server block if it doesn't exist
        if [[ ! -f /etc/nginx/sites-available/django-apps ]]; then
            cat > /etc/nginx/sites-available/django-apps << 'SERVERBLOCK'
server {
    listen 80;
    server_name ${NGINX_SERVER_NAME};
    include /etc/nginx/sites-available/project-locations/*.conf;
}
SERVERBLOCK
        fi

        # Symlink to sites-enabled
        ln -sf /etc/nginx/sites-available/django-apps /etc/nginx/sites-enabled/

        # Remove default nginx site if it exists
        rm -f /etc/nginx/sites-enabled/default

        # Test nginx config
        nginx -t

        # Reload nginx
        systemctl reload nginx
    "

    if [[ $? -ne 0 ]]; then
        echo "Failed to configure Nginx on server." >&2
        return 1
    fi

    echo "Nginx configured."
}
