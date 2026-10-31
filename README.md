# Stratup Guzallik

Startup loyihasi - Guzallik industriyasi uchun ochiq manba loyihasi.

## Loyiha haqida

Bu loyiha guzallik salonlari, kosmetolog va guzallik xizmatlari beruvchilar uchun boshqaruv tizimini yaratadi.

## Papkalar tuzilimi

```
stratup_guzallik/
├── frontend/          # Frontend kod (React, Vue, yoki boshqa)
├── backend/           # Backend kod (Node.js, Python, yoki boshqa)
├── database/          # Ma'lumotlar bazasi skriptlari
├── docs/              # Dokumentatsiya
└── README.md
```

## Boshlanish

1. Repository-ni clone qiling:
```bash
git clone https://github.com/yetmishboyev/stratup_guzallik.git
cd stratup_guzallik
```

2. O'z branch-ingizni yarating:
```bash
git checkout -b feature/sizning-xususiyatingiz
```

3. O'z papkangizda ishlang va commit qiling
4. Pull Request yarating

## Hamkorlar

Bu loyihada birgalikda ishlaydigan barcha ishchilar shu yerda ro'yxatga olinadi.

## Litsenziya

Ushbu loyiha MIT litsenziyasi ostida.

---

## Cosmetic Map (ветка Mobile-App)

Монорепозиторий сервиса поиска косметологических заведений и услуг на карте.

### Состав

- `apps/mobile` — Flutter-клиент с feature-first структурой и GoRouter.
- `apps/backend` — Django + DRF API.
- `apps/admin` — React + TypeScript административная панель.
- `infra` — Docker Compose, Nginx и Prometheus.
- `docs` — архитектура и API-контракты.

### Быстрый старт

```bash
cp .env.example .env
docker compose up --build
```

После запуска:

- API: http://localhost:8000/api/v1/
- Swagger: http://localhost:8000/api/docs/
- Admin UI: http://localhost:5173/
- Django admin: http://localhost:8000/admin/
- MinIO: http://localhost:9001/
- Prometheus: http://localhost:9090/

Локальная разработка без Docker описана в [docs/development.md](docs/development.md).
