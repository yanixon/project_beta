# lib/git_ops.sh — source this file, do not execute directly

push_to_remote() {
    # Find the remote name that matches REPO_URL
    local remote_name
    remote_name=$(git remote -v | grep -F "$REPO_URL" | head -1 | awk '{print $1}')

    if [[ -z "$remote_name" ]]; then
        echo "No git remote matches repo_url '$REPO_URL'. Cannot push." >&2
        return 1
    fi

    echo "Pushing to ${remote_name}/${REPO_BRANCH}..."
    if ! git push "$remote_name" "HEAD:${REPO_BRANCH}"; then
        echo "Failed to push to remote. Ensure you have write access to $REPO_URL." >&2
        return 1
    fi
}
