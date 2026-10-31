from rest_framework import serializers

from .models import Place, Service


class ServiceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Service
        fields = ("id", "name", "price", "duration_minutes")


class PlaceSerializer(serializers.ModelSerializer):
    services = ServiceSerializer(many=True, read_only=True)

    class Meta:
        model = Place
        fields = (
            "id", "name", "description", "address", "latitude", "longitude",
            "rating", "is_verified", "services",
        )

