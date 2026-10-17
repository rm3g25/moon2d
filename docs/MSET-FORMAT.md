# The `.mset` sprite set format

A sprite set is one file holding many sprites. It exists to replace a
thousand loose files in a shipping folder with about two dozen, without
giving up the ability to see what changed, take a set apart, or load one
sprite without loading the rest.

## Layout

```
offset  size  what
     0     4  'MSET'
     4     2  version, currently 1        (word, little-endian)
     6     4  manifest size in bytes      (cardinal, little-endian)
    10     n  manifest, UTF-8 JSON
  10+n     …  every image, concatenated, no padding, no separators
```

Nothing marks where one image ends and the next begins. The manifest
carries an offset and a length for each, so reading a sprite is a seek
and a read. Searching for a separator would be slower and, worse,
ambiguous — the bytes of a separator can occur inside a PNG.

Offsets are counted from the first byte of the image block, not from the
start of the file. The manifest can grow or shrink without a single
image moving.

## Manifest

```json
{
  "id": "gravel",
  "description": "Free text, or JSON, or nothing. Whatever the author
                  wants to remember about this set.",
  "sprites": [
    { "name": "1", "description": "", "offset": 0, "size": 2148 },
    { "name": "2", "description": "", "offset": 2148, "size": 1980 }
  ],
  "sequences": [
    { "name": "alive", "description": "",
      "frames": ["1", "2", "3", "4", "5", "6", "7", "8"] },
    { "name": "death", "description": "last frame holds",
      "frames": ["d1", "d2", "d3", "d4"] }
  ]
}
```

- **`id`** — the set's name. Levels and monsters refer to sets by this,
  not by filename.
- **`description`** — free-form, on the set and on every sprite. The
  format never parses it; it is there so that a decision made today is
  still legible in a year.
- **`sprites`** — order matters: it is the order they were packed and the
  order tools list them in.
- **`sequences`** — named frame orders, each with its own free-form
  description. The engine asks for `alive` and `death`; any other name is
  legal and simply waits for something to ask for it. A frame may appear
  in several sequences — a sequence names sprites, it does not own them.
  This is what retires the `.mns` side files.

Images are stored exactly as they came off disk — raw PNG bytes, no
re-encoding, no compression on top. A PNG is already compressed, and
re-encoding art on every build is a good way to lose a pixel to a
rounding difference.

## Who owns which set

- **Monsters own their sprites.** `monsters.json` names the set; a level
  that places a monster gets its art automatically. A level never lists
  monster sets, because then two lists would have to agree, and one day
  they would not.
- **The hero is the default.** Loaded by the engine, named in no JSON.
- **Levels declare environment only** - the tiles:
  `"spriteSets": ["moon-surface", "machinery"]`. Sets are searched in the
  order declared, first match wins.
- **Backdrops and objects follow the level by convention**, one set per
  `assetsDir` and kind: `level1-backdrops`, `level1-objects`. They are
  never declared - the level has at most one of each, so a list would
  only be a second place to misspell the name. The objects set is
  optional: a level whose object art is all shared ships none.
- **Shared object art is declared**, like the tiles:
  `"objectSets": ["sky"]`. Searched after the level's own objects set, in
  the order declared. Art that more than one level shows (the Earth, the
  satellite) lives there once instead of in every level's set; a set is
  an index plus blobs read on demand, so a level pays only for the
  pictures it draws.

A bare name that two declared sets both carry would resolve silently,
and reordering the declaration would then change a picture without
changing a palette. The engine refuses to load a level that asks for
such a name and lists the offenders. Two sets merely sharing a name is
not a problem — that is what the qualifier is for. The fix is to say
which set is meant:

```json
"tilePalette": ["common:pustota", "moon-surface:moongrunt1"]
```

A qualified name resolves in the named set only and ignores declaration
order. Qualify what is ambiguous, leave the rest bare — a qualifier on
every name would be noise on the 180 names that are not in question.

Environment sets are split by theme, not by level. Tiles have always
crossed level boundaries — level 2 uses art from level 1 — so a set per
level would need duplication or cross-references from the first day.
When a theme needs more art, the set grows. A second set is created for
a new theme, never because an old one got large: sets are loaded lazily,
so size costs nothing, while a name to remember costs every time.

## The tile sets

Twelve sets hold the 2008 tile art, grouped by subject. Both levels draw
from the same folders, so the split is by what a tile depicts, not by
where it is used: brick is brick whichever level stands on it.

| set | what | tiles |
|---|---|---|
| `brickwork` | the brick wall families b1x, b2x, b3x | 24 |
| `mine-structure` | floors, wall edges, posts, hook | 11 |
| `moon-surface` | lunar ground and caves | 6 |
| `machinery` | coolers, fans, pipes, lamps, hull plating | 19 |
| `facility` | bases, crates, TEK-branded structures | 6 |
| `common` | void, screen transition | 3 |
| `conveyor` | the belt system in every variant | 25 |
| `mining-rig` | diggers and their machinery | 16 |
| `railway` | rails, wagons, platforms, posts | 20 |
| `mine-walls` | rough and TEK-panelled mine walls | 11 |
| `cargo` | goods and crates | 15 |
| `mine-interior` | doors, windows, railings, ceilings | 33 |

Four names exist twice with different pictures behind them — `mash1`,
`mash2`, `mash3` and `pustota` live in both `textures\` and
`textures\level1\`. They are routed to sets that hold no other tile of
that name, so nothing collides inside a set. A level that declares both
sides gets the first declared, which is the rule everywhere else too.

This art is finished: levels 3 and up are drawn fresh, so these twelve
sets are frozen and will not grow. The grow-do-not-multiply rule applies
to the new art, where a residential sector or a train earns its own set
the moment it is a new subject rather than more of an old one.

## Reading

Opening a set parses the manifest and stops. Image bytes are read when
something asks for them. A level declaring five sets and using three
tiles from one of them reads three tiles.

## In the repository

Sets are committed as `.mset`; the loose PNGs are not. Anything inside
can be recovered with `SpritePackCli unpack`, so keeping both would be
storing the same bytes twice.

Because a set is binary, `git diff` says only that it changed. To see
*what* changed, teach git to read it — the manifest is text, and the
tool prints it:

```
# .gitattributes
*.mset diff=mset

# .git/config
[diff "mset"]
    textconv = bin/SpritePackCli.exe list
```

Then a renamed sprite or a reordered animation shows up as a line, the
way it should.

## Tools

```
SpritePackCli pack   <folder> <out.mset> [--id <name>] [--list <file>]
SpritePackCli list   <file.mset>
SpritePackCli unpack <file.mset> <folder>
```

`pack` takes every PNG in the folder in natural order. `--list` points
at a 2008 sprite list — a monster's `.mns`, the hero's `default.txt`,
the weapon's — and splits it into named sequences by its length: sixteen
lines are `alive` and `death`, twenty-four are `walk`, `death` and
`henshin`, anything else is one group called `frames`. That is not a
guess; it is the arithmetic each 2008 loader already did, given a name.

This is a migration path, used once. Afterwards the set is the only
source — names, descriptions and frame order live in its manifest and
are edited in the tool. No authoring file sits beside a set waiting to
disagree with it, and the sprite lists retire along with the loose
images.

`unpack` writes the images back out along with `manifest.json`, so any
set can be taken apart and rebuilt. A format only its own tool can read
is a trap; this one has a way out.

The round trip is the acceptance test: pack a folder, unpack it
elsewhere, compare the bytes. Writing is deterministic — the same input
produces the same file — so a rebuilt set that did not change is not a
diff either.

## Journal

### Сессия: миграция BMP → PNG, v2.2.0 (2026-08-02)

Формат наборов спрайтов (.mset) отложен: сперва вся графика
переезжает на PNG, чтобы формат родился с одним типом картинок внутри и
не тащил версионирование с первого дня.

#### Шаг 1 — конвертация (tools/bmp2png/convert.py)

Все 471 BMP получили PNG-близнеца. Правило прозрачности снято с кода
(grep по SetColorKey), а не придумано, но по ходу работы трижды
переписывалось — исходники оказались грязнее, чем ожидалось.

**Классы файлов:**
- **alpha** (447): textures\, heroes\, weapon\, monsters\, Stars\ — их
  кэши держат color key по ТОЧНОМУ чёрному (0,0,0).
- **opaque** (24): levels\* (DisableColorKey), 8 корневых файлов и 9
  крашеных тайлов (см. ниже). Корневые НЕ запекаются сознательно: их
  прозрачность делает рантаймный цитатный код 2008 (пороги <33 / <15,
  альфа 130 логотипа, порог атласа шрифта). Запечь = сломать цитату.

**Финальное правило для alpha-класса.** Прозрачным становится пиксель,
если он чистый чёрный ИЛИ входит в почти-чёрную (макс. канал ≤ 16)
область, дотянувшуюся до края кадра, И эта область прошла один из двух
тестов:
- **тонкая** — исчезает при эрозии 3×3, то есть толщиной ≤ 2 px. Это
  бахрома от ресайза, нарисованной фигурой быть не может;
- **плоская** — один точный цвет покрывает ≥ 50% области, и этот же цвет
  сидит на рамке кадра. Это крашеная заливка фона.

Всё прочее — арт, не трогаем. Разделение проверено на данных и оказалось
не пограничным: заливка идёт 71–100% одного цвета, а ноги гравела —
5–13% доминирующего цвета на 40–100 оттенков.

**Почему потребовался тест на толщину.** Первая версия просто заливала
от края всё почти-чёрное — и съедала ноги гравела: они тёмные, толстые и
касаются фона. Тест эрозией отделяет нарисованную фигуру от бахромы.

**Крашеные тайлы → opaque целиком.** Если заливка занимает ≥ 25% кадра,
файл сохраняется непрозрачным без альфы вовсе. Ключевое наблюдение:
цвет заливки (12,12,11) игра НИКОГДА не выбивала — ключ по чистому
чёрному, — значит эти тайлы все 20 лет рисовались сплошными, такими их и
задумывали. Выбить их = пустить фон насквозь (глюк на 2 уровне при
плейтесте). Правило сработало ровно на 9 файлах: lamp, provod1..6, оба
pustota — лампы, трубы и «пустота», то есть закрывающие плитки.

**Итог:** убрано 873 857 px чистого чёрного + 26 677 px бахромы +
32 148 px заливок; 16 872 px тёмного арта сохранено (ноги и подобное).
Инвариант проверен машинно на всех файлах: цвета выживших пикселей не
изменены ни в одном. Ассеты 13.8 МБ → 4.7 МБ.

**Остаточный дефект, принят как есть:** у гравела остались открытые
чёрные разрывы у основания ног — так нарисовано в 2008. Замкнутые дыры
(4–50 px на кадр) залить можно, открытые — только кистью. Решено:
оставить.

#### Шаг 2 — игра читает PNG

Новый юнит **Sdl2.Image.pas** — биндинги SDL2_image, delayed по паттерну
Audio.pas. Отличие от миксера принципиальное: EnsureImageLib вызывается в
начале RunGame и падает честным сообщением, если DLL нет. Без звука игра
играется, без графики — нет. IMG_Quit в финальном finally: инициализация
без парной уборки — асимметрия, которой в проекте нет нигде.

Четыре точки загрузки SDL_LoadBMP_RW → IMG_Load_RW: Render.Sprites
(кэш спрайтов), Render.Font (атлас), Menu ×2 (LoadTexture /
LoadOpaqueTexture). RW-обвязка не тронута, диффы — по одному имени.

Ссылки .bmp → .png: константы кода (sky, fullmoon, logo, fonty, флаги,
Stars, target*, health, конкатенации в Bullets) и данные (все .mns,
heroes/weapon default.txt, level1/level2.json). Кросс-чек прогнан: каждая
ссылка резолвится в существующий файл.

**tools/TitleCard** тоже поправлен — он линкует Render.Font и без правок
сломался бы: fonty.png в конфиге и сообщении, Sdl2.Image в uses и dproj,
EnsureImageLib перед Application.Initialize.

SDL2_image.dll 2.8.8 win32-x86 в bin\ — PNG-декодер встроен, extra-DLL
не нужны.

**Color key в TSpriteCache оставлен включённым:** на запечённых PNG
чистого чёрного не осталось, вызов молотит воздух. Снос машинерии —
отдельным шагом, кандидат в refactoring.md.

#### Версия

2.2.0, не 2.1.2: сменился формат всех ассетов, в поставке новая DLL,
движок больше не читает BMP вообще. Старый bin\ + новый exe = чёрный
экран. Ломающее изменение данных при том же геймплее.

### Сессия: формат наборов спрайтов .mset (2026-08-02, вечер)

Возврат к задаче, отложенной ради PNG. Формат родился в чистом мире:
один тип картинок внутри, никаких «а если BMP».

#### Что решено (аргументы в скобках)

- **Один файл на набор.** Манифест внутри, не рядом. Внешний pack.json
  был отвергнут: два файла на один набор — это два источника правды,
  которые однажды разойдутся. Читаемость git-диффов добывается через
  textconv (`SpritePackCli list`), а не вторым файлом.
- **Наборы в репе, россыпь PNG — нет.** Распаковщик возвращает байты
  один в один, значит хранить и то и другое — хранить дважды. Цена:
  каждая правка картинки кладёт в историю новую копию набора; лечится
  не дроблением наборов, а привычкой коммитить пачкой.
- **Владение.** Монстр владеет своими спрайтами (`monsters.json` назовёт
  набор), герой — умолчание движка, уровень объявляет ТОЛЬКО окружение.
  Первый вариант (уровень перечисляет и монстров) отвергнут: два списка,
  которые обязаны совпадать, однажды не совпадут.
- **Тематическое деление вместо поуровневого.** Уровень 2 уже берёт
  тайлы уровня 1 — деление по уровням врёт с первого дня. Итог: 12
  наборов по сюжету изображения.
- **Ключевой довод про размер:** загрузка ленивая, поэтому размер
  набора не стоит машине ничего. Цена только человеческая — найти тайл
  в палитре редактора. Значит режем не ради загрузки, а ради глаз.
- **Именованные последовательности с описанием.** Задел: движок
  спрашивает alive/death, формат принимает любое имя. У самой
  последовательности есть свободное поле description — под скорость,
  зацикленность, кадр удара, когда что-то начнёт это читать.
- **Два exe над одним юнитом**, а не один с AttachConsole: VCL-программа
  с командной строкой не ведёт себя как консольная, и лечится это
  костылями. Логика всё равно в Sprites.Sets, обёртки тонкие.

#### Формат

10-байтовая шапка ('MSET', версия word, размер манифеста cardinal),
UTF-8 JSON, затем PNG подряд без разделителей. Границы — из манифеста
(offset+size), смещения считаются от начала блока картинок, чтобы
правка манифеста не двигала ни одного изображения. Разделителей нет
сознательно: их байты могут встретиться внутри PNG.

Спека: docs/MSET-FORMAT.md.

#### Инструменты

`SpritePackCli` (pack / list / unpack) и `pack-sets.ps1`. Списки 2008
разбираются по длине: 16 строк → alive+death, 24 → walk+death+henshin,
иначе одна группа frames. Это не эвристика — ровно так делил каждый
загрузчик 2008, длина и была форматом. Использование одноразовое,
миграционное; дальше единственный источник — манифест.

Тайлы нельзя разложить по тематическим папкам, пока игра читает их с
диска по старым путям, поэтому скрипт раскладывает во временную папку,
пакует и убирает. Костыль уедет вместе с россыпью.

#### Проверено

Круг pack → list → unpack → сравнение хешей: 16 из 16 файлов гравела
совпали побайтово. Собрано 29 наборов (15 монстров, герой, оружие, 12
тайловых), не разобранных файлов — ноль.

#### Находки по ходу

- **level2 берёт из папки level1 ровно один тайл** — `doom1`. Вся
  легендарная «второй лезет в первый» — одна плитка.
- **`textures\d8.png` побитово равен `monsters/gravel/d8.png`** и при
  этом честно используется в палитре второго уровня: кадр взрыва в
  роли тайла.
- **Четыре имени задвоены** (`mash1..3`, `pustota` в корне и в level1\)
  и это РАЗНЫЕ картинки. Разведены по разным наборам; при переходе на
  наборы одно из имён стоит переименовать.
- **Рельсы и вагоны для будущего уровня с рудным поездом уже нарисованы
  в 2008** — 20 плиток в наборе `railway`.
- **`TSpriteCache` дедуплицирует по имени файла**: `e1.png` двух
  монстров грузится один раз. В мире наборов у каждого свой `e1`, общий
  кэш исчезнет и взрывы продублируются в памяти. Некритично (мегабайты),
  но если понадобится — общий набор `shared`. Решать на шаге 3.

#### Дальше: загрузка в игре, пятью шагами

1. `TSpriteCache` учится второму источнику; наружу тот же `Get(name)`,
   папочный режим остаётся живым.
2. Один подопытный: гравел из набора, остальные из папок. Плейтест.
3. Остальные монстры и герой. Здесь умирают .mns и default.txt.
4. Окружение: `"spriteSets"` в level*.json. Здесь меняется формат
   уровней.
5. Уборка: папочный режим уходит, россыпь уходит из bin\, наборы въезжают
   в реп. **Это и будет 2.3.0** — снова ломающее изменение данных.

Инструмент сам по себе версию игры не двигает: версия маркирует игру,
а не репозиторий (тот же случай, что TitleCard).

### Сессия: движок читает наборы — шаги 1–3 (2026-08-03)

Пять шагов плана, пройдено три с половиной. Каждый шаг — плейтест,
все зелёные.

#### Шаг 1: кэш с двумя источниками

`TSpriteCache.AttachSpriteSet` — кэш переключается с папки на набор.
Набором кэш НЕ владеет (один набор может кормить несколько кэшей;
освобождает открывший). `LoadTexture` распался на `LoadSurface`
(единственное место, где источники различаются: RWFromFile против
RWFromMem из блоба) и общий конвейер. `SDL_RWFromMem` добавлен в
Sdl2.Core.

Ключевой ход миграции: в режиме набора `Get` срезает расширение, так
что `Get('1.png')` и `Get('1')` — один слот. Все старые вызовы работают
против наборов без единой правки — это и позволило переезжать по
одному подопытному.

Перегрузка `LoadAnimSet(cache, spriteSet)`: та же TAnimSet 8+8, кадры
из последовательностей alive/death, длина проверяется строго — TAnimSet
это контракт 2008 с фиксированными массивами.

#### Шаг 2: пилот-гравел

Шлюз `SetPilots = ('gravel')` в `AnimFor`. Плейтест: гравел неотличим.
Шлюз удалён на шаге 3 (удалён, не расширен — как и было записано в
комментарии).

#### Шаг 3: все монстры, герой, оружие, пули, HUD

- `AnimFor`: есть `sprites\<имя>.mset` — читаем набор, нет — папка.
  Поле владеет парами набор+кэш (TObjectList, OwnsObjects).
- Герой: `LoadSetSequences` — близнец LoadSpriteList, кормится
  манифестом. Массив 1..24 = конкатенация walk+death+henshin; молчаливое
  «17-й кадр — начало превращения» стало именем. Ровно 24 кадра или
  исключение.
- Оружие героя: последовательность frames (7), прицел target* находится
  в наборе благодаря нормализации имён.
- TBurst: оба выброса подключают weapon.mset; два открытия одного файла
  легальны (читатели не мешают друг другу).
- Health-иконка: FHudCache подключает hero.mset — тот самый 25-й спрайт
  вне последовательностей пригодился.
- `SpriteSetsDir` переехал из Monsters.pas в Render.Sprites: константа
  понадобилась двум юнитам → уровень выше, по канону.

#### Хвост плана

Шаг 4 — окружение: `"spriteSets"` в level*.json, тайлы и фоны из
тематических наборов, меню и шрифт. Единственный шаг, меняющий формат
уровней. Шаг 5 — уборка: папочный режим, россыпь PNG, .mns и default.txt
уходят; наборы въезжают в реп; тег 2.3.0.

Ловушка E2008 по дороге: анонимный `array[0..3] of AnsiChar` в записи и
в константе — разные типы; лечится именованным типом (TMsetMagic).
Записано и в карту.

### Сессия: окружение, квалификатор, уборка — шаги 4–5 (2026-08-05)

План из пяти шагов пройден. Игра целиком живёт на наборах, россыпи
картинок в поставке больше нет.

#### Шаг 4: окружение

`"spriteSets"` в level*.json — массив имён в порядке разрешения. Кэш
получил СПИСОК подключённых наборов вместо одного: первый содержащий имя
побеждает. При поиске отбрасывается не только расширение, но и путь —
`level1\doom1.png` и `doom1` один спрайт, поэтому написания 2008 в
палитрах работают без правки данных.

Тайловый кэш переехал в `LoadLevel`: с наборами он принадлежит уровню,
как фоновый всегда принадлежал. Фоны экранов идут КОНВЕНЦИЕЙ, а не
объявлением: `<assetsDir>-backdrops.mset`. Объявленный, но отсутствующий
набор — исключение, не фолбэк: фолбэк существует для имён, не для
наборов.

Раскладка тайлов: 12 тематических наборов вместо двух папок. Проверено
машинно — все 191 имя палитр разрешается.

#### Квалификатор и проверка неоднозначности

Проблема: `pustota` и `mash1..3` есть в двух наборах РАЗНЫМИ картинками.
Голое имя разрешается порядком объявления — молча. Перестановка наборов
в JSON поменяла бы картинку, не тронув палитру.

Решение из двух частей (квалификатор — идея автора):
- **`набор:имя`** — квалифицированное имя идёт только в названный набор.
  Разделитель ':' выбран потому, что не путается ни с расширением, ни с
  путём. Ключ кэша несёт квалификатор, иначе два `pustota` схлопнулись
  бы в один слот.
- **`AmbiguousNames(палитра)`** — движок отказывается грузить уровень,
  который просит ГОЛОЕ имя, живущее в нескольких объявленных наборах, и
  перечисляет виновных.

Важная поправка по ходу: первая версия проверяла НАБОРЫ (два набора с
одним именем = ошибка) и ругалась даже на уже квалифицированную палитру.
Правильный критерий — что уровень ПРОСИТ, а не что наборы содержат.

Прецедент не выдумывали: проверка сразу нашла реальный случай, второй
уровень получил `common:pustota`. Один на 191 имя.

Договорённость на будущее: редактор уровней будет ЧИТАТЬ и голые, и
квалифицированные имена, а ПИСАТЬ всегда квалифицированные. Инструмент
строже формата — здоровая асимметрия; заодно открыть-и-сохранить
нормализует палитру первого уровня без единого клика.

#### Меню, шрифт, звёзды

`ui.mset`: небо, луна, логотип, флаги, 10 звёзд, 3 атласа шрифта.
Собраны в один набор по назначению, а не по папке (звёзды лежали
отдельно). Меню получает наборы ИНЪЕКЦИЕЙ, а не ищет файлы само:
композиционный корень решает, что существует.

Введена `LoadImageSurface` — единственное место, знающее, откуда берутся
байты картинки. До неё кэш, меню и шрифт имели по своей ветке.

#### Шаг 5: уборка, двумя частями

**Часть 1 — файлы.** Удалены 471 PNG, 15 .mns, 2 default.txt. В bin
остались три DLL, четыре JSON, lang, sounds, sprites. 29 наборов вместо
505 файлов; после добавления backdrops и ui — 32.

**Часть 2 — код.** Папочный режим удалён целиком: -198 строк, +78.
Ушли FBaseDir и параметр базовой папки у кэша, .mns-перегрузка
LoadAnimSet, ReadListFrames и фолбэк-ветка героя, общий кэш монстров,
константы TexturesDir/LevelsDir/MonstersDir/HeroSkinFile/WeaponListFile,
System.Classes из трёх юнитов. `SDL_RWFromFile` в движке остался только
в Audio.

#### Ловушка, стоившая вечера

Фолбэк на папку работал ГЛУШИТЕЛЕМ: отсутствующий набор молча
подменялся диском. Плейтест меню прошёл при НЕсобранном ui.mset —
`sky.png` подхватился с диска. Ошибка вылезла только после удаления
файлов, и выглядела как ошибка формата, хотя была ошибкой сборки.

Отсюда правило, подтверждённое дважды: **фолбэк, который никто не
должен использовать, обязан быть удалён, а не оставлен на всякий
случай.** Теперь отсутствующий набор падает на старте.

Вторая причина того же вечера — мои неприменённые патчи: пачка правок
обрывалась на середине, а я верил напечатанному «ok». Проверять grep-ом
каждое изменённое место, а не отсутствие исключения.

#### Репозиторий

Наборы въехали в реп, россыпь ушла. Реп снова самодостаточен:
clone → build → играет. `.gitattributes` научен диффать .mset через
манифест (`git config diff.mset.textconv "bin/SpritePackCli.exe list"`).

Следующий тег — **2.3.0**: формат ассетов сменился второй раз за месяц,
старый bin несовместим.
