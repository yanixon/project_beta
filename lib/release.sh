# lib/release.sh — source this file, do not execute directly

setup_release() {
    local release_ts
    release_ts=$(date +%Y%m%d%H%M%S)
    RELEASE_DIR="${RELEASES_DIR}/${release_ts}"

    echo "Setting up release ${release_ts}..."

    run_ssh "
        # Create directory structure
        mkdir -p ${RELEASES_DIR} ${SHARED_DIR}/static ${SHARED_DIR}/env

        # Clone into release directory
        git clone --branch ${REPO_BRANCH} --depth 1 ${REPO_URL} ${RELEASE_DIR}

        # Update current symlink
        ln -sfn ${RELEASE_DIR} ${CURRENT_LINK}

        # Clean up old releases, keep 5 most recent
        cd ${RELEASES_DIR} && ls -1d */ 2>/dev/null | sort -r | tail -n +6 | xargs -r rm -rf
    "

    if [[ $? -ne 0 ]]; then
        echo "Failed to set up release directory on server." >&2
        return 1
    fi

    echo "Release ${release_ts} deployed."
}
