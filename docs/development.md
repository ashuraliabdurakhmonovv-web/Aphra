# Локальная разработка

## Backend

```bash
cd apps/backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

По умолчанию вне Docker используется SQLite. Для PostgreSQL задайте `DATABASE_URL`.

## Mobile

```bash
cd apps/mobile
flutter pub get
flutter run
```

## Admin

```bash
cd apps/admin
npm install
npm run dev
```

