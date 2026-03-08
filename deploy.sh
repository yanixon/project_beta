#!/usr/bin/env bash
# deploy.sh — main deployment orchestrator for project_alpha
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Flag defaults
SKIP_NGINX=false
SKIP_SEED=false
ONLY_DEPLOY=false
ONLY_NGINX=false
ONLY_SEED=false

# Parse CLI flags
while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-nginx)
            SKIP_NGINX=true
            shift
            ;;
        --skip-seed)
            SKIP_SEED=true
            shift
            ;;
        --only-deploy)
            ONLY_DEPLOY=true
            shift
            ;;
        --only-nginx)
            ONLY_NGINX=true
            shift
            ;;
        --only-seed)
            ONLY_SEED=true
            shift
            ;;
        --help)
            echo "Usage: deploy.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --skip-nginx    Skip Nginx configuration"
            echo "  --skip-seed     Skip database seeding"
            echo "  --only-deploy   Skip git push; run remote phases only"
            echo "  --only-nginx    Only run Nginx configuration (parse, SSH, nginx, reload)"
            echo "  --only-seed     Only run database seeding (parse, SSH, seed)"
            echo "  --help          Show this usage message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Run 'deploy.sh --help' for usage." >&2
            exit 1
            ;;
    esac
done

# Source all helpers
source "$SCRIPT_DIR/lib/yaml_parse.sh"
source "$SCRIPT_DIR/lib/validate.sh"
source "$SCRIPT_DIR/lib/server_check.sh"
source "$SCRIPT_DIR/lib/git_ops.sh"
source "$SCRIPT_DIR/lib/release.sh"
source "$SCRIPT_DIR/lib/venv.sh"
source "$SCRIPT_DIR/lib/env_file.sh"
source "$SCRIPT_DIR/lib/database.sh"
source "$SCRIPT_DIR/lib/static.sh"
source "$SCRIPT_DIR/lib/gunicorn.sh"
source "$SCRIPT_DIR/lib/nginx.sh"
source "$SCRIPT_DIR/lib/seed.sh"
source "$SCRIPT_DIR/lib/health.sh"
source "$SCRIPT_DIR/lib/deploy_log.sh"

# Handle --only-* flags first
if $ONLY_NGINX; then
    parse_deploy_yml "deploy.yml"
    test_ssh_connection
    configure_nginx
    exit 0
fi
if $ONLY_SEED; then
    parse_deploy_yml "deploy.yml"
    test_ssh_connection
    run_seed
    exit 0
fi

# Full deployment flow
echo "==> Phase: Parsing configuration"
parse_deploy_yml "deploy.yml"

echo "==> Phase: Validating project"
validate_project

if ! $ONLY_DEPLOY; then
    echo "==> Phase: Pushing to remote"
    push_to_remote
fi

echo "==> Phase: Testing SSH connectivity"
test_ssh_connection

echo "==> Phase: Validating server software"
validate_server_software

echo "==> Phase: Setting up release"
setup_release

echo "==> Phase: Setting up virtual environment"
setup_venv

echo "==> Phase: Generating environment file"
generate_env_file

echo "==> Phase: Provisioning database"
provision_database

echo "==> Phase: Running migrations"
run_migrations

echo "==> Phase: Collecting static files"
collect_static

echo "==> Phase: Configuring Gunicorn"
configure_gunicorn

if ! $SKIP_NGINX; then
    echo "==> Phase: Configuring Nginx"
    configure_nginx
fi

if ! $SKIP_SEED; then
    echo "==> Phase: Seeding database"
    run_seed
fi

echo "==> Phase: Running health checks"
run_health_checks

echo "==> Phase: Logging deployment"
log_deployment "$(basename "$RELEASE_DIR")"

echo ""
echo "==> Deployment complete!"
