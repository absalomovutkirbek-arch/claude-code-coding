# Setupni yangi loyihaga ulash: qo'llanma

Bu qo'llanma setupni har bir loyihaga qo'lda ko'chirmasdan ishlatishni tushuntiradi. Asosiy fikr: setupni siz o'rnatmaysiz, Claude o'zi o'rnatadi. Siz faqat bir marta sozlaysiz.

## Qaysi yo'lni tanlash kerak

| Qayerda ishlaysiz | Bir marta qilinadigan ish | Har yangi loyihada |
| --- | --- | --- |
| **claude.ai Projects** (tavsiya) | GitHub ulash va Claude GitHub App o'rnatish | Project yaratasiz, ikkita repo qo'shasiz, tayyor instructionsni qo'yasiz. Setupni birinchi thread o'zi o'rnatib PR ochadi |
| **Claude Desktop yoki terminal** (kompyuterdagi papka) | `./install.sh --global` | Papkani ochib `/setup-stack` deysiz |
| **claude.ai/code oddiy sessiya** (projectsiz) | GitHub ulash | Sessiyada "setupni o'rnat" deysiz |

Qaysi yo'lni tanlasangiz ham natija bir xil: loyiha reposida `CLAUDE.md` va `.claude/` papkasi paydo bo'ladi va gitga commit qilinadi. Shundan keyin setup kod bilan birga yuradi: boshqa kompyuterda, boshqa dasturchida va cloudda ham ishlaydi.

## Setupning qaysi qismi qayerda ishlaydi

Claude Code har joyda setupning hamma qismini o'qimaydi. Buni bilish kerak, aks holda "nega `/new-endpoint` ishlamayapti" degan savol chiqadi.

| Setup qismi | Desktop / terminal | claude.ai/code oddiy sessiya | claude.ai Projects thread |
| --- | --- | --- | --- |
| `CLAUDE.md` | Ha | Ha | Ha |
| `.claude/rules/common/` va `structure.md` | Ha | Ha | Ha |
| Qatlam qoidalari (`http-layer.md` va boshqalar, `paths:` bilan) | Ha, kerakli faylda | Ha, kerakli faylda | Avtomatik emas |
| Skills (`/new-endpoint` va boshqalar) | Ha | Ha | Avtomatik emas |
| Hooklar (`guard-files`, `check-*`) | Ha | Ha | Ishlamaydi |
| `settings.json` ruxsatlari | Ha | Ha | Qo'llanmaydi, auto mode ishlaydi |

Projects threadlarida yo'q qismlar o'rniga `CLAUDE.md` ichida "Sessions without skills or hooks" bo'limi bor. Unda Claude'ga aytilgan: skill kerak bo'lsa `.claude/skills/<nom>/SKILL.md` ni o'zi o'qib bajarsin, qatlam qoidasini o'zi o'qisin va ishni tugatishdan oldin `check-changed` skriptini ishga tushirsin. `check-changed` hook bilan bir xil tekshiruvni o'zgargan barcha fayllarga qo'llaydi. Shuning uchun Projectsda ham qoidalar to'liq ishlaydi, faqat slash buyruq o'rniga oddiy so'z bilan yozasiz: "new-endpoint skill bo'yicha ...".

## 1-yo'l. claude.ai Projects (tavsiya)

Projects Pro va Max tariflarida bor. claude.ai/code sahifasida chap menyuda **Projects** ko'rinmasa, **More** ichiga qarang.

### 1.1. Bir martalik tayyorgarlik

1. GitHub hisobingizni ulang: https://claude.ai/connect-github
2. Claude GitHub App'ni o'rnating va unga ikkala turdagi repoga ruxsat bering: https://github.com/apps/claude
   - `claude-code-coding` (shu setup repo);
   - ilovangiz reposi (yangi loyiha bo'lsa, avval GitHub'da bo'sh repo yarating).

   Eng osoni: App o'rnatishda "All repositories" ni tanlash. Shunda keyingi har bir yangi repo uchun bu qadam kerak bo'lmaydi.

### 1.2. Project yaratish

1. https://claude.ai/code → **Projects** → **New project**.
2. **Name**: loyiha nomi, masalan "Hamyon API".
3. **Goal** (ixtiyoriy): bir qator, masalan "Hamyonlar va pul o'tkazmalari uchun API".
4. **Context** → **Add**: ilova reposini va `claude-code-coding` reposini qo'shing. Ikkalasi ham kerak: birinchisida ish qilinadi, ikkinchisidan setup olinadi.
5. **Create project**.

Backend va frontend alohida repolarda bo'lsa (masalan Laravel API va React), uchala reponi qo'shing: ikkala ilova reposi va `claude-code-coding`.

### 1.3. Project instructions

Project sarlavhasidagi tishli g'ildirak (gear) → **Project settings** → **Memory** → **Project instructions**. Pastdagi [shablonlardan](#3-project-instructions-shablonlari) o'z stackingizniki nusxalab qo'ying, `<...>` joylarini to'ldiring va saqlang.

Instructions har bir yangi threadga yuboriladi. Ular ingliz tilida, chunki Claude inglizcha ko'rsatmalarga aniqroq amal qiladi. Javoblar o'zbek tilida bo'lishi shablonda yozilgan.

### 1.4. Cloud environment (kerak bo'lsa)

Threadlar Ubuntu 24.04 da ishlaydi. Unda PHP 8.3 + Composer, Java 21 + Maven + Gradle, Node.js 22, PostgreSQL 16 va Redis allaqachon o'rnatilgan. Packagist, npm va Maven Central default **Trusted** tarmoq darajasida ochiq.

Faqat quyidagi holatlarda environmentni o'zgartirasiz: **Project settings** → **Environment** → cloud environment yonidagi tishli g'ildirak.

- Yii2 loyiha `bower-asset` yoki `npm-asset` paketlarini ishlatsa: **Network access** → **Custom**, **Allowed domains** ga `asset-packagist.org` qo'shing va default ro'yxatni qoldiring.
- Bog'liqliklarni har threadda qayta o'rnatmaslik uchun **Setup script** yozing (ixtiyoriy). Script repo papkasidan bir daraja yuqorida ishga tushadi:

  ```bash
  #!/bin/bash
  cd <app-repo> && composer install --no-interaction || true      # Yii2 / Laravel
  # cd <app-repo> && ./mvnw -q dependency:go-offline || true      # Spring Boot
  # cd <app-repo> && npm ci || true                               # React
  ```

- `.env` dagi maxfiy qiymatlarni environment o'zgaruvchilariga yozmang: environmentdan foydalanadigan har kim ularni ko'radi. Testlar uchun `.env.testing` yoki test konfiguratsiyasi yetarli.

### 1.5. Birinchi xabar: setupni o'rnatish

Project chatiga yozing:

> Setupni o'rnat

Claude yangi thread ochadi va instructions bo'yicha:

1. ilova reposida yangi branch ochadi;
2. `claude-code-coding/install.sh <stack> .` ni ishga tushiradi;
3. `adopt-project` skillini bajaradi: loyihani o'rganadi, `CLAUDE.md` dagi "Project facts" ni to'ldiradi va loyiha standartdan qayerda farq qilishini aytadi;
4. "Install Claude Code setup" nomli PR ochadi.

Siz PR'ni ko'rib chiqasiz va merge qilasiz. Keyin:

> foundation skillini bajar

Bu umumiy yadroni (shared kernel) o'rnatadi va yana PR ochadi. Bu ham har loyihada bir marta.

### 1.6. Kundalik ish

Shundan keyin project chatiga oddiy tilda yozasiz. Masalan:

> billing moduliga pul o'tkazish endpointini qo'sh: POST /transfers. Foydalanuvchi o'z hamyonidan boshqa hamyonga pul o'tkazadi, valyutalar bir xil bo'lishi kerak, balans yetmasa insufficient_balance xatosi.

> Buyurtmani bekor qilish: faqat "new" holatidagi buyurtma bekor qilinadi, pul qaytariladi va omborga qaytariladi.

Claude har vazifa uchun alohida thread ochadi, kerakli skillni (`new-module`, `new-endpoint`, `pipeline`, `strategy` ...) o'zi tanlaydi, testlarni ishga tushiradi, `check-changed` bilan qoidalarni tekshiradi va PR ochadi. Biznes mantiqda noaniqlik bo'lsa, sizdan so'raydi.

Bir nechta ishni bir xabarda yozsangiz, ular parallel threadlarga bo'linadi.

### 1.7. Setupni yangilash

`claude-code-coding` reposida standart o'zgarsa (yangi qoida, yangi skill), project chatiga yozing:

> Setupni yangila

Claude `install.sh` ni qayta ishga tushiradi va PR ochadi. Qoidalar, skills va hooklar yangilanadi. Sizning `CLAUDE.md` va `settings.json` faylingiz o'zgartirilmaydi: yangi variant `.new` bo'lib yoziladi va Claude ularni birlashtiradi.

## 2-yo'l. Claude Desktop yoki terminal

Kod kompyuteringizdagi papkada bo'lsa, Claude Desktop ning **Code** bo'limida yoki terminalda `claude` bilan ishlaysiz. Bu yerda setupning hamma qismi ishlaydi: skills, hooklar, ruxsatlar.

### 2.1. Bir martalik o'rnatish

Reponi doimiy joyga clone qiling va global rejimni ishga tushiring:

```bash
git clone https://github.com/absalomovutkirbek-arch/claude-code-coding.git ~/tools/claude-code-coding
cd ~/tools/claude-code-coding
./install.sh --global
```

Windows'da buni Git Bash yoki WSL ichida bajaring.

Bu buyruq loyihalarga hech narsa yozmaydi. U faqat `~/.claude/skills/setup-stack/` ga bitta skill qo'yadi va unga setup repo qayerda turganini yozib qo'yadi. `~/tools/claude-code-coding` papkasini o'chirmang.

### 2.2. Har yangi loyihada

1. Loyiha papkasini oching: Claude Desktop → **Code** → papkani tanlang, yoki terminalda `cd loyiha && claude`.
2. Yozing:

   > /setup-stack

   yoki oddiy so'z bilan: "shu loyihaga setupni o'rnat".

Claude stackni o'zi aniqlaydi (`composer.json` → Yii2 yoki Laravel, `pom.xml` / `build.gradle` → Spring Boot, `package.json` → React), setupni o'rnatadi, `/adopt-project` ni bajaradi va natijani aytadi. Bo'sh, yangi loyihada qaysi stack ekanini so'raydi. Stackni o'zingiz ham aytishingiz mumkin: `/setup-stack laravel`.

3. Yangi slash buyruqlar (`/foundation`, `/new-endpoint` ...) ko'rinmasa, sessiyani qayta oching.
4. `/foundation` ni bir marta bajaring.
5. `CLAUDE.md` va `.claude/` ni commit qiling.

Bitta repoda ham backend, ham frontend bo'lsa (`backend/`, `frontend/`), `/setup-stack` har biriga o'z stackini o'rnatadi. Ishlaganda Claude Code'ni o'sha papka ichida oching.

### 2.3. Global o'rnatishsiz

`--global` ni ishlatmagan bo'lsangiz ham bo'ladi. Loyiha papkasida Claude'ga yozing:

> https://github.com/absalomovutkirbek-arch/claude-code-coding reposidagi setupni shu loyihaga o'rnat

Claude reponi vaqtinchalik papkaga clone qiladi va `install.sh` ni ishga tushiradi.

### 2.4. Yangilash

```bash
cd ~/tools/claude-code-coding && git pull
```

Keyin loyihada yana `/setup-stack` deysiz. `/setup-stack` o'zi ham ishga tushganda `git pull` qiladi.

### 2.5. Hooklar uchun talablar

Hooklar sizning kompyuteringizda ishlaydi, shuning uchun: Yii2 va Laravel uchun `php`, Spring Boot uchun `bash` va `git`, React uchun `node` kerak. PHP faqat Docker ichida bo'lsa, `.claude/settings.json` dagi `hooks` buyruqlarini `docker compose exec -T php php ...` ko'rinishiga o'zgartiring.

## 3. Project instructions shablonlari

`<app-repo>` o'rniga ilova reposining nomini, `<product>` o'rniga loyiha nima ekanini bir qatorda yozing. Asosiy branch `main` bo'lmasa, uni ham almashtiring.

### Laravel

```text
This project builds <product>. Repositories: <app-repo> (Laravel API, where all work happens) and claude-code-coding (the coding standard: read it, never change it).

Setup
- If <app-repo> has no .claude/rules/common/ folder, the setup is not installed. Before any other work, on a new branch from main: run `bash ../claude-code-coding/install.sh laravel .` from the root of <app-repo>, follow .claude/skills/adopt-project/SKILL.md, and open a pull request "Install Claude Code setup".
- "Update the setup" means the same install on a new branch; merge any *.new file into the existing one and open a pull request.

How to work
- Follow CLAUDE.md of <app-repo>, including "Sessions without skills or hooks": skills are procedures in .claude/skills/<name>/SKILL.md, layer rules are in .claude/rules/laravel/.
- When I name a skill (foundation, new-module, new-endpoint, new-migration, pipeline, strategy, arch-review), follow its SKILL.md. Otherwise pick the matching skill yourself.
- Ask me only about business behaviour. Decide the technical structure from the rules.
- One branch from main and one pull request per thread.
- Tests use PostgreSQL: start it with `service postgresql start` and create the test database and user from phpunit.xml if they are missing.
- Before calling work done, run `php .claude/hooks/check-changed.php origin/main`, `vendor/bin/pint --test` and `php artisan test`, fix what fails, and paste the summary lines.
- Do not merge, force-push, change .env files or run destructive migrations without asking me.
- Reply to me in Uzbek.
```

### Yii2

```text
This project builds <product>. Repositories: <app-repo> (Yii2 API, where all work happens) and claude-code-coding (the coding standard: read it, never change it).

Setup
- If <app-repo> has no .claude/rules/common/ folder, the setup is not installed. Before any other work, on a new branch from main: run `bash ../claude-code-coding/install.sh yii2 .` from the root of <app-repo>, follow .claude/skills/adopt-project/SKILL.md, and open a pull request "Install Claude Code setup".
- "Update the setup" means the same install on a new branch; merge any *.new file into the existing one and open a pull request.

How to work
- Follow CLAUDE.md of <app-repo>, including "Sessions without skills or hooks": skills are procedures in .claude/skills/<name>/SKILL.md, layer rules are in .claude/rules/yii2/.
- When I name a skill (foundation, new-module, new-endpoint, new-migration, pipeline, strategy, arch-review), follow its SKILL.md. Otherwise pick the matching skill yourself.
- Ask me only about business behaviour. Decide the technical structure from the rules.
- One branch from main and one pull request per thread.
- Tests use PostgreSQL: start it with `service postgresql start` and create the test database and user from the test config if they are missing.
- Before calling work done, run `php .claude/hooks/check-changed.php origin/main` and `vendor/bin/codecept run unit`, fix what fails, and paste the summary lines.
- Do not merge, force-push, change .env files or run destructive migrations without asking me.
- Reply to me in Uzbek.
```

### Spring Boot

```text
This project builds <product>. Repositories: <app-repo> (Spring Boot API, where all work happens) and claude-code-coding (the coding standard: read it, never change it).

Setup
- If <app-repo> has no .claude/rules/common/ folder, the setup is not installed. Before any other work, on a new branch from main: run `bash ../claude-code-coding/install.sh spring-boot .` from the root of <app-repo>, follow .claude/skills/adopt-project/SKILL.md, and open a pull request "Install Claude Code setup".
- "Update the setup" means the same install on a new branch; merge any *.new file into the existing one and open a pull request.

How to work
- Follow CLAUDE.md of <app-repo>, including "Sessions without skills or hooks": skills are procedures in .claude/skills/<name>/SKILL.md, layer rules are in .claude/rules/spring-boot/.
- When I name a skill (foundation, new-module, new-endpoint, new-migration, pipeline, strategy, arch-review), follow its SKILL.md. Otherwise pick the matching skill yourself.
- Ask me only about business behaviour. Decide the technical structure from the rules.
- One branch from main and one pull request per thread.
- Tests use PostgreSQL: start it with `service postgresql start` and create the test database and user from the test configuration if they are missing.
- Before calling work done, run `bash .claude/hooks/check-changed.sh origin/main` and `./mvnw test` (or `./gradlew test`), fix what fails, and paste the summary lines.
- Do not merge, force-push, change secrets or run Flyway clean or repair without asking me.
- Reply to me in Uzbek.
```

### React

```text
This project builds <product>. Repositories: <app-repo> (React frontend, where all work happens) and claude-code-coding (the coding standard: read it, never change it). The backend API follows the same standard: envelope {data, meta} / {error: {code, message, details}}, snake_case JSON.

Setup
- If <app-repo> has no .claude/rules/common/ folder, the setup is not installed. Before any other work, on a new branch from main: run `bash ../claude-code-coding/install.sh react .` from the root of <app-repo>, follow .claude/skills/adopt-project/SKILL.md, and open a pull request "Install Claude Code setup".
- "Update the setup" means the same install on a new branch; merge any *.new file into the existing one and open a pull request.

How to work
- Follow CLAUDE.md of <app-repo>, including "Sessions without skills or hooks": skills are procedures in .claude/skills/<name>/SKILL.md, layer rules are in .claude/rules/react/.
- When I name a skill (foundation, new-feature, new-api-resource, new-page, new-form, arch-review), follow its SKILL.md. Otherwise pick the matching skill yourself.
- Ask me only about behaviour and design. Do not invent a layout when a design or an existing page is given.
- One branch from main and one pull request per thread.
- Run `npm ci` if node_modules is missing. Before calling work done, run `node .claude/hooks/check-changed.mjs origin/main`, `npm run typecheck`, `npm run lint` and `npm run test`, fix what fails, and paste the summary lines.
- Do not merge, force-push or add dependencies without asking me.
- Reply to me in Uzbek.
```

### Backend va frontend bitta projectda

Ikkala shablonni birlashtiring: "Repositories" qatorida ikkala ilova reposini yozing, "Setup" qismida har biriga o'z buyrug'ini qoldiring (`install.sh laravel .` API reposida, `install.sh react .` frontend reposida) va qo'shing:

```text
- A feature that needs both an endpoint and a screen: finish the backend pull request first, then build the frontend against its request and response shapes.
```

## 4. Nega qoidalarni `~/.claude` ga global qo'ymaymiz

Qoidalar va skillarni bir marta `~/.claude` ga qo'yib, loyihaga hech narsa yozmaslik ham mumkin edi. Biz buni tanlamadik, chunki:

- to'rtta stackning skill nomlari bir xil (`/foundation`, `/new-endpoint`), global papkada ular bir-birini almashtirib yuboradi;
- Yii2 va Laravel qoidalari ikkalasi ham `*.php` fayllariga tegishli, global holda Laravel loyihasiga Yii2 qoidalari ham yuklanadi;
- `~/.claude` faqat sizning kompyuteringizda bor: cloud threadlar, boshqa dasturchilar va CI uni ko'rmaydi.

Shuning uchun global joyga faqat `/setup-stack` qo'yiladi, qoidalar esa har loyihaning o'z reposida turadi.

## 5. Tez-tez beriladigan savollar

**Loyihada allaqachon `CLAUDE.md` bor.** O'rnatuvchi uni o'zgartirmaydi va yangi variantni `CLAUDE.md.new` qilib yozadi. `/setup-stack` yoki Projects thread ikkalasini birlashtiradi: yangi fayl asos bo'ladi, sizning qoidalaringiz "Project facts" va "Project-specific overrides" ga o'tadi.

**Eski loyihadagi kod standartga mos emas.** Claude eski kodni ommaviy qayta yozmaydi. U yangi kodni standart bo'yicha yozadi, eski koddagi farqlarni `/adopt-project` hisobotida aytadi. Hooklar va `check-changed` ham faqat yangi yozilgan qatorlarni tekshiradi.

**Projects threadda `/new-endpoint` deb yozdim, ishlamadi.** Projects threadlarida repodagi skillar slash buyruq sifatida yuklanmaydi. "new-endpoint skill bo'yicha ..." yoki oddiy tilda yozing, Claude `SKILL.md` ni o'qib bajaradi.

**Projectga yangi repo qo'shsam, Claude setupni o'zi o'rnatadimi?** Ha, agar instructionsda o'sha repo va uning stacki yozilgan bo'lsa. Yangi repo uchun instructionsga bir qator qo'shing.

**Setup qaysi versiyasi o'rnatilganini qanday bilaman?** `install.sh` qoidalar, skills va hooklarni har safar yangilaydi. Qachon yangilanganini loyiha reposidagi "Install/Update Claude Code setup" PR'laridan ko'rasiz.
