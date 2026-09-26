# Moon 2D — карта кодовой базы

Справочник по проекту. Назначение: имея этот файл плюс описание задачи, сразу
понимать, какие файлы открывать, без повторных раскопок репозитория.

Репозиторий: `https://github.com/rm3g25/moon2d/` · Delphi 10.3+ (inline var) +
SDL2, Win32. Логика в пространстве 512×384 игровых единиц (16×12 клеток по 32),
тайловая графика 64 px, фиксированный тик 33 Гц, уровни по экранам (без
скролла).

Перегенерировано на `v2.5.2`. Где карта и код расходятся, прав код.

Направление зависимостей (примерно снизу вверх):
`Sdl2.Core` / `Sprites.Sets` → `Render.*` / `Audio` / `Game.Config` /
`Game.Bonus` / `Localization` / `Hud.Draw` → `Levels.Defs` / `Monsters.Defs` /
`Hud.Health` / `Hud.Score` → `Bullets` / `Hud.Vitals` / `Hud.Charge` → `Hero` /
`Monsters` / `Hud.Messages` / `Menu` / `Render.Tiles` → `Game.Loop` →
`Moon2D.dpr`.

---

## Юниты игры

### `Sdl2.Core.pas` (~365 строк)
Рукописные биндинги SDL2. Классов нет — константы, записи, объявления
`external` к `SDL2.dll`.
- **Константы**: флаги инициализации, флаги окна (включая `SdlWindowHidden` для
  офскрин-инструментов), флаги рендерера, режимы доступа к текстурам (включая
  `Target`), хинты (`SdlHintRenderDriver`, `SdlHintRenderScaleQuality`),
  идентификаторы событий, флаги отражения, формат пикселей
  `SdlPixelFormatAbgr8888`, режимы блендинга (`None`, `Blend`, `Add` —
  последний для бликов HUD), используемые игрой сканкоды.
- **Записи**: `TSdlRect`, `TSdlFRect`, `TSdlPoint`, `TSdlRendererInfo`,
  `TSdlVersion`, `TSdlSurface` (частичное зеркало — только ведущие поля),
  `TSdlKeysym`, `TSdlKeyboardEvent`, `TSdlMouseMotionEvent`,
  `TSdlMouseButtonEvent`, `TSdlEvent` (вариантная, ветка-паддинг на 56 байт).
- **Импорты**: жизненный цикл окна и рендерера, вызовы отрисовки
  (`SDL_RenderCopy/F/Ex`, заливка, очистка, present), поверхности + color key +
  конвертация формата, текстуры (включая target-текстуры и
  `SDL_RenderReadPixels` — используются в TitleCard), события, тайминг
  (`SDL_GetPerformanceCounter/Frequency`, `SDL_Delay`), `SDL_SetHint`,
  `SDL_RenderSetLogicalSize`, `SDL_RWFromMem`.
- **Хелперы**: `SdlText(string)→UTF8String`, `SdlErrorText`.
- Лезть сюда, если: нужна новая функция SDL, вопросы по обработке событий или
  по ABI.

### `Sprites.Sets.pas` (~445 строк)
Контейнер наборов спрайтов `.mset`: JSON-манифест, за ним все картинки подряд.
Читается игрой, упаковщиком и (позже) редактором уровней — один юнит, три
вызывающих. Вся графика игры приходит из наборов, россыпь картинок больше не
поставляется. `SetQualifier` (':') живёт здесь же — редактор и упаковщик читают
тот же синтаксис.
- **Константы**: `MsetVersion=1`, `SetQualifier=':'`. Имена полей манифеста —
  константы (`KeyId`, `KeySprites`, `KeyOffset`…): опечатка в литерале
  компилируется.
- **Записи**: `TSpriteEntry` (имя, описание, offset, size — смещение от начала
  блока картинок, не от начала файла), `TSpriteSequence` (имя, описание,
  кадры), `TMsetHeader` (packed: магия, версия, размер манифеста), `TMsetMagic`
  (именованный тип — анонимный `array[0..3] of AnsiChar` не присвоится другому
  такому же).
- **`TSpriteSet`** — чтение. При открытии разбирается только манифест, байты
  картинок приходят по требованию: `ReadSprite(name)`, `Contains`,
  `SequenceFrames`; свойства `Id`, `Description`, `Entries`, `Sequences`.
- **`TSpriteSetWriter`** — запись. `AddSprite`/`AddSpriteFile`, `AddSequence`,
  `SaveToFile`. Смещения раздаются при сохранении в порядке добавления; запись
  детерминированная, поэтому неизменившийся набор пересобирается байт в байт.
  Ловит дубли имён и последовательности, ссылающиеся на отсутствующие кадры.
- Спека формата: `docs/MSET-FORMAT.md`.

### `Render.Sprites.pas` (~465 строк)
Кэш текстур + низкоуровневая отрисовка спрайтов. Здесь же живут константы
размеров.
- **Константы**: `SpriteSetsDir` ('sprites\'), `SpriteSize=32`, `TileSize=32`
  (игровые единицы!), `TileArtSize=64` (пиксели текстуры!), `FramesAlive=8`,
  `FramesDeath=8`. Разделение 32 против 64 — та самая дисциплина систем
  координат в коде.
- **`TSpriteCache`** — словарь `набор:имя → PSdlTexture`, ленивая загрузка из
  наборов, подключённых через `AttachSpriteSet` (не владеет — освобождает тот,
  кто открыл). Разрешение: квалифицированное имя (`common:pustota`) идёт только
  в названный набор; голое — в первый подключённый, который его содержит;
  **имени, которого нет ни в одном подключённом наборе, соответствует
  `ESpriteError`** — отката к папке больше нет. Путь и расширение отбрасываются
  при поиске, поэтому написания 2008 в палитрах (`level1\doom1.png`)
  по-прежнему разрешаются. `AmbiguousNames` докладывает голые имена,
  встречающиеся в нескольких наборах — они разрешились бы порядком объявления,
  ради чего квалификатор и заведён. Опциональный color key
  (`SetColorKey`/`DisableColorKey`).
- **`LoadImageSurface(spriteSet, name)`** (свободная функция) — единственное
  место, которое превращает хранимые байты в поверхность. Возвращает `nil` для
  пустого набора или неизвестного имени; формулирует ошибку вызывающий, потому
  что только он знает, для чего была картинка.
- **`TAnimSet`** (запись) — массивы текстур `Alive[0..7]` и `Death[0..7]`;
  `IsLoaded`. Собирается **`LoadAnimSet(cache, spriteSet)`** из
  последовательностей `alive` и `death` манифеста, каждая проверяется на ровно
  восемь кадров — `TAnimSet` это контракт 2008 с фиксированными массивами.
- **`TSpriteRenderer`** — рисует в игровых единицах: `DrawCell` (спрайтовая
  сетка), `DrawTile` (тайловая сетка, кроп верхних левых 64×64 воспроизведён из
  `sttextures.pas`), `Draw` (свободная позиция, опция зеркала), `DrawRect`,
  `DrawRotated` (рука с оружием). **`Origin`** (`TSdlPoint`) сдвигает каждый из
  них — точка входа тряски экрана; здесь его никто не сбрасывает, вызывающий
  ставит его перед каждым слоем, а неподвижные слои (задник, курсор, HUD)
  рисует при `NoShake`.

### `Sdl2.Image.pas` (~70 строк)
Биндинги SDL2_image, delayed-импорты по образцу `Audio.pas`. `IMG_Load_RW`
заменил `SDL_LoadBMP_RW` во всех точках загрузки. `EnsureImageLib` вызывается на
старте и падает внятным сообщением, если DLL нет: в отличие от опционального
миксера, отсутствие графики фатально.

### `Render.Tiles.pas` (~95 строк)
- **`TTileScreenRenderer`** — рисует один экран двумя слоями в порядке,
  который задаёт вызывающий: `DrawBackground` (спрайт-задник экрана через
  `FBackgroundCache`), затем `DrawTiles` (индексы палитры из `TLevel` через
  `FTileCache`). Два вызова и никакого общего: задник стоит, пока тайлы
  трясутся. Оба кэша
  наполняются композиционным корнем из `.mset`-наборов, и ни одним из них юнит
  не владеет. Это же разделение фон/тайлы — точка входа для будущей идеи
  «ИИ-фоны как художественный слой».

### `Render.Shake.pas` (~110 строк)
Тряска экрана как один метр травмы на всю игру, читаемый обратно как сдвиг
отрисовки по слоям. Только рендер: арифметика мира сдвига не видит.
- **`TShakeChannel`** = (`scWorld`, `scHero`, `scMonsters`) — мир (тайлы,
  пули) дёргается одним куском; герой и монстры едут вместе с ним плюс своя
  небольшая добавка (`FigureJitterRatio=0.25`), чтобы фигуры выглядели
  отклеенными от земли.
- **`TScreenShake`** — `AddTrauma(amount)` (мягкое насыщение `T += A·(1−T)`:
  цепочка бочек ползёт к потолку и не упирается в него), `Tick` (раз в
  логический тик: линейное остывание `TraumaDecayPerTick=0.03`, затем свежий
  бросок всех трёх сдвигов — амплитуда `T²·MaxShakeOffset(8)`, так что одна
  бочка едва заметна, а босс — потолок), `Offset(channel)`. Свой поток
  xorshift, не `Random`: тот кормит спавн-таблицу босса. `NoShake` — константа
  нулевого сдвига.
- Дозы живут в dpr (константы `*Trauma`), не здесь: что и насколько трясёт —
  политика игрового потока, этот юнит — механизм.

### `Render.Font.pas` (~350 строк)
Растровый шрифт, атлас 448 px, сетка глифов 16×16 (раскладка CP1251).
- **Константы**: геометрия атласа (`FontAtlasSize`, `FontGridCells`,
  `FontCellPx`) + дословные метрики глифов 2008, выведенные из NDC-математики
  оригинала (`LegacyColumnWidth`, `SmallGlyphWidth/Height`,
  `BigGlyphWidth/Height`, `BigAdvanceRatio=0.8` — перекрытие 20%,
  `BigGlyphAspect`).
- **`TFontAtlasOrientation`** = (`faUpright`, `faRotatedCw`) — фикс ориентации
  атласа.
- **`TMoonFont`** — принимает необязательный `TSpriteSet` (подключён, не в
  собственности) и читает атлас из него. `DrawSmall`, `DrawBig`,
  `DrawSmallBlock` (многострочно), `DrawScaled` (произвольная высота глифа —
  цифры обратного отсчёта), измерители ширины (`SmallTextWidth`, `BigTextWidth`,
  `ScaledTextWidth`), `DrawAtlas` (отладочный просмотр, клавиша F).

### `Audio.pas` (~230 строк)
Биндинги SDL2_mixer (импорты `delayed` — игра переживает отсутствие DLL) плюс
банк звуков.
- **`TMusicMode`** = (`mmLoop`, `mmOnce`).
- **`TSoundBank`** — словарь WAV-чанков и один слот музыки. `Load`/`Play`
  (sounds\, строго: плохое имя взрывается на старте, а не посреди боя),
  `PlayMusic`/`StopMusic` (music\, OGG, мягко: отсутствующий трек пропускается
  молча), `ToggleMusicMuted`, `Enabled` (False, если DLL миксера нет — тогда все
  вызовы становятся пустышками).

### `Game.Version.pas` (~20 строк)
Одна константа, `GameVersion` — единственное место, где игра знает свою
версию. Двигается вместе с git-тегом: поднимается в коммите, который становится
версией. Читают `Menu` (метка в углу) и dpr (заголовок окна). В dproj ресурса
версии нет, так что больше ничему с ней сходиться не нужно.

### `Game.Config.pas` (~255 строк)
- **`TDifficulty`** = (`dfNormal`, `dfHard`, `dfWild`); множество
  `TDifficultyGrades`; протокольные строки `DifficultyIds`
  ('normal'/'hard'/'wild'); `AllDifficultyGrades`.
- **`TLanguage`** = (`lgEnglish`, `lgRussian`); `LanguageIds` ('en'/'ru') — один
  словарь обслуживает и config.json, и имена файлов словарей.
- **`TEra`** = (`eraRemake`, `era2008`); `EraIds` ('remake'/'2008'). «Режим
  2008»: иконки здоровья, текст очков и дорожки текста оригинала на уровнях,
  объявивших `era2008` (см. `Levels.Defs`). Этот юнит хранит только желание;
  что показывает уровень, решает `TMoonGame.LevelEra`.
- **`TGameConfig`** (запись) — ширина/высота окна, полный экран, vsync, fpsCap,
  tickRate, сложность, язык, эра; фабрика `Defaults`. Любая проблема разбора
  возвращает `Defaults`: конфигурация это предпочтение, а не повод падать.
- Свободные функции: `LoadGameConfig`, `SaveGameDifficulty`,
  `SaveGameLanguage`, `SaveGameEra` (частичная перезапись config.json, молча
  переживает заблокированный файл).

### `Localization.pas` (~310 строк)
- **`TLocalizedText`** (запись) — `Values[TLanguage]`, `Current`. Используется
  для контента уровней и монстров (базовое поле JSON = RU, сосед `En` = EN,
  отсутствующий сосед откатывается на базовое при разборе).
- ~65 строковых констант-ключей `S*` (протокольные идентификаторы в словари
  языков): игровые тикеры, подписи серий, тексты хеншина и бонусов, финальный
  экран, полный словарь меню (включая строку `Режим 2008:Вкл/Выкл`).
- Свободные функции: `LoadLanguage` (подменяет плоский словарь из
  lang\en.json / ru.json, сверяясь с полным реестром ключей), `Tr(key)`,
  `CurrentLanguage`, `ReadLocalizedText(jsonObj, key)`, `MakeLocalizedText`.

### `Levels.Defs.pas` (~405 строк)
Модель данных уровня + JSON-парсер. Игровой логики нет.
- **`EmptyTile = 0`** — значение сетки 0 это ничего; N ≥ 1 отображается в
  `TilePalette[N - 1]`.
- **`TEntityOverrides`** (запись) — необязательные направление, скорость, жизни,
  canShoot для конкретной расстановки (пары флаг Has* + значение).
- **`TDifficultyValue`** (запись) — по одному целому на грейд; в JSON либо число,
  либо `{"normal":..,"hard":..,"wild":..}`; `Uniform`, `ForGrade`.
- **`TEntityTriggers`** (запись) — `BigMessage`/`SmallMessage`/`HintText`
  (локализованные), `ChangeMusic`, перестановка героя по heroX/heroY
  (вертикальные переходы), квота испытания грейвелов (`HasGravelBoss` +
  `GravelQuota: TDifficultyValue`).
- **`TEntityPlacement`** (запись) — monsterId, экран (с единицы), x/y
  (спрайтовая сетка), spriteList, `Grades` (идиома doom-овских флагов
  сложности), overrides, triggers. `SpriteList` до сих пор несёт написание 2008
  `.mns` (`gravel.mns`); основа имени называет набор `.mset`, расширение
  отбрасывается при загрузке. Переименование поля — изменение данных, у него
  будет свой шаг.
- **`TBackgroundChange`** (запись) — fromScreen + image.
- **`TLevel`** (класс) — разобранный уровень: тайлы `[экран][строка][столбец]`,
  строки коллизий `[экран][строка]` ('1' = стена), палитра тайлов, фоны,
  сущности, id/title/assetsDir/**spriteSets**/music/introText, размеры сетки,
  число экранов, `SupportsEra2008` (ключ `era2008`: True на двух уровнях, с
  которыми вышел оригинал 2008, — только там режиму 2008 есть что показать).
  `SpriteSets` — наборы окружения в порядке разрешения, только
  тайлы; задники экранов идут по соглашению `<assetsDir>-backdrops` и там не
  появляются. Запросы: `TileAt`, `SolidAt`, `BackgroundFor` (побеждает последняя
  смена). `LoadFromFile`.

### `Monsters.Defs.pas` (~440 строк)
Модель определений монстров + реестр (разбирает monsters.json). Поведения нет.
- **Перечисления**: `TMonsterCategory` (mcEnemy/Pickup/Prop/Boss),
  `TMovementKind` (mkStatic/Patrol/PatrolNoEdgeCheck/ChaseHero/BossFly),
  `TAttackPattern` (apNone/StraightSingle/StraightCluster5/AimedSingle/
  AimedDouble/RainVolley), `TPickupEffectKind` (peNone/Heal/GiveWeapon).
- **Записи**: `TMovementDef` (вид+скорость); `TAttackDef` (паттерн, темп огня,
  скорость пули, параметры конкретного паттерна, `HasAttack`);
  `TPickupEffectDef` (peGiveWeapon перепаивает всё оружие: тип, перезарядка,
  скорость, гравитация); `TSpawnEntry` (monsterId+вес); `TBossDef`
  (endsLevelOnDeath, темп/экран/таблица спавна, `RageMusic`, `PickSpawn` —
  взвешенный случайный выбор); `TMonsterDef` — полный лист: id, legacyName,
  displayName (локализованное), spriteList, category, dangerous,
  affectedByGravity, explodesOnDeath, movement, attack, pickupEffect, lives,
  score, animFreq, deathText (локализованный), массив deathSounds, boss.
- **`TMonsterRegistry`** (класс) — владеет всеми определениями;
  `LoadFromFile/String`, `Find`, `FindByLegacyName`, `TryFind`, `Count`,
  `AllDefs` (отсюда банк звуков прогревает кэш), валидация таблиц спавна.

### `Bullets.pas` (~310 строк)
Снаряды + все частичные хаки 2008.
- **`TFanShape`** (запись) — rows/cols/baseSpeed/speedSpread формулы веера k/t
  (тот самый travel-тест: один шаблон, пять носителей).
- **`TBulletStatus`** = (`bsFlying`, `bsBursting`, `bsInactive`).
- **`TBullet`** — позиция, скорость, гравитация ('dyy'), кадр анимации взрыва,
  `Contact` (участвует в перехвате пуля-в-пулю). `Move`, `StartBurst`,
  `StartBurstSliding` (удар о стену сохраняет 1/8 инерции).
- **`TBurst`** — владеет списком пуль, своим набором спрайтов и своим кэшем
  ('bullet' — герой, 'bull' — монстры; кадр полёта + кадры разрушения 2..8).
  `NewBullet`, `Clear` (переходы между экранами стирают пули), `Update`, `Draw`.
  Спавнеры, все дословно из 2008: `SpawnExplosionFan` (веер из 180 осколков для
  бочек и цепных реакций), `SpawnFan(shape)` (финал хеншина / осыпание ледяной
  формы / победа над боссом), `SpawnConvergingRing` (лечащие волны хеншина;
  Contact=True, поэтому кольцо ранит босса), `SpawnFireRain` (768 медленных пуль
  по сетке в 16 единиц), `SpawnStaticAura` (неподвижные пули — щитовой хак 2008,
  урезан до 250 в 2.1.1).
- Известная бородавка: `TBurst.Draw` продвигает кадры взрывов, то есть меняет
  состояние симуляции из пути отрисовки. Именно это блокирует интерполяцию
  рендера для игрового мира.

### `Hero.pas` (~1170 строк)
Герой: физика, оружие, смерть. Владеет `GameWidth=512`, `GameHeight=384`,
`HeroSize=32`.
- **Перечисления**: `THeroAction` (стоит/идёт/прыгает/падает × направление),
  `THeroCommand` (идти/стоп влево-вправо, прыжок/стоп прыжка), `THeroForm`
  (hfNormal/hfIce), `TPendingSide` ('ExtraInstruction' из 2008 — отложенное
  боковое намерение, исполняемое, когда преграда исчезнет).
- **`THero`** —
  - Графика: `hero.mset` (24 кадра как последовательности `walk`, `death`,
    `henshin`) плюс набор оружия, оба в собственности; `OpenFrames` достаёт
    именованные последовательности из набора.
  - Состояние: FX/FY (Y — линия СТОП), экран, действие, направление, кадр
    ходьбы, ускорение, форма, поля смерти (кадр 9→16, оседание трупа).
  - Оракулы коллизий (дословно 2008): `Solid`, `CellOfX/Y`, `CellsOfX/Y`
    (пролёт в 32 единицы, накрывающий две клетки), `CanIGoLeft/Right/Up/Down`,
    `CanIFlyLeft/Right`, `WallBlocksLeft/Right` (пробы без побочных эффектов для
    толчков), `GroundUnderFeet`, `LandExactly`, `SettleOnGround`.
  - Оружие: `FBullets: TBurst`, тип 0..4 (пистолет / дробовик×5 / гранатное
    облако×22 / цепь×3 / миниган с чередующимися боковыми выстрелами),
    состояние перезарядки/скорости/гравитации, `Fire: Boolean` (True = выстрел
    действительно покинул ствол, и вызывающий даёт звук), `SetWeaponAngle`,
    `DrawWeapon`, прицел (`DrawCrosshair`, кадры 1..4 — цвета умного курсора),
    живой тюнер дула минигана (`NudgeMinigun`, DEBUGKEYS).
  - Жизненный цикл: `Command`, `Tick` (дословно OurHero.Timer), `Draw`,
    `SetMouse`, `PlaceAtCell`, `SetScreenX`, `SetY`, `ShoveX` (по единице,
    останавливается о стену), `ApplyWeaponPickup`, `Kill`, `Revive`.

### `Monsters.pas` (~830 строк)
Поведение монстров (управляется данными `TMonsterDef`) плюс поле, которое ими
распоряжается.
- **Перечисления**: `TMonsterAction` (стоит/идёт/падает/летит×4),
  `TMonsterLife` (mlAlive/Dying/Dead), `TMonsterEvent`
  (meNone/BossWantsMinion/Henshin/BossRage/LevelComplete/Died) —
  'MessageToMain' из 2008, игровой цикл вычерпывает их каждый тик.
- **`TMonster`** — позиция, экран, направление, жизни (+`LivesAll`), кадр
  анимации, шаг, таймер огня, флаг ярости, таймер миньонов босса, одноразовый
  флаг хеншина, список событий. Собственные оракулы коллизий (пары
  `CanGoLeftEdgeAware`/`WallOnly` = CanIGo*1/2 из 2008, `CanGoDown`), `ShoveX`.
  Движение: `MoveWalking`/`Falling`/`Flying`, `PatrolStep`. Бой: `FireAt`
  (паттерны из `TAttackDef`), `TakeDamage` (отбрасывание через оракул стены +
  веера взрывов + события), `EnrageTankIfLow`, `ProcessBossThresholds`,
  `BeginDying`. Публично: `Tick(heroX, heroY, bullets)`, `Draw`, `DrainEvent`.
  `FSecret` объявлен и всегда False — флага расстановки, которого он ждёт, в
  формате уровня пока нет.
- **`TMonsterField`** — владеет `TObjectList<TMonster>`, кэшем анимаций по имени
  spriteList из расстановки и одним `TSpriteSet` плюс одним `TSpriteCache` на
  монстра (всё в собственности; `AnimFor` открывает `sprites\<основа>.mset` при
  первом обращении). `FLivesScale` — множитель сложности, применяемый к каждому
  монстру, рождённому в этом поле. `Tick` (текущий экран), `SpawnFromSky`
  (миньоны босса в случайной верхней клетке), `AnyAliveOnScreen` (ворота
  прорыва — пикапы считаются, дословно), `Draw`.

### `Hud.Messages.pas` (~325 строк)
- **`TTextLanes`** (запись) — где идут бегущая строка и стопка тикера:
  `MarqueeY`, `TickerTopY`. Два готовых набора: `LanesUnderIcons` (24/36, под
  иконками здоровья 2008) и `LanesUnderMonitor` (40/52, под кардиомонитором);
  композиционный корень выбирает по эре.
- **`TMessageBoard`** — система сообщений 2008: строки тикера (выезд, приватная
  запись `TTickerLine`), большой заголовок посреди экрана, бегущая строка,
  всплывающие очки (приватная `TScorePopup`, поднимающееся '+N'). `Tick` /
  `Draw(alpha)` — отрисовка учитывает интерполяцию (бегущая строка, всплывашки).
  API: `AddTicker`, `ShowBig`, `StartMarquee`, `AddScorePopup`, `ClearPopups`
  (переход между экранами оставляет всплывашки над чужой геометрией), `Clear`
  (смерть заставляет доску замолчать), свойство `Lanes`.

### `Game.Bonus.pas` (~25 строк)
Словарь бонусной рулетки, общий для игры, которая её крутит, и HUD, который её
показывает: **`TBonusKind`** (bkNone/Health/FireRain/Aura/Explosion; bkNone =
пустой слот) и `BonusCost=50`. С 2.5.2 цена списывается при активации
награды, а не при выпадении, поэтому счёт продолжает расти за 50, пока награда
ждёт.

### `Hud.Draw.pas` (~175 строк)
Кисть, общая для HUD-панелей, нарисованных примитивами. Ни спрайта, ни атласа
шрифта.
- **`TRgb`** (запись); палитра типизированными константами (`CalmColor`
  голубой, `WaryColor` янтарный, `AlarmColor` красный, `BonusColor` салатовый +
  `BonusShade`, `CalmShade`, `PanelColor`, `White`); `Mix` (интерполяция).
- **`TXorShift`** (запись) — собственный поток случайных чисел для украшений
  HUD; `Random` кормит таблицу спавна босса, и искра не имеет права его
  трогать.
- **`THudBrush`** — `Fill` (прямоугольник с альфой в игровых юнитах), `Glow`
  (аддитивно), `Frame` (рамка в один юнит из четырёх прямоугольников),
  `DrawNumber` (пиксельные цифры 3×5; `NumberWidth` измеряет),
  `BeginDraw`/`EndDraw` (режим блендинга включить и выключить — остальная игра
  рисует непрозрачно).
- Общая геометрия панелей обоих углов: `PanelMargin=6`, `PanelY=4`,
  `PanelH=32`, `PanelW=118`, `ReadoutY`, ряд ячеек (`CellY`, `CellW=7`,
  `CellH=4`, `CellGap=1`), `DigitPixel=3`.

### `Hud.Health.pas` (~90 строк)
Индикатор здоровья героя, по классу на эру.
- **`THealthHud`** (абстрактный) — `Tick(health, invulnerable)` раз в логический
  тик, `Draw`. Игра держит один и не спрашивает, какой; класс выбирает
  `ApplyLevelEra` в dpr.
- **`THealthIcons`** — индикатор 2008: по одному шарику `health` из `hero.mset`
  на очко здоровья, слева сверху, с шагом 18 юнитов (владеет своим набором и
  кэшем).

### `Hud.Vitals.pas` (~365 строк)
Индикатор здоровья ремейка: кардиомонитор в левом верхнем углу, нарисованный
одной кистью. **`THudVitals`** (наследует `THealthHud`).
- `HealthyHealth=5` (константа интерфейса): базовый ряд из пяти ячеек; пустые
  остаются контурами, так что hard/wild стартуют заметно ранеными. Здоровье
  выше пяти — бонус, салатовые ячейки за разделителем (потолок лечения 10).
- Дорожка ЭКГ: кольцевой буфер на 88 сэмплов, два сэмпла за тик, форма удара
  PQRST, темп по здоровью (62 уд/мин с бонусом, 70 при 4–5, 92, 118, 152 при
  1), прямая при нуле, шум 10 тиков после удара; тёмный разрыв в 4 сэмпла перед
  бегунком, след гаснет с возрастом.
- Число: цифры 3×5, салатовое пока есть бонус, мигает при 1.
- Наблюдает, а не слушает: реагирует на разницу между тиками (вспышка
  потерянной ячейки, свечение выросшей, белая волна по кардиограмме при
  лечении, красная рамка при ударе, белое мигание ячеек в окне милосердия).

### `Hud.Score.pas` (~65 строк)
Индикатор очков, по классу на эру — близнец `Hud.Health`.
- **`TScoreHud`** (абстрактный) — `Tick(score, streak, bonus)`, `Draw`.
- **`TScoreText`** — индикатор 2008: `Score: N` малым шрифтом справа сверху
  (принимает шрифт и ширину экрана).

### `Hud.Charge.pas` (~365 строк)
Индикатор очков ремейка: заряд бонуса в правом верхнем углу, близнец
кардиомонитора. **`THudCharge`** (наследует `TScoreHud`).
- Число (36 юнитов, три цифры, потолок 999), шкала до `BonusCost` с риской на
  каждые десять очков (жёсткая пружина, чтобы убийство читалось рывком) и серия
  убийств рядом из десяти ячеек (`StreakGoal`) — те десять убийств без
  царапины, которые игра награждает, но никогда не показывала.
- Ждущая награда делает шкалу салатовой и дышащей, с врезанным значком 9×9
  (`HealthIcon`/`FireRainIcon`/`AuraIcon`/`ExplosionIcon` как списки
  прямоугольников) и бликом раз в 2 с; при выпадении летят искры; при трате
  рамка вспыхивает белым.
- Концы серии различаются по очкам: сброс с очками = десятый убитый заплатил
  (белая вспышка), сброс без очков = удар (красная вспышка по потерянным
  ячейкам).

### `Menu.pas` (~990 строк)
Главное меню с летящей луной и звёздным полем.
- **Записи**: `TLevelChoice` (имя файла + локализованное название; поиск делает
  композиционный корень, он владеет файловой системой), `TMenuResult` (команда +
  полезная нагрузка), `TMenuItem`, `TStar` (дословный TStar из MenuPic.pas: вид
  0..7 — И класс скорости, И индекс спрайта; текстура разрешается один раз на
  старте), `TMoonDrift` (дрейфующая луна в пространстве «сдвига» 2008 ±500;
  `Respawn`, `Tick`).
- **Перечисления**: `TMenuCommand` (mcNone/StartLevel/Resume/ToggleFullscreen/
  SetDifficulty/SetLanguage/SetEra/Quit), `TMenuScreen` (msMain/LevelSelect/
  Difficulty/Credits/QuitConfirm), `TItemAction` (внутренняя навигация против
  всплывающих наружу команд; `iaToggleEra` переключает строку `Режим 2008` на
  месте — двум состояниям подменю не нужно), **`TShowcaseKind`** (skNone/skLogo/skSky) — кадры для
  трейлера: живое небо само по себе, с логотипом или без. Войти туда можно
  только отладочными клавишами, поэтому с выключенным DEBUGKEYS состояние
  остаётся skNone.
- **`TMoonMenu`** — текстуры неба, луны и логотипа, звёзды, список пунктов на
  каждый экран, флаги языков (текстуры в собственности; `FlagRect` — геометрия
  И отрисовки, И попадания), отображаемая копия сложности. Принимает набор ui и
  набор оружия (подключены, не в собственности). `ShowMain`, `Tick`,
  `Draw(alpha)`, `DrawSky(alpha)` (экран истории переиспользует живое небо как
  декорацию), `MouseMove`, `Click → TMenuResult`, `HandleEscape` (True =
  поглощено), `ShowShowcase`/`ShowcaseActive`/`EndShowcase`, `DrawVersion`
  (метка `vX.Y.Z` в правом нижнем углу каждого экрана меню). Свойства
  `HasActiveGame`, `Difficulty`, `Era`, `Language` (сеттер пересобирает подписи
  через `Tr` — присваивать ПОСЛЕ подмены словаря).

### `Game.Loop.pas` (~385 строк)
Хост: окно и рендерер плюс цикл с фиксированным шагом.
- **`TGameApp`** (абстрактный) — `Update(dt)` (фиксированный),
  `Render(renderer, alpha)` (alpha — доля интерполяции),
  `HandleKey/MouseMove/MouseButton`, `RequestQuit`.
- **`TGameHost`** — создаёт окно и рендерер (хинт D3D11 живёт здесь),
  `Run(app)`: насос событий, фиксированный аккумулятор 33 Гц, fps в заголовке с
  диагностикой худшего кадра, ожидание бюджета кадра для пути без vsync.
  `TKeyAction` = (kaDown, kaUp).

### `Moon2D.dpr` (~2025 строк — НЕ заглушка, всегда грепать вместе с .pas)
Композиционный корень плюс вся машина состояний игрового потока (`TMoonGame`).
- **Константы вверху**: шаблон поиска уровней, имя файла конфигурации, имена
  папок ассетов (`SoundsDir`, `MusicDir`), карта «оружие → звук выстрела»,
  именованные одиночные звуки, выезд подписи бонуса (сама цена живёт в
  `Game.Bonus`), `VictoryMusicFile`, `MenuMusicFile`, `LevelEndLingerTicks=400`,
  здоровье героя и множители жизней монстров по сложности, темп испытания
  грейвелов, длительности тикера, расписание волн хеншина
  (`HenshinWaves[0..4]`: тик/пули/радиус), тики вспышки и финала, дозы тряски
  экрана (`ExploderTrauma`, `HenshinWaveTrauma`, `HenshinFinishTrauma`,
  `BossBlastTrauma`, `BonusExplosionTrauma`, `BonusFireRainTrauma` — добавление
  2026), строки макета финального экрана, настройка обратного отсчёта
  (прелюдия 3..2..1 — тоже 2026).
- **Типы**: `TGameState` (gsMenu/gsIntro/gsPlaying/gsEnding), `THenshinWave`
  (запись).
- **`TMoonGame`** (наследует `TGameApp`) — владеет всем: реестр, уровень, наборы
  спрайтов уровня и оба его кэша, наборы ui и оружия, рендереры спрайтов и
  тайлов, герой, поле монстров, оба всплеска пуль, шрифт, доска сообщений,
  тряска экрана, банк звуков, меню и два угловых HUD (`THealthHud`,
  `TScoreHud` — рождаются заново с каждым уровнем, ведь эра может отличаться).
  Ключевое состояние: состояние игры + состояние возврата, флаги
  удерживаемых клавиш (опросная модель клавиатуры 2008), здоровье + окно
  милосердия, таймер game over, чекпойнт X/Y, очки + серия убийств, флаги
  сработавших триггеров по сущностям, хеншин (активен/тик) + обратный отсчёт
  (цифра/тик/передача), слот бонуса (+ отложенная активация), испытание
  грейвелов (флаг атаки, квота, таймер волны, экран), таймер конца уровня,
  список уровней + текущий файл + текущая музыка, полный экран, сложность и
  эра (желание игрока; `LevelEra` = желание И `SupportsEra2008` уровня).
  Кластеры методов:
  - Поток: `Update`, `Render` (порядок слоёв там и есть спецификация тряски:
    задник стоит, тайлы + пули на канале мира, монстры и герой на своих,
    курсор и HUD стоят), `LoadLevel`, `StartPlaying`, `RestartLevel`,
    `AdvanceToNextLevel`, `CurrentLevelIsLast`, `BeginEnding`, `OpenMenu`,
    `ApplyMenuResult`, `ToggleFullscreen`, `PreloadSounds`, `LevelEra`,
    `ApplyLevelEra` (строит оба угловых HUD и ставит дорожки текста по эре —
    при загрузке уровня и снова, когда меню переключает режим посреди игры).
  - Мир: `HandleScreenTransitions`, `ArriveOnScreen`, `HandlePitFall`,
    `FireScreenTriggers`, `TickGravelAttack`.
  - Бой: `ResolveHeroBulletHits`, `ResolveMonsterBulletHits`,
    `ResolveMonsterContact`, `RewardMonsterKill`, `HurtHero`,
    `DrainMonsterEvents` (здесь же взрывы и удары босса доливают тряску),
    `ProcessKillStreak`, `AwardStreakBonus`.
  - Хеншин и бонусы: `StartHenshinCountdown`/`TickCountdown`/`DrawCountdown`,
    `StartHenshin`/`TickHenshin`/`FinishHenshin`, `RemoveIceForm`, `CureHero`,
    `AwardRandomBonus`, `ActivateQueuedBonus` (списывает `BonusCost` при
    использовании), `DrawBonusHud`.
  - Отрисовка и ввод: `DrawIntro`, `DrawEnding`, `DrawCenteredBig`,
    `HitEndingLine`, `HandleEndingClick`, `DrawMessages`, `CrosshairFrame`,
    `HandleKey/MouseMove/MouseButton`.
  - Отладка: `HandleDebugKey`, `HandleDebugMenuKey`, `UpdateInspectorCaption`,
    `DrawAtlasOverlay` — четыре двери, через которые ходит отладочная
    клавиатура, и больше никаких. Все четыре существуют в любой сборке, их тела
    компилируются в ничто, поэтому ни одному вызывающему не нужен ifdef. За
    ними: `NudgeCrosshair`, `NudgeMinigunMuzzle`, `DebugBrowseScreen`.
- **Свободные функции**: `OpenWebPage`, `BonusDisplayName`, хелперы клеток пуль
  и выхода за экран, `ReadLevelTitle`, `DiscoverLevels`, `RunGame` (настоящий
  main: конфиг → хост → реестр → игра).

---

## Инструменты

### `tools/SpritePack/` — упаковщик наборов спрайтов (консоль)
Собирает и осматривает `.mset`. Обёртка над `Sprites.Sets` и больше ничего.
- **`SpritePackCli.dpr`** (~350 строк) — команды `pack` / `list` / `unpack`.
  `pack` берёт все PNG в папке в натуральном порядке (2 раньше 10); `--list`
  разбивает список спрайтов 2008 на именованные последовательности по его длине
  (16 строк → alive+death, 24 → walk+death+henshin, иначе одна группа).
  `unpack` пишет картинки плюс `manifest.json`, так что набор всегда можно
  разобрать.
- **`pack-sets.ps1`** — собирает все наборы за один прогон и держит таблицы
  тайловых тем: первый совпавший шаблон забирает имя, остатки пакуются отдельно
  и докладываются, чтобы ничего не исчезло тихо. Пересобирает наборы из рабочей
  копии россыпи графики — в поставке её нет, поэтому это инструмент
  сопровождения, а не шаг сборки.
- Планируется VCL-половина (`SpritePack.exe`, правка спрайтов и описаний);
  логика остаётся в `Sprites.Sets`, чтобы оба исполняемых файла были тонкими.

### `tools/TitleCard/` — генератор титров для трейлера (VCL-приложение)
Рисует произвольный текст шрифтом игры в PNG. Переиспользует `Sdl2.Core`,
`Sprites.Sets` и `Render.Font` по относительному пути — открывает `ui.mset` и
просит спрайт `fonty`, тем же путём, каким ходит игра.
- **`TitleCard.dpr`** — VCL-бутстрап.
- **`TitleCard.Layout.pas`** (~355 строк) — чистая математика раскладки.
  Константы: измеренные метрики «чернил» шрифта (`InkTopRatio`,
  `CapHeightRatio`). Записи: `TCardGeometry` (размер, поля, оптический центр
  0.45, межстрочный интервал), `TCardScale` (smFitInteger/FitFree/Explicit +
  фабрики), `TPlacedLine`, `TCardLayout` (высота ячейки, строки, лимит символов,
  запросы переполнения). Функции: `BuildCardLayout`, `WrapCardText` (аварийный
  перенос по словам), `SplitCards` (пакетный файл, деление по пустым строкам),
  хелперы геометрии.
- **`TitleCard.Renderer.pas`** (~165 строк) — **`TCardRenderer`**: скрытое окно
  SDL плюс target-текстура, рисует раскладку, `RenderCard → TBytes` (RGBA сверху
  вниз) через `SDL_RenderReadPixels`. `TCardBackground` = (cbTransparent,
  cbBlack).
- **`TitleCard.Config.pas`** (~170 строк) — запись **`TTitleCardConfig`** (путь
  к набору, имя спрайта шрифта, драйвер рендера, геометрия, шаги масштаба,
  пакетный шаблон), загрузка и сохранение ini, `ResolveSpriteSet` (поднимается
  на шесть папок вверх в поисках набора).
- **`TitleCard.Main.pas`** (~425 строк) — **`TMainForm`** (VCL): мемо плюс
  комбо-боксы для соотношения сторон, масштаба и полей, живой предпросмотр,
  одиночное сохранение и пакетный рендер.
- **`Image.Png.pas`** (~190 строк) — свободная функция `SavePngRgba`,
  рукописный писатель PNG.

### `tools/bmp2png/convert.py`
Разовая миграция BMP→PNG с зашитым правилом color key (чистый чёрный →
прозрачность). Оставлен для истории; сейчас его никто не вызывает.

---

## Данные времени выполнения (`bin\`)

### `config.json` (крошечный)
`window` (width/height/fullscreen/vsync/fpsCap) + `game` (tickRate,
идентификатор сложности, идентификатор языка, идентификатор эры). Читается
`Game.Config`; сложность, язык и эра сохраняются обратно поодиночке.

### `monsters.json` (~11 КБ)
Ключи: `version`, `comment`, `defaults` (bound, spritesToDeath, animFreq, score,
dangerous — наследуются монстрами), массив `monsters`. 15 идентификаторов:
`gravel`, `gravelFemale`, `winter`, `zombieShooter`, `betoner`, `platform`,
`tank`, `mount`, `barrel`, `medkit`, `weaponShotgun`, `weaponGrenade`,
`weapon3`, `weapon4`, `boss1`. Разбирается `TMonsterRegistry` в `TMonsterDef`
(полный лист полей см. в Monsters.Defs выше). У девяти из пятнадцати нет
`spriteList` — он приходит из расстановки в уровне.

### `level1.json` (~49 КБ) / `level2.json` (~19 КБ)
Единый формат уровня, разбирается `TLevel`. Ключи: `version`, `id`,
`title`/`titleEn`, `era2008` (true у обоих: режим 2008 действует здесь),
`assetsDir`, **`spriteSets`** (наборы окружения в порядке разрешения), `music`,
`legacyTrailing` (артефакт миграции, чистка не сделана),
`grid` (16×12), `backgrounds` (fromScreen + image), `tilePalette` (имена
спрайтов; индекс N в тайлах → palette[N-1]), `tiles` (`encoding`, `emptyValue`,
массив `screens` из сеток [строка][столбец]), `entities` (расстановки:
monsterId, screen, x, y, spriteList, необязательные грейды `difficulty`,
`overrides`, `triggers` — сообщения/подсказки/changeMusic/heroX-heroY/
gravelBoss), `introText`/`introTextEn`.
- level1: 17 экранов, 145 сущностей, палитра из 156 тайлов, 5 фонов (пятый —
  `_black` для целиком замощённых экранов лаборатории 12–13); наборы
  `brickwork mine-structure facility conveyor mining-rig railway mine-walls
  cargo mine-interior`.
- level2: 9 экранов, 38 сущностей, палитра из 35 тайлов, 3 фона; наборы
  `moon-surface machinery facility common mine-interior`. Здесь живут испытание
  грейвелов и босс, и на этом кампания оригинала кончается.

### `sprites\*.mset` (32 набора)
- **Герой и оружие**: `hero` (последовательности walk/death/henshin плюс иконка
  здоровья режима 2008), `weapon` (кадры оружия в руках, пули, прицел), `weapon1`–`weapon4`
  (подбираемое).
- **Сущности**: `gravel`, `gravel2`, `vinter`, `shoot1`, `betoner`, `barrel`,
  `medic`, `krep`, `platform`, `tank`, `boss1` — на них ссылается `spriteList`
  расстановки, всё ещё написанием `<основа>.mns`.
- **Тайловые темы**: `brickwork`, `cargo`, `common`, `conveyor`, `facility`,
  `machinery`, `mine-interior`, `mine-structure`, `mine-walls`, `mining-rig`,
  `moon-surface`, `railway` — сгруппированы по предмету, а не по уровню, потому
  что уровни делят тайлы.
- **Задники**: `level1-backdrops`, `level2-backdrops` — находятся по соглашению
  `<assetsDir>-backdrops`, в `spriteSets` не объявляются никогда.
- **Интерфейс**: `ui` — небо, полная луна, логотип, спрайты звёзд, флаги языков
  и атласы `font`/`fontx`/`fonty`.

### `lang/en.json` / `lang/ru.json` (~2–3 КБ)
Плоские словари ключ→строка для текстов интерфейса и игры (все ключи `S*` из
`Localization.pas`): тикеры, серии, хеншин и бонусы, финальный экран, полный
словарь меню. Контента уровней и монстров здесь НЕТ — он локализован на месте, в
JSON уровней и монстров, по схеме «базовое поле + сосед `En`».

### `sounds/` (18 WAV) и `music/` (OGG)
Одиночные звуки грузятся строго на старте, музыка — мягко. Треки, на которые
ссылаются данные: `moon.ogg` (меню), `moon_surface.ogg`, `underground.ogg`,
`moon_surface2.ogg`, `boss1.ogg`, `hallu.ogg`, `under01.ogg`, `boss2.ogg`,
`win.ogg`.

---

## Быстрая таблица маршрутизации задач

| Задача пахнет как… | Смотреть |
| --- | --- |
| Движение героя / коллизии / ощущение прыжка | Hero.pas |
| Паттерны оружия / прицел | Hero.pas (+Bullets.pas) |
| Поведение монстров / ИИ / босс | Monsters.pas + Monsters.Defs.pas + monsters.json |
| Новый монстр (только данные) | monsters.json + набор `.mset` (spriteList хранит написание `.mns`) |
| Взрывы / частицы / визуал хеншина | Bullets.pas (+кластер хеншина в dpr) |
| Контент уровня / триггеры / экраны | levelN.json + Levels.Defs.pas |
| Игровой поток / машина состояний / очки / бонусы / испытание грейвелов | Moon2D.dpr |
| Панели кардиомонитора / заряда бонуса: вид, цвета, тайминги | Hud.Vitals.pas / Hud.Charge.pas (+Hud.Draw.pas — кисть и палитра) |
| Режим 2008: что переключает, где действует | Moon2D.dpr (`LevelEra`, `ApplyLevelEra`) + Game.Config.pas + `era2008` в levelN.json + Hud.Health.pas / Hud.Score.pas |
| Переходы между экранами / чекпойнты | Moon2D.dpr (HandleScreenTransitions, ArriveOnScreen) |
| Меню / переключение языка / кадры трейлера | Menu.pas + Localization.pas |
| Отрисовка текста / новые подписи | Render.Font.pas + Hud.Messages.pas + JSON языков |
| Ритм кадров / окно / vsync | Game.Loop.pas (+Sdl2.Core.pas) |
| Звук / музыка | Audio.pas (+поля данных в JSON) |
| Отрисовка тайлов и фонов | Render.Tiles.pas + Render.Sprites.pas |
| Тряска экрана: дозы, что трясётся, что стоит | Moon2D.dpr (константы `*Trauma`, `Render`, `DrainMonsterEvents`) + Render.Shake.pas |
| Имя спрайта разрешается не в ту картинку | Render.Sprites.pas (Get, AmbiguousNames) + порядок `spriteSets` уровня |
| Монстр или герой грузит не те кадры из набора | Monsters.pas AnimFor / Hero.pas OpenFrames |
| Наборы спрайтов / формат `.mset` | Sprites.Sets.pas + docs/MSET-FORMAT.md |
| Упаковка или осмотр наборов | tools/SpritePack/* |
| Титры для трейлера | tools/TitleCard/* |
| Загрузка PNG / графическая DLL | Sdl2.Image.pas |
