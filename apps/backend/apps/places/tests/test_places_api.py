import pytest
from rest_framework.test import APIClient

from apps.places.models import Place


@pytest.mark.django_db
def test_only_published_places_are_returned():
    Place.objects.create(
        name="Visible", address="Tashkent", latitude=41.311081,
        longitude=69.240562, is_published=True,
    )
    Place.objects.create(
        name="Hidden", address="Tashkent", latitude=41.3,
        longitude=69.2, is_published=False,
    )

    response = APIClient().get("/api/v1/places/")

    assert response.status_code == 200
    assert [item["name"] for item in response.data["results"]] == ["Visible"]

