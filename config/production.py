import os

import dj_database_url

from config.settings import *  # noqa: F401, F403

DEBUG = False

SECRET_KEY = os.environ["SECRET_KEY"]

ALLOWED_HOSTS = os.environ.get("ALLOWED_HOSTS", "").split(",")

DATABASES = {
    "default": dj_database_url.config(default=os.environ.get("DATABASE_URL")),
}

STATIC_ROOT = os.environ.get("STATIC_ROOT", BASE_DIR / "staticfiles")

CSRF_TRUSTED_ORIGINS = [f"http://{host}" for host in ALLOWED_HOSTS]

FORCE_SCRIPT_NAME = "/beta"

STATIC_URL = "/beta/static/"
