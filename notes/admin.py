from django.contrib import admin

from notes.models import Note, Notebook


@admin.register(Notebook)
class NotebookAdmin(admin.ModelAdmin):
    list_display = ["name", "created_at"]


@admin.register(Note)
class NoteAdmin(admin.ModelAdmin):
    list_display = ["title", "notebook", "color", "pinned", "created_at"]
    list_filter = ["color", "pinned", "notebook"]
