# lib/deploy_log.sh — source this file, do not execute directly

log_deployment() {
    local release_name="$1"

    echo "Logging deployment..."

    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    local commit_sha
    commit_sha=$(run_ssh "git -C ${RELEASES_DIR}/${release_name} rev-parse --short HEAD 2>/dev/null || echo unknown")
    commit_sha=$(echo "$commit_sha" | xargs)  # trim whitespace

    run_ssh "
        echo '{\"timestamp\":\"${timestamp}\",\"project\":\"${PROJECT_NAME}\",\"release\":\"${release_name}\",\"branch\":\"${REPO_BRANCH}\",\"commit\":\"${commit_sha}\",\"user\":\"${USER}\",\"host\":\"${SERVER_HOST}\"}' >> ${PROJECT_DIR}/deploy.log
    "

    if [[ $? -ne 0 ]]; then
        echo "Failed to write deployment log on server." >&2
        return 1
    fi

    echo "Deployment logged to ${PROJECT_DIR}/deploy.log"
}
