from django.contrib import admin

from .models import Place, Service


class ServiceInline(admin.TabularInline):
    model = Service
    extra = 0


@admin.register(Place)
class PlaceAdmin(admin.ModelAdmin):
    list_display = ("name", "address", "rating", "is_verified", "is_published")
    list_filter = ("is_verified", "is_published")
    search_fields = ("name", "address")
    inlines = (ServiceInline,)

