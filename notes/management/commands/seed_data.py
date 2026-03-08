from django.core.management.base import BaseCommand

from notes.models import Note, Notebook

SEED = [
    {
        "notebook": "Development",
        "notebook_desc": "Software development notes",
        "notes": [
            {"title": "Set up CI/CD pipeline", "content": "Configure GitHub Actions for automated testing and deployment", "color": "blue", "pinned": True},
            {"title": "Write unit tests for auth module", "content": "Cover login, logout, and password reset flows", "color": "blue", "pinned": False},
            {"title": "Refactor database queries", "content": "Optimize N+1 queries in the dashboard view", "color": "green", "pinned": False},
        ],
    },
    {
        "notebook": "Design",
        "notebook_desc": "UI/UX design notes",
        "notes": [
            {"title": "Create wireframes for mobile app", "content": "Design key screens: home, profile, settings", "color": "yellow", "pinned": True},
            {"title": "Update brand color palette", "content": "Align with new brand guidelines from marketing", "color": "yellow", "pinned": False},
        ],
    },
    {
        "notebook": "Operations",
        "notebook_desc": "DevOps and infrastructure notes",
        "notes": [
            {"title": "Migrate to PostgreSQL 16", "content": "Upgrade from PostgreSQL 14 to 16 on production", "color": "blue", "pinned": True},
            {"title": "Set up monitoring alerts", "content": "Configure Prometheus alerts for CPU, memory, and disk usage", "color": "green", "pinned": False},
            {"title": "Document deployment process", "content": "Write runbook for production deployments", "color": "yellow", "pinned": False},
        ],
    },
]


class Command(BaseCommand):
    help = "Seed database with sample notes"

    def handle(self, *args, **options):
        for group in SEED:
            nb, _ = Notebook.objects.get_or_create(
                name=group["notebook"],
                defaults={"description": group["notebook_desc"]},
            )
            for n in group["notes"]:
                Note.objects.get_or_create(
                    title=n["title"],
                    defaults={
                        "content": n["content"],
                        "notebook": nb,
                        "color": n["color"],
                        "pinned": n["pinned"],
                    },
                )
        self.stdout.write(self.style.SUCCESS("Seeded note data successfully."))
