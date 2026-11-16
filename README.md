# Claude Code setuplari

Har bir stack uchun tayyor Claude Code setup. Loyihaga o'rnatasiz va Claude kodni sizning arxitekturangizda yozadi: Controller → Action → Form → DTO → Service → Repository. Siz faqat biznes mantiqni aytasiz.

## Holat

| Stack | Papka | Holat | Namuna kod qanday sinalgan |
| --- | --- | --- | --- |
| Umumiy qoidalar | `common/` | Tayyor | |
| Yii2 | `yii2/` | Tayyor | Yii2 2.0.55 + PostgreSQL 16: 14 ta HTTP holat, 6 ta unit test |
| Laravel | `laravel/` | Tayyor | Laravel 13 + PostgreSQL 16: 10 ta feature test, 6 ta unit test |
| Java (Spring Boot) | `spring-boot/` | Tayyor | Spring Boot 3.5 + Java 21 + PostgreSQL 16: 11 ta API test, 6 ta unit test |
| React | `react/` | Tayyor | React 19 + TypeScript + Vite: 29 ta test (Vitest + MSW) |

Barcha stacklar bir xil standartga amal qiladi: bir xil qatlamlar, bir xil javob formati (`{data, meta}` va `{error: {code, message, details}}`), bir xil exception turlari va xato kodlari. Shuning uchun React setupi uchala backend bilan ham to'g'ridan-to'g'ri ishlaydi.

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

<stack>/                 yii2, laravel, spring-boot, react
  CLAUDE.md              Loyiha yo'riqnomasi (Project facts qismini to'ldirasiz)
  .claude/
    settings.json        Ruxsatlar va hooklar
    rules/<stack>/       Shu stack uchun qoidalar (5 ta fayl)
    skills/              Slash buyruqlar va tekshirilgan namuna kod
    hooks/               Avtomatik tekshiruvlar

global/skills/setup-stack/  /setup-stack skill (install.sh --global o'rnatadi)
docs/                    Qo'llanmalar
install.sh               Setupni loyihaga o'rnatadi
```

## O'rnatish

Har loyihaga qo'lda o'rnatish shart emas. claude.ai Projects, Claude Desktop va terminal uchun to'liq qo'llanma: [docs/claude-code-projects.md](docs/claude-code-projects.md). Qisqasi:

- **claude.ai Projects**: projectga ilova reposi va shu reponi qo'shasiz, qo'llanmadagi tayyor "Project instructions" ni qo'yasiz, chatga "Setupni o'rnat" deysiz. Claude o'zi o'rnatib PR ochadi.
- **Claude Desktop yoki terminal**: bir marta `./install.sh --global`, keyin har loyihada `/setup-stack`.

Qo'lda o'rnatish:

```bash
git clone https://github.com/absalomovutkirbek-arch/claude-code-coding.git
cd claude-code-coding
./install.sh <stack> /path/to/loyiha     # stack: yii2 | laravel | spring-boot | react
```

Windows'da Git Bash yoki WSL orqali ishga tushiring.

Skript quyidagilarni ko'chiradi:

- `common/rules/` → `<loyiha>/.claude/rules/common/`
- `<stack>/.claude/` → `<loyiha>/.claude/`
- `<stack>/CLAUDE.md` → `<loyiha>/CLAUDE.md`

Loyihada `CLAUDE.md` yoki `.claude/settings.json` allaqachon bo'lsa, ular o'zgartirilmaydi. Yangi variant yoniga `.new` kengaytmasi bilan yoziladi va siz qo'lda birlashtirasiz. Ustidan yozish uchun `--force` qo'shing.

Setup yangilanganda skriptni qayta ishga tushirsangiz, qoidalar, skills va hooklar yangilanadi.

## Birinchi ishga tushirish

Loyiha papkasida `claude` ni oching va tartib bilan bajaring:

1. `/adopt-project` — Claude loyihani o'rganadi, `CLAUDE.md` dagi "Project facts" qismini to'ldiradi va loyiha standartdan qayerda farq qilishini aytadi.
2. `/foundation` — umumiy yadroni (shared kernel) o'rnatadi. Har loyihada bir marta.
3. Backendda: `/new-module billing`, keyin `/new-endpoint billing POST /transfers pul o'tkazish`. Frontendda: `/new-feature billing`, keyin `/new-api-resource`, `/new-page`, `/new-form`.

Shundan keyin oddiy tilda yozsangiz ham bo'ladi, masalan "buyurtmani bekor qilish endpointini qo'sh". Claude qoidalarga o'zi amal qiladi va kerakli skillni o'zi tanlaydi.

## Skills

Backend stacklarida (Yii2, Laravel, Spring Boot) buyruqlar bir xil:

| Buyruq | Vazifasi |
| --- | --- |
| `/adopt-project` | Loyihani o'rganish va "Project facts" ni to'ldirish |
| `/foundation` | Shared kernelni o'rnatish |
| `/new-module` | Yangi biznes modul va uning DB schemasi |
| `/new-endpoint` | Endpointni barcha qatlamlari va testlari bilan yaratish |
| `/new-migration` | Schema o'zgarishi |
| `/pipeline` | 3 va undan ko'p qadamli ish uchun Chain of Responsibility |
| `/strategy` | 2 va undan ko'p variantli ish uchun Strategy |
| `/arch-review` | Kodni qoidalarga solishtirib tekshirish |

React:

| Buyruq | Vazifasi |
| --- | --- |
| `/adopt-project` | Loyihani o'rganish va "Project facts" ni to'ldirish |
| `/foundation` | `src/shared/` (HTTP client, ApiError, query client, formalar uchun yordamchilar) va test sozlamalari |
| `/new-feature` | Yangi feature papkasi va uning routelari |
| `/new-api-resource` | Backend resursini ulash: model, API modul, TanStack Query hooklar, testlar |
| `/new-page` | Sahifa: yuklanish, xato, bo'sh va ma'lumot holatlari bilan |
| `/new-form` | Forma: zod schema, react-hook-form, server xatolari, testlar |
| `/arch-review` | Kodni qoidalarga solishtirib tekshirish |

## Stacklar bo'yicha qisqa farqlar

| | Yii2 | Laravel | Spring Boot | React |
| --- | --- | --- | --- | --- |
| Action | Alohida `Action` klass | Invokable `Action` klass | Controller metodi (≤3 qadam) | Page komponenti |
| Form | `yii\base\Model` | `FormRequest` | Bean Validation `record` | zod schema |
| DTO | `final` + `readonly` | `final readonly class` | `record` | model `interface` |
| Repository | interface + klass | interface + klass | Spring Data interface | `*.api.ts` modul |
| Transaction | `TransactionManagerInterface` | `TransactionManagerInterface` | `@Transactional` | — |
| Migratsiya | Yii migratsiya (modul ichida) | Laravel migratsiya (modul ichida) | Flyway SQL (modul papkasida) | — |
| Hook tili | PHP | PHP | Bash | Node.js |

## Hooklar

Ikkita hook Claude har fayl yozganda avtomatik ishlaydi:

- `guard-files` — `.env`, uchinchi tomon kodi (`vendor/`, `node_modules/`), build natijalari va gitga commit qilingan migratsiyalarni tahrirlashni bloklaydi.
- `check-*` — qatlam qoidalarini nazorat qiladi. Masalan, Action ichida DB so'rovi, Service ichida request yoki `SecurityContextHolder`, React komponentida to'g'ridan-to'g'ri `useQuery` yoki `any` yozilsa, Claude'ga darhol xabar beradi va u tuzatadi. Faqat yangi yozilgan kod tekshiriladi, eski kod tegilmaydi.

claude.ai Projects threadlarida hooklar ishlamaydi. U yerda Claude ishni tugatishdan oldin `check-changed` skriptini ishga tushiradi: u hook bilan bir xil tekshiruvni o'zgargan barcha fayllarga qo'llaydi (`php .claude/hooks/check-changed.php origin/main`, Spring Boot uchun `bash .claude/hooks/check-changed.sh`, React uchun `node .claude/hooks/check-changed.mjs`). Uni CI'da ham ishlatish mumkin.

Talablar: Yii2 va Laravel uchun kompyuterda `php`, Spring Boot uchun `bash` va `git` (JSON uchun `jq` yoki `python3` bo'lsa yaxshi), React uchun `node`. PHP faqat Docker ichida bo'lsa, `.claude/settings.json` dagi `hooks` qismida buyruqni `docker compose exec -T php php ...` ko'rinishiga o'zgartiring yoki hooklarni olib tashlang.

## Reference kod

Har bir stackda to'liq ishlaydigan namuna bor: `billing` moduli, hamyonlar orasida pul o'tkazish. Unda transaction, qatorlarni qulflash (`FOR UPDATE`), biznes exceptionlar va ularning xato kodlari, after-commit event, pagination va testlar ko'rsatilgan. React namunasi xuddi shu API ga ulanadi: ro'yxat sahifasi, pul o'tkazish formasi, server xatolarini forma maydonlariga chiqarish.

- Yii2, Laravel, Spring Boot: `<stack>/.claude/skills/new-endpoint/reference/`
- React: `react/.claude/skills/new-api-resource/reference/`
- Shared kernel shablonlari: `<stack>/.claude/skills/foundation/templates/`

Har bir kod haqiqiy ilovada sinab ko'rilgan (yuqoridagi jadvalga qarang). Fayllar `.tpl` kengaytmasida turadi, shunda IDE ularni loyiha kodi deb indekslamaydi.

## Standartni o'zgartirish

- Barcha stacklarga tegishli qoida: `common/rules/` ichidagi faylni tahrirlang.
- Faqat bitta stackka tegishli qoida: `<stack>/.claude/rules/<stack>/`.
- Bitta loyihaga xos istisno: o'sha loyihaning `CLAUDE.md` faylidagi "Project-specific overrides" qatoriga yozing. U qoida fayllaridan ustun turadi.

Qoida fayllari ingliz tilida yozilgan, chunki Claude inglizcha ko'rsatmalarga aniqroq amal qiladi.
