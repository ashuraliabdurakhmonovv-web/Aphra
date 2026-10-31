from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):
    initial = True
    dependencies = []

    operations = [
        migrations.CreateModel(
            name="Place",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("name", models.CharField(max_length=160)),
                ("description", models.TextField(blank=True)),
                ("address", models.CharField(max_length=255)),
                ("latitude", models.DecimalField(decimal_places=6, max_digits=9)),
                ("longitude", models.DecimalField(decimal_places=6, max_digits=9)),
                ("rating", models.DecimalField(decimal_places=1, default=0, max_digits=2)),
                ("is_verified", models.BooleanField(default=False)),
                ("is_published", models.BooleanField(default=False)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
            ],
            options={"ordering": ("-rating", "name")},
        ),
        migrations.CreateModel(
            name="Service",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("name", models.CharField(max_length=160)),
                ("price", models.DecimalField(decimal_places=2, max_digits=12)),
                ("duration_minutes", models.PositiveSmallIntegerField()),
                ("is_active", models.BooleanField(default=True)),
                ("place", models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name="services", to="places.place")),
            ],
        ),
    ]

