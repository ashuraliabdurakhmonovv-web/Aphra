from django.db import models


class Place(models.Model):
    name = models.CharField(max_length=160)
    description = models.TextField(blank=True)
    address = models.CharField(max_length=255)
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    rating = models.DecimalField(max_digits=2, decimal_places=1, default=0)
    is_verified = models.BooleanField(default=False)
    is_published = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ("-rating", "name")

    def __str__(self) -> str:
        return self.name


class Service(models.Model):
    place = models.ForeignKey(Place, related_name="services", on_delete=models.CASCADE)
    name = models.CharField(max_length=160)
    price = models.DecimalField(max_digits=12, decimal_places=2)
    duration_minutes = models.PositiveSmallIntegerField()
    is_active = models.BooleanField(default=True)

    def __str__(self) -> str:
        return f"{self.place}: {self.name}"

