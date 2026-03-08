# lib/venv.sh — source this file, do not execute directly

setup_venv() {
    echo "Setting up virtual environment and installing dependencies..."

    run_ssh "
        # Create venv if it doesn't exist
        if [[ ! -d ${SHARED_DIR}/venv ]]; then
            python${APP_PYTHON_VERSION} -m venv ${SHARED_DIR}/venv
        fi

        # Upgrade pip
        ${SHARED_DIR}/venv/bin/pip install --upgrade pip -q

        # Install dependencies
        if [[ -f ${CURRENT_LINK}/requirements.txt ]]; then
            ${SHARED_DIR}/venv/bin/pip install -r ${CURRENT_LINK}/requirements.txt -q
        elif [[ -f ${CURRENT_LINK}/pyproject.toml ]]; then
            ${SHARED_DIR}/venv/bin/pip install -e ${CURRENT_LINK} -q
        else
            echo 'No requirements.txt or pyproject.toml found in release.' >&2
            exit 1
        fi
    "

    if [[ $? -ne 0 ]]; then
        echo "Failed to install dependencies. Check requirements.txt or pyproject.toml." >&2
        return 1
    fi

    echo "Virtual environment ready."
}
