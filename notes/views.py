from django.views.generic import ListView

from notes.models import Note


class NoteListView(ListView):
    model = Note
    template_name = "notes/note_list.html"
    context_object_name = "notes"
    ordering = ["-pinned", "-created_at"]
