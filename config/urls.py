from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path("admin/", admin.site.urls),
    path("auth/", include("shared_auth.urls")),
    path("", include("notes.urls")),
]
