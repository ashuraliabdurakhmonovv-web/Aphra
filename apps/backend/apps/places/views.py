from rest_framework import filters, viewsets

from .models import Place
from .serializers import PlaceSerializer


class PlaceViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = PlaceSerializer
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ["name", "address", "services__name"]
    ordering_fields = ["rating", "name", "created_at"]

    def get_queryset(self):
        return Place.objects.filter(is_published=True).prefetch_related("services")

