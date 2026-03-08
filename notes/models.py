from django.db import models


class Notebook(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name


class Note(models.Model):
    COLOR_CHOICES = [
        ("yellow", "Yellow"),
        ("blue", "Blue"),
        ("green", "Green"),
    ]

    title = models.CharField(max_length=200)
    content = models.TextField(blank=True)
    notebook = models.ForeignKey(Notebook, on_delete=models.CASCADE, related_name="notes")
    color = models.CharField(max_length=10, choices=COLOR_CHOICES, default="yellow")
    pinned = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.title
