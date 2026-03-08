from django.urls import path

from notes.views import NoteListView

urlpatterns = [
    path("", NoteListView.as_view(), name="note-list"),
]
