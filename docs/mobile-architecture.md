# Mobile architecture rules

Flutter ilovasi feature-first Clean Architecture asosida yuritiladi.

## Qatlamlar

- `domain` — entity, repository contract va use case. Flutter, Dio va Hive'ga bog‘lanmaydi.
- `data` — API/local data source, Freezed model va repository implementation.
- `presentation` — page, widget va event/state asosidagi BLoC.
- `core` — DI, error, network, storage va umumiy use case kontraktlari.

Dependency yo‘nalishi: `presentation -> domain <- data`. Data xatolari `Exception`, domain/presentation natijalari esa `Failure` orqali uzatiladi (`Either<Failure, T>`).

## Saqlash qoidalari

- Hive CE — offline obyektlar va feature cache.
- `flutter_secure_storage` — token va maxfiy qiymatlar.
- `shared_preferences` — locale kabi sodda sozlamalar.
- Katta hajmdagi ma’lumotlar uchun texnologiya alohida kelishiladi.

Har bir yangi foydalanuvchi matni `assets/translations` ichida `uz`, `ru` va `en` uchun yoziladi. Yangi dependency va umumiy widget qo‘shishdan avval mavjud implementatsiya qayta ishlatilishi tekshiriladi.

