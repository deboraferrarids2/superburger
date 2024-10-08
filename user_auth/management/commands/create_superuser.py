import logging
import os
import django

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "superburger.settings")
django.setup()

User = get_user_model()

class Command(BaseCommand):
    help = 'Create a superuser'

    def handle(self, *args, **options):
        if not User.objects.filter(email='admin@superburger.com').exists():
            User.objects.create_superuser('admin@superburger.com', 'admin')
            self.stdout.write(self.style.SUCCESS('Superuser created successfully'))
        else:
            self.stdout.write(self.style.NOTICE('Superuser already exists'))
