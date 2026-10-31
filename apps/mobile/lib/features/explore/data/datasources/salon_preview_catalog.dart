import '../../domain/entities/place.dart';

/// Booking data for negative-ID demo salons only. API places do not receive
/// invented services, specialists, prices, or availability.
abstract final class SalonPreviewCatalog {
  /// The demo credit balance shown on the profile screen, until credits have
  /// an API.
  static const demoCreditBalance = 86;

  static SalonCatalog? forPlace(Place place) {
    if (place.id >= 0) return null;

    final index = -place.id - 1;
    final priceAdjustment = (index % 3) * 10000;
    final services = <SalonService>[
      SalonService(
        'manicure',
        'Маникюр',
        60,
        150000 + priceAdjustment,
        'assets/images/profile/manicure.png',
      ),
      SalonService(
        'pedicure',
        'Педикюр',
        75,
        190000 + priceAdjustment,
        'assets/images/profile/pedicure.png',
      ),
      SalonService(
        'brows',
        'Брови',
        40,
        100000 + priceAdjustment,
        'assets/images/profile/brows.png',
      ),
      SalonService(
        'haircut',
        'Стрижка',
        60,
        180000 + priceAdjustment,
        'assets/images/profile/haircut.png',
      ),
      SalonService(
        'styling',
        'Укладка',
        45,
        140000 + priceAdjustment,
        'assets/images/profile/styling.png',
      ),
      SalonService(
        'lashes',
        'Наращивание ресниц',
        90,
        120000 + priceAdjustment,
        'assets/images/home/service_lashes.jpg',
      ),
      SalonService(
        'facial',
        'Чистка лица',
        60,
        150000 + priceAdjustment,
        'assets/images/home/service_facial.jpg',
      ),
    ];

    const names = [
      'Дилноза',
      'Сабина',
      'Малика',
      'Алена',
      'Феруза',
      'Шахноза',
      'Зарина',
      'Мадина',
      'Нигина',
      'Азиза',
    ];
    const portraits = {
      'Алена': 'assets/images/masters/alena.jpg',
      'Сабина': 'assets/images/masters/sabina.jpg',
      'Дилноза': 'assets/images/masters/dilnoza.jpg',
      'Мадина': 'assets/images/masters/madina.jpg',
    };
    String nameAt(int offset) => names[(index * 2 + offset) % names.length];
    const nailServices = {'manicure', 'pedicure'};
    const hairServices = {'styling', 'haircut'};
    final specialists = <SalonSpecialist>[
      SalonSpecialist(
        id: 'nail-$index',
        name: 'Лола',
        role: 'Нейл-мастер',
        rating: 4.9,
        experienceYears: 5,
        photoAsset: 'assets/images/masters/lola.png',
        serviceIds: nailServices,
      ),
      SalonSpecialist(
        id: 'nail-second-$index',
        name: 'Ситора',
        role: 'Нейл-мастер',
        rating: 4.8,
        experienceYears: 4,
        photoAsset: 'assets/images/masters/sitora.png',
        serviceIds: nailServices,
      ),
      SalonSpecialist(
        id: 'nail-top-$index',
        name: 'Муниса',
        role: 'Топ-мастер',
        rating: 5.0,
        experienceYears: 7,
        photoAsset: 'assets/images/masters/munisa.png',
        serviceIds: nailServices,
      ),
      SalonSpecialist(
        id: 'hair-$index',
        name: nameAt(0),
        photoAsset: portraits[nameAt(0)],
        role: 'Стилист по волосам',
        rating: 4.6 + (index % 4) * 0.1,
        experienceYears: 3 + index % 5,
        serviceIds: hairServices,
      ),
      SalonSpecialist(
        id: 'hair-second-$index',
        name: nameAt(1),
        photoAsset: portraits[nameAt(1)],
        role: 'Топ-стилист',
        rating: 4.7 + (index % 2) * 0.1,
        experienceYears: 6 + index % 4,
        serviceIds: hairServices,
      ),
      SalonSpecialist(
        id: 'brows-$index',
        name: nameAt(2),
        photoAsset: portraits[nameAt(2)],
        role: 'Бровист',
        rating: 4.7 + (index % 3) * 0.1,
        experienceYears: 2 + index % 4,
        serviceIds: const {'brows', 'lashes'},
      ),
      SalonSpecialist(
        id: 'brows-second-$index',
        name: nameAt(3),
        photoAsset: portraits[nameAt(3)],
        role: 'Бровист-визажист',
        rating: 4.8 + (index % 2) * 0.1,
        experienceYears: 4 + index % 3,
        serviceIds: const {'brows', 'lashes'},
      ),
      SalonSpecialist(
        id: 'face-$index',
        name: nameAt(4),
        photoAsset: portraits[nameAt(4)],
        role: 'Косметолог',
        rating: 4.8 + (index % 2) * 0.1,
        experienceYears: 5 + index % 3,
        serviceIds: const {'facial'},
      ),
      SalonSpecialist(
        id: 'face-second-$index',
        name: nameAt(5),
        photoAsset: portraits[nameAt(5)],
        role: 'Косметолог-эстетист',
        rating: 4.7 + (index % 3) * 0.1,
        experienceYears: 3 + index % 4,
        serviceIds: const {'facial'},
      ),
    ];
    return SalonCatalog(
      services: services,
      specialists: specialists,
      reviewCount: 24 + (102 + index * 53) % 190,
    );
  }

  /// Services of the preview salons among [places], each with its salons.
  static List<ServiceOffers> offersFor(List<Place> places) {
    final offers = <String, ServiceOffers>{};
    for (final place in places) {
      for (final service
          in forPlace(place)?.services ?? const <SalonService>[]) {
        (offers[service.id] ??= ServiceOffers(
          service,
        )).salons.add((place, service));
      }
    }
    return offers.values.toList();
  }

  /// Days open for demo booking, starting tomorrow.
  static List<DateTime> bookingDates(DateTime now, {int days = 7}) =>
      List.generate(
        days,
        (index) => DateTime(now.year, now.month, now.day + 1 + index),
      );

  static List<String> slotsFor(SalonSpecialist specialist, DateTime date) {
    const allSlots = [
      '10:00',
      '11:00',
      '12:00',
      '13:00',
      '14:00',
      '15:00',
      '16:00',
      '17:00',
      '18:00',
      '19:00',
      '20:00',
    ];
    final seed = specialist.id.codeUnits.fold<int>(date.day, (a, b) => a + b);
    return [
      for (var i = 0; i < allSlots.length; i++)
        if ((seed + i) % 4 != 0) allSlots[i],
    ];
  }
}

class SalonCatalog {
  const SalonCatalog({
    required this.services,
    required this.specialists,
    required this.reviewCount,
  });

  final List<SalonService> services;
  final List<SalonSpecialist> specialists;
  final int reviewCount;

  List<SalonSpecialist> specialistsFor(SalonService service) => specialists
      .where((specialist) => specialist.serviceIds.contains(service.id))
      .toList(growable: false);

  int get minPrice =>
      services.map((service) => service.price).reduce((a, b) => a < b ? a : b);

  /// Earliest slot free with any specialist on [dates], as (date, time);
  /// only specialists doing [service] count when it is given.
  (DateTime, String)? nearestSlot(
    List<DateTime> dates, {
    SalonService? service,
  }) {
    final available = service == null ? specialists : specialistsFor(service);
    for (final date in dates) {
      final slots = {
        for (final specialist in available)
          ...SalonPreviewCatalog.slotsFor(specialist, date),
      }.toList()..sort();
      if (slots.isNotEmpty) return (date, slots.first);
    }
    return null;
  }
}

/// One catalog service and the salons offering it, at their own prices.
class ServiceOffers {
  ServiceOffers(this.service);

  /// The service as the first salon lists it.
  final SalonService service;
  final List<(Place, SalonService)> salons = [];

  int get minPrice =>
      salons.map((salon) => salon.$2.price).reduce((a, b) => a < b ? a : b);
}

class SalonService {
  const SalonService(
    this.id,
    this.name,
    this.durationMinutes,
    this.price,
    this.imageAsset,
  );

  final String id;
  final String name;
  final int durationMinutes;
  final int price;
  final String imageAsset;

  static const depositPercent = 50;

  /// Demo credit pricing: a credit is worth about 4 400 sum, and evening
  /// slots (from 18:00) cost 20% more.
  static const _sumPerCredit = 4400;

  int creditsAt(String slot) {
    final base = (price / _sumPerCredit).round();
    return int.parse(slot.split(':').first) >= 18 ? (base * 1.2).round() : base;
  }

  int get deposit => price * depositPercent ~/ 100;
  int get remaining => price - deposit;
}

class SalonSpecialist {
  const SalonSpecialist({
    required this.id,
    required this.name,
    required this.role,
    required this.rating,
    required this.experienceYears,
    required this.serviceIds,
    this.photoAsset,
  });

  final String id;
  final String name;
  final String role;
  final double rating;
  final int experienceYears;
  final Set<String> serviceIds;
  final String? photoAsset;
}
