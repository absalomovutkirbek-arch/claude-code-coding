# Claude Code setuplari

Har bir stack uchun tayyor Claude Code setup. Loyihaga o'rnatasiz va Claude kodni sizning arxitekturangizda yozadi: Controller → Action → Form → DTO → Service → Repository. Siz faqat biznes mantiqni aytasiz.

## Holat

| Stack | Papka | Holat |
| --- | --- | --- |
| Umumiy qoidalar | `common/` | Tayyor |
| Yii2 | `yii2/` | Tayyor (reference stack) |
| Laravel | `laravel/` | Rejada |
| Java (Spring Boot) | `spring-boot/` | Rejada |
| React | `react/` | Rejada |

## Tuzilishi

```
common/rules/            Barcha stacklar uchun umumiy qoidalar (9 ta fayl)
  architecture.md          Qatlamlar, modullar, transaction chegarasi
  clean-code.md            SOLID, DRY, KISS, nomlash, funksiyalar
  design-patterns.md       Qaysi pattern qachon ishlatiladi va qachon ishlatilmaydi
  api-design.md            URL, status kodlar, javob formati, pagination
  validation-and-errors.md Ikki bosqichli validatsiya, exceptionlar
  database.md              Schema, normalizatsiya, nomlash, migratsiyalar
  testing.md               Nima va qanday test qilinadi
  security.md              Xavfsizlik qoidalari
  workflow.md              Claude qanday ishlashi kerak, eski kod bilan ishlash

yii2/
  CLAUDE.md              Loyiha yo'riqnomasi (Project facts qismini to'ldirasiz)
  .claude/
    settings.json        Ruxsatlar va hooklar
    rules/yii2/          Yii2 uchun qoidalar (5 ta fayl)
    skills/              8 ta slash buyruq
    hooks/               2 ta avtomatik tekshiruv

install.sh               Setupni loyihaga o'rnatadi
```

## O'rnatish

```bash
git clone https://github.com/absalomovutkirbek-arch/claude-code-coding.git
cd claude-code-coding
./install.sh yii2 /path/to/loyiha
```

Windows'da Git Bash yoki WSL orqali ishga tushiring.

Skript quyidagilarni ko'chiradi:

- `common/rules/` → `<loyiha>/.claude/rules/common/`
- `yii2/.claude/` → `<loyiha>/.claude/`
- `yii2/CLAUDE.md` → `<loyiha>/CLAUDE.md`

Loyihada `CLAUDE.md` yoki `.claude/settings.json` allaqachon bo'lsa, ular o'zgartirilmaydi. Yangi variant yoniga `.new` kengaytmasi bilan yoziladi va siz qo'lda birlashtirasiz. Ustidan yozish uchun `--force` qo'shing.

Setup yangilanganda skriptni qayta ishga tushirsangiz, qoidalar, skills va hooklar yangilanadi.

## Birinchi ishga tushirish

Loyiha papkasida `claude` ni oching va tartib bilan bajaring:

1. `/adopt-project` — Claude loyihani o'rganadi, `CLAUDE.md` dagi "Project facts" qismini to'ldiradi va loyiha standartdan qayerda farq qilishini aytadi.
2. `/foundation` — `core/` papkasini o'rnatadi: asosiy controller va action, xatolarni qayta ishlovchi, exceptionlar, transaction manager, pipeline, event dispatcher. Har loyihada bir marta.
3. `/new-module billing` — yangi modul va uning schemasi.
4. `/new-endpoint billing POST /v1/billing/transfers pul o'tkazish` — to'liq endpoint: migratsiya, model, repository, service, form, action, resource va testlar.

Shundan keyin oddiy tilda yozsangiz ham bo'ladi, masalan "buyurtmani bekor qilish endpointini qo'sh". Claude qoidalarga o'zi amal qiladi va kerakli skillni o'zi tanlaydi.

## Yii2 skills

| Buyruq | Vazifasi |
| --- | --- |
| `/adopt-project` | Loyihani o'rganish va "Project facts" ni to'ldirish |
| `/foundation` | `core/` shared kernelni o'rnatish |
| `/new-module` | Yangi biznes modul |
| `/new-endpoint` | Endpointni barcha qatlamlari va testlari bilan yaratish |
| `/new-migration` | Schema o'zgarishi |
| `/pipeline` | 3 va undan ko'p qadamli ish uchun Chain of Responsibility |
| `/strategy` | 2 va undan ko'p variantli ish uchun Strategy |
| `/arch-review` | Kodni qoidalarga solishtirib tekshirish |

## Hooklar

Ikkita hook Claude har fayl yozganda avtomatik ishlaydi:

- `guard-files.php` — `.env`, `vendor/` va gitga commit qilingan migratsiyalarni tahrirlashni bloklaydi.
- `check-php.php` — `php -l` bilan sintaksisni tekshiradi va qatlam qoidalarini nazorat qiladi. Masalan, Action ichida `::find()` yoki Service ichida `Yii::$app` yozilsa, Claude'ga darhol xabar beradi va u tuzatadi. Faqat yangi yozilgan kod tekshiriladi, eski kod tegilmaydi.

Hooklar kompyuteringizda `php` buyrug'i mavjud bo'lishini talab qiladi. PHP faqat Docker ichida bo'lsa, `.claude/settings.json` dagi `hooks` qismida buyruqni `docker compose exec -T php php ...` ko'rinishiga o'zgartiring yoki hooklarni olib tashlang.

## Reference kod

`yii2/.claude/skills/new-endpoint/reference/` ichida to'liq ishlaydigan namuna bor: `billing` moduli, hamyonlar orasida pul o'tkazish. Unda transaction, qatorlarni qulflash (`FOR UPDATE`), biznes exceptionlar, event, pagination va unit testlar ko'rsatilgan.

Bu kod haqiqiy Yii2 2.0.55 + PostgreSQL 16 ilovasida sinab ko'rilgan: 14 ta HTTP holat va 6 ta unit test o'tgan. Fayllar `.tpl` kengaytmasida turadi, shunda IDE ularni loyiha kodi deb indekslamaydi.

## Standartni o'zgartirish

- Barcha stacklarga tegishli qoida: `common/rules/` ichidagi faylni tahrirlang.
- Faqat Yii2 ga tegishli qoida: `yii2/.claude/rules/yii2/`.
- Bitta loyihaga xos istisno: o'sha loyihaning `CLAUDE.md` faylidagi "Project-specific overrides" qatoriga yozing. U qoida fayllaridan ustun turadi.

Qoida fayllari ingliz tilida yozilgan, chunki Claude inglizcha ko'rsatmalarga aniqroq amal qiladi.
