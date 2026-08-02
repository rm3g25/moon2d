# Moon 2D — карта кодовой базы

Справочник по проекту. Назначение: имея этот файл плюс описание задачи,
сразу понимать, какие файлы смотреть, без повторных раскопок репозитория.

Репозиторий: `https://github.com/rm3g25/moon2d/` · Delphi 12 + SDL2, Win32.
Логика в пространстве 512×384 игровых единиц (16×12 клеток по 32),
тайловая графика 64 px, фиксированный тик 33 Гц, уровни по экранам
(без скролла). Везде действует CODESTYLE-3.6.

Направление зависимостей (примерно снизу вверх):
`Sdl2.Core` → `Render.*` / `Audio` / `Game.Config` / `Localization` →
`Levels.Defs` / `Monsters.Defs` → `Bullets` → `Hero` / `Monsters` /
`Hud.Messages` / `Menu` / `Render.Tiles` → `Game.Loop` → `Moon2D.dpr`.

---

## Юниты игры

### `Sdl2.Core.pas` (~350 строк)
Рукописные биндинги SDL2. Классов нет — константы, записи, объявления
`external` к `SDL2.dll`.
- **Константы**: флаги инициализации, флаги окна, флаги рендерера, режимы
  доступа к текстурам, хинты (`SdlHintRenderDriver`, качество масштаба),
  идентификаторы событий, флаги отражения, формат пикселей
  `SdlPixelFormatAbgr8888`, режимы блендинга, используемые игрой сканкоды.
- **Записи**: `TSdlRect`, `TSdlFRect`, `TSdlPoint`, `TSdlRendererInfo`,
  `TSdlVersion`, `TSdlSurface`, `TSdlKeysym`, `TSdlKeyboardEvent`,
  `TSdlMouseMotionEvent`, `TSdlMouseButtonEvent`, `TSdlEvent` (вариантная).
- **Импорты**: жизненный цикл окна и рендерера, вызовы отрисовки
  (`SDL_RenderCopy/F/Ex`, заливка, очистка, present), поверхности +
  color key + конвертация формата, текстуры (включая target-текстуры и
  `SDL_RenderReadPixels` — используются в TitleCard), события, тайминг
  (`SDL_GetPerformanceCounter/Frequency`, `SDL_Delay`), `SDL_SetHint`,
  `SDL_RenderSetLogicalSize`.
- **Хелперы**: `SdlText(string)→UTF8String`, `SdlErrorText`.
- Лезть сюда, если: нужна новая функция SDL, вопросы по обработке событий
  или по ABI.

### `Render.Sprites.pas` (~345 строк)
Кэш текстур + низкоуровневая отрисовка спрайтов. Здесь же живут константы
размеров.
- **Константы**: `SpriteSize=32`, `TileSize=32` (игровые единицы!),
  `TileArtSize=64` (пиксели текстуры!), `FramesAlive=8`, `FramesDeath=8`.
  Разделение 32 против 64 — та самая дисциплина систем координат в коде.
- **`TSpriteCache`** — словарь `имя файла → PSdlTexture`, ленивая загрузка
  PNG из базовой папки, опциональный color key (`SetColorKey` /
  `DisableColorKey`). По одному кэшу на корень ассетов (textures\,
  monsters\, heroes\, weapon\, levels\...).
- **`TAnimSet`** (запись) — массивы текстур `Alive[0..7]` и `Death[0..7]`;
  `IsLoaded`. Собирается свободной функцией **`LoadAnimSet(cache, mnsFile)`**,
  которая разбирает список спрайтов `.mns`.
- **`TSpriteRenderer`** — рисует в игровых единицах: `DrawCell` (спрайтовая
  сетка), `DrawTile` (тайловая сетка), `Draw` (свободная позиция, опция
  зеркала), `DrawRect`, `DrawRotated` (рука с оружием).

### `Render.Tiles.pas` (100 строк)
- **`TTileScreenRenderer`** — рисует один экран: `DrawScreen` =
  `DrawBackground` (PNG экрана из `FBackgroundCache`, папка уровня) +
  `DrawTiles` (индексы палитры из `TLevel` через `FTileCache`, папка
  textures\). Именно это разделение фон/тайлы — точка входа для будущей
  идеи «ИИ-фоны как художественный слой».

### `Render.Font.pas` (~345 строк)
Растровый шрифт, атлас 448 px, сетка глифов 16×16 (раскладка CP1251).
- **Константы**: геометрия атласа + дословные метрики глифов из 2008
  (`SmallGlyphWidth/Height`, `BigGlyphWidth/Height`, `BigAdvanceRatio=0.8` —
  перекрытие 20%, всё выведено из NDC-математики оригинала).
- **`TFontAtlasOrientation`** = (`faUpright`, `faRotatedCw`) — фикс
  ориентации атласа.
- **`TMoonFont`** — `DrawSmall`, `DrawBig`, `DrawSmallBlock` (многострочно),
  `DrawScaled` (произвольная высота глифа — цифры обратного отсчёта),
  измерители ширины (`SmallTextWidth`, `BigTextWidth`, `ScaledTextWidth`),
  `DrawAtlas` (отладочный просмотр, клавиша F).

### `Audio.pas` (~230 строк)
Биндинги SDL2_mixer (импорты `delayed` — игра переживает отсутствие DLL)
плюс банк звуков.
- **`TMusicMode`** = (`mmLoop`, `mmOnce`).
- **`TSoundBank`** — словарь WAV-чанков и один слот музыки.
  `Load`/`Play` (sounds\), `PlayMusic`/`StopMusic` (music\, OGG),
  `ToggleMusicMuted`, `Enabled` (False, если DLL микшера нет → всё
  превращается в no-op).

### `Game.Config.pas` (~225 строк)
- **`TDifficulty`** = (`dfNormal`, `dfHard`, `dfWild`); множество
  `TDifficultyGrades`; протокольные строки `DifficultyIds`
  ('normal'/'hard'/'wild').
- **`TLanguage`** = (`lgEnglish`, `lgRussian`); `LanguageIds` ('en'/'ru').
- **`TGameConfig`** (запись) — ширина/высота окна, полноэкранный режим,
  vsync, fpsCap, tickRate, сложность, язык; фабрика `Defaults`.
- Свободные функции: `LoadGameConfig`, `SaveGameDifficulty`,
  `SaveGameLanguage` (частичная перезапись config.json).

### `Localization.pas` (~310 строк)
- **`TLocalizedText`** (запись) — `Values[TLanguage]`, `Current`.
  Используется для контента уровней и монстров (базовое поле JSON = RU,
  соседнее поле с суффиксом `En` = EN, при отсутствии — откат на базовое).
- ~60 констант-ключей `S*` (протокольные идентификаторы в словари языков):
  тикеры геймплея, подписи серий убийств, тексты хенсина и бонусов, экран
  финала, полный словарь меню.
- Свободные функции: `LoadLanguage` (подменяет плоский словарь из
  lang\en.json / ru.json), `Tr(key)`, `CurrentLanguage`,
  `ReadLocalizedText(jsonObj, key)`, `MakeLocalizedText`.

### `Levels.Defs.pas` (~390 строк)
Модель данных уровня + парсер JSON. Игровой логики нет.
- **`TEntityOverrides`** (запись) — опциональные для конкретной расстановки
  направление, скорость, жизни, canShoot (пары «флаг Has* + значение»).
- **`TDifficultyValue`** (запись) — по одному int на грейд; в JSON либо
  число, либо `{"normal":..,"hard":..,"wild":..}`; `Uniform`, `ForGrade`.
- **`TEntityTriggers`** (запись) — `BigMessage`/`SmallMessage`/`HintText`
  (локализованные), `ChangeMusic`, перестановка героя по heroX/heroY
  (вертикальные переходы), квота испытания грейвелов (`HasGravelBoss` +
  `GravelQuota: TDifficultyValue`).
- **`TEntityPlacement`** (запись) — monsterId, экран (нумерация с 1), x/y
  (спрайтовая сетка), spriteList (.mns), `Grades` (идиома doom-овских
  skill-флагов), переопределения, триггеры.
- **`TBackgroundChange`** (запись) — fromScreen + image.
- **`TLevel`** (класс) — разобранный уровень: тайлы `[экран][ряд][колонка]`,
  строки коллизий `[экран][ряд]` ('1' = стена), палитра тайлов, фоны,
  сущности, id/title/assetsDir/music/introText, размеры сетки,
  screenCount. Запросы: `TileAt`, `SolidAt`, `BackgroundFor` (побеждает
  последнее изменение). `LoadFromFile`.

### `Monsters.Defs.pas` (~440 строк)
Модель описаний монстров + реестр (парсит monsters.json). Поведения нет.
- **Перечисления**: `TMonsterCategory` (mcEnemy/Pickup/Prop/Boss),
  `TMovementKind` (mkStatic/Patrol/PatrolNoEdgeCheck/ChaseHero/BossFly),
  `TAttackPattern` (apNone/StraightSingle/StraightCluster5/AimedSingle/
  AimedDouble/RainVolley), `TPickupEffectKind` (peNone/Heal/GiveWeapon).
- **Записи**: `TMovementDef` (вид + скорость); `TAttackDef` (паттерн,
  темп стрельбы, скорость пули, параметры конкретных паттернов,
  `HasAttack`); `TPickupEffectDef` (peGiveWeapon перепрошивает оружие
  целиком: тип, перезарядка, скорость, гравитация); `TSpawnEntry`
  (monsterId + вес); `TBossDef` (endsLevelOnDeath, темп/экран/таблица
  спавна, `RageMusic`, `PickSpawn` — взвешенный рандом);
  `TMonsterDef` — полный лист: id, legacyName, displayName
  (локализовано), spriteList, категория, dangerous, affectedByGravity,
  explodesOnDeath, movement, attack, pickupEffect, lives, score, animFreq,
  deathText (локализовано), массив deathSounds, boss.
- **`TMonsterRegistry`** (класс) — владеет всеми описаниями;
  `LoadFromFile/String`, `Find`, `FindByLegacyName`, `TryFind`, `Count`,
  `AllDefs` (прогрев банка звуков), валидация таблиц спавна.

### `Bullets.pas` (~300 строк)
Снаряды + все спавнеры партиклов из 2008-го.
- **`TFanShape`** (запись) — rows/cols/baseSpeed/speedSpread формулы веера
  k/t (та самая запись по travel-тесту: один шаблон, пять носителей).
- **`TBulletStatus`** = (`bsFlying`, `bsBursting`, `bsInactive`).
- **`TBullet`** — позиция, скорость, гравитация ('dyy'), кадр анимации
  взрыва, `Contact` (участвует в перехвате пуля-против-пули).
  `Move`, `StartBurst`, `StartBurstSliding` (при ударе о стену сохраняет
  1/8 инерции).
- **`TBurst`** — владеет списком пуль и их текстурами ('bullet' — герой,
  'bull' — монстры; кадр полёта + кадры разрушения 2..8).
  `NewBullet`, `Clear` (переход между экранами стирает пули), `Update`,
  `Draw`. Спавнеры, все дословно из 2008: `SpawnExplosionFan` (веер на
  180 осколков для бочек и цепных реакций), `SpawnFan(shape)` (финал
  хенсина / осыпание ледяной формы / победные веера босса),
  `SpawnConvergingRing` (лечащие волны хенсина; Contact=True, кольцо ранит
  босса), `SpawnFireRain` (768 медленных пуль по сетке в 16 единиц),
  `SpawnStaticAura` (500 неподвижных пуль — тот самый щит-хак 2008-го).
- Известная бородавка: `TBurst.Draw` мутирует состояние симуляции
  (refactoring.md #14, блокирует интерполяцию #19).

### `Hero.pas` (~1150 строк)
Герой: физика, оружие, смерть. Здесь живут `GameWidth=512`,
`GameHeight=384`, `HeroSize=32`.
- **Перечисления**: `THeroAction` (стойка/ходьба/прыжок/падение ×
  направление), `THeroCommand` (идти/стоп влево-вправо, прыжок/отпустить),
  `THeroForm` (hfNormal/hfIce), `TPendingSide` ('ExtraInstruction' 2008-го
  — отложенное намерение вбок, исполняется, когда преграда уходит).
- **`THero`** —
  - Состояние: FX/FY (Y — линия НОГ), экран, действие, направление, кадр
    ходьбы, ускорение, форма, поля смерти (кадры 9→16, оседание трупа).
  - Оракулы коллизий (дословно из 2008): `Solid`, `CellOfX/Y`,
    `CellsOfX/Y` (спан в 32 единицы может лежать на двух клетках),
    `CanIGoLeft/Right/Up/Down`, `CanIFlyLeft/Right`,
    `WallBlocksLeft/Right` (пробы без побочных эффектов для толчков),
    `GroundUnderFeet`, `LandExactly`, `SettleOnGround`.
  - Оружие: `FBullets: TBurst`, тип 0..4 (пистолет / дробовик ×5 /
    гранатное облако ×22 / цепь ×3 / миниган с чередующимися боковыми
    выстрелами), состояние перезарядки/скорости/гравитации,
    `Fire: Boolean` (True = выстрел реально вышел из ствола → вызывающий
    играет звук), `SetWeaponAngle`, `DrawWeapon`, прицел (`DrawCrosshair`,
    кадры 1..4 = цвета умного курсора), живой тюнер дульного среза
    минигана (`NudgeMinigun`, DEBUGKEYS).
  - Жизненный цикл: `Command`, `Tick` (дословный OurHero.Timer), `Draw`,
    `SetMouse`, `PlaceAtCell`, `SetScreenX`, `SetY`, `ShoveX` (по единице,
    останавливается у стен), `ApplyWeaponPickup`, `Kill`, `Revive`.

### `Monsters.pas` (~840 строк)
Поведение монстров (управляется данными из `TMonsterDef`) плюс поле,
которое ими заведует.
- **Перечисления**: `TMonsterAction` (стойка/ходьба/падение/полёт ×4),
  `TMonsterLife` (mlAlive/Dying/Dead),
  `TMonsterEvent` (meNone/BossWantsMinion/Henshin/BossRage/LevelComplete/
  Died) — 'MessageToMain' 2008-го, игровой цикл вычерпывает их каждый тик.
- **`TMonster`** — позиция, экран, направление, жизни (+`LivesAll`), кадр
  анимации, шаг, таймер стрельбы, флаг ярости, таймер призыва миньонов
  у босса, список событий. Собственные оракулы коллизий
  (`CanGoLeftEdgeAware`/`WallOnly` — пары CanIGo*1/2 из 2008,
  `CanGoDown`), `ShoveX`. Движение: `MoveWalking`/`Falling`/`Flying`,
  `PatrolStep`. Бой: `FireAt` (паттерны из `TAttackDef`), `TakeDamage`
  (отбрасывание через оракул стен + веера взрывов + события),
  `EnrageTankIfLow`, `ProcessBossThresholds`, `BeginDying`.
  Публично: `Tick(heroX, heroY, bullets)`, `Draw`, `DrainEvent`.
- **`TMonsterField`** — владеет `TObjectList<TMonster>`, кэшем анимаций
  (.mns → `TAnimSet`), спрайтовым кэшем monsters\, `FLivesScale`
  (множитель сложности, применяется к каждому рождённому здесь монстру).
  `Tick` (текущий экран), `SpawnFromSky` (миньоны босса в случайной
  верхней клетке), `AnyAliveOnScreen` (ворота прорыва — пикапы считаются,
  дословно как в оригинале), `Draw`.

### `Hud.Messages.pas` (~310 строк)
- **`TMessageBoard`** — система сообщений 2008-го: строки тикера
  (выезд сбоку, приватная запись `TTickerLine`), большой заголовок по
  центру, бегущая строка, всплывашки очков (приватная `TScorePopup`,
  «+N» уплывает вверх). `Tick` / `Draw(alpha)` — отрисовка учитывает
  интерполяцию (бегущая строка, всплывашки).
  API: `AddTicker`, `ShowBig`, `StartMarquee`, `AddScorePopup`,
  `ClearPopups` (переход между экранами оставляет всплывашки не у дел),
  `Clear` (смерть заставляет доску замолчать).

### `Menu.pas` (~875 строк)
Главное меню с летящей луной и звёздным полем.
- **Записи**: `TLevelChoice` (имя файла + локализованное название; поиск
  файлов делает корень композиции), `TMenuResult` (команда + полезная
  нагрузка), `TMenuItem`, `TStar` (дословный TStar из MenuPic.pas: kind
  0..7 — одновременно класс скорости И индекс спрайта; текстура
  разрешается один раз на инициализации), `TMoonDrift` (дрейфующая луна
  в пространстве «sdvig» ±500 из 2008; `Respawn`, `Tick`).
- **Перечисления**: `TMenuCommand` (mcNone/StartLevel/Resume/
  ToggleFullscreen/SetDifficulty/SetLanguage/Quit), `TMenuScreen`
  (msMain/LevelSelect/Difficulty/Credits/QuitConfirm), `TItemAction`
  (внутренняя навигация против команд, всплывающих наружу).
- **`TMoonMenu`** — текстуры неба/луны/логотипа, звёзды, список пунктов на
  каждый экран, флаги языков (собственные текстуры, `FlagRect` — единая
  геометрия и для отрисовки, и для попадания), отображаемая копия
  сложности. `ShowMain`, `Tick`, `Draw(alpha)`, `DrawSky(alpha)` (экран
  истории переиспользует живое небо как декорацию), `MouseMove`,
  `Click → TMenuResult`, `HandleEscape` (True = меню съело клавишу).
  Свойства `HasActiveGame`, `Difficulty`, `Language` (сеттер пересобирает
  подписи через `Tr` — вызывать ПОСЛЕ подмены словаря).

### `Game.Loop.pas` (~390 строк)
Хост: окно и рендерер + цикл с фиксированным шагом.
- **`TGameApp`** (абстрактный) — `Update(dt)` (фиксированный),
  `Render(renderer, alpha)` (alpha — доля интерполяции),
  `HandleKey/MouseMove/MouseButton`, `RequestQuit`.
- **`TGameHost`** — создаёт окно и рендерер (хинт D3D11 живёт здесь),
  `Run(app)`: насос событий, аккумулятор фиксированных 33 Гц, заголовок с
  FPS и диагностикой худшего кадра, ожидание бюджета кадра для ветки без
  vsync. `TKeyAction` = (kaDown, kaUp).

### `Moon2D.dpr` (~1800 строк — НЕ заглушка, всегда грепать вместе с .pas)
Корень композиции + весь автомат игрового потока (`TMoonGame`).
- **Константы вверху**: имена папок ассетов, длительности тикера,
  расписание волн хенсина (`HenshinWaves[0..4]`: тик/пули/радиус), тики
  вспышки и завершения, разметка экрана финала, настройки обратного
  отсчёта (прелюдия 3..2..1 — авторское добавление 2026-го).
- **Типы**: `TGameState` (gsMenu/gsIntro/gsPlaying/gsEnding),
  `THenshinWave` (запись), `TBonusKind` (bkNone/Health/FireRain/Aura/
  Explosion).
- **`TMoonGame`** (наследует `TGameApp`) — владеет всем: реестром,
  уровнем, кэшами, рендерерами спрайтов и тайлов, героем, полем монстров,
  обоими бурстами, шрифтом, доской сообщений, банком звуков, меню.
  Ключевое состояние: состояние игры + состояние возврата, флаги
  зажатых клавиш (модель опроса клавиатуры из 2008), здоровье + окно
  неуязвимости после удара, чекпойнт X/Y, очки + серия убийств, флаги
  сработавших триггеров по сущностям, хенсин (активен/тик) + обратный
  отсчёт (цифра/тик/передача), слот бонуса (+ отложенная активация),
  испытание грейвелов (флаг атаки, квота, таймер волны, экран), таймер
  завершения уровня, список уровней + текущий файл + текущая музыка,
  полноэкранный режим и сложность.
  Группы методов:
  - Поток: `Update`, `Render`, `LoadLevel`, `StartPlaying`,
    `RestartLevel`, `AdvanceToNextLevel`, `CurrentLevelIsLast`,
    `BeginEnding`, `OpenMenu`, `ApplyMenuResult`, `ToggleFullscreen`.
  - Мир: `HandleScreenTransitions`, `ArriveOnScreen`, `HandlePitFall`,
    `FireScreenTriggers`, `TickGravelAttack`.
  - Бой: `ResolveHeroBulletHits`, `ResolveMonsterBulletHits`,
    `ResolveMonsterContact`, `RewardMonsterKill`, `HurtHero`,
    `DrainMonsterEvents`, `ProcessKillStreak`, `AwardStreakBonus`.
  - Хенсин и бонусы: `StartHenshinCountdown`/`TickCountdown`/
    `DrawCountdown`, `StartHenshin`/`TickHenshin`/`FinishHenshin`,
    `RemoveIceForm`, `CureHero`, `AwardRandomBonus`,
    `ActivateQueuedBonus`, `DrawBonusHud`.
  - Отрисовка и ввод: `DrawHud`, `DrawIntro`, `DrawEnding`,
    `DrawMessages`, `CrosshairFrame`, `HandleKey/MouseMove/MouseButton`,
    `HandleEndingClick`, отладочные тюнеры (`NudgeCrosshair`,
    `NudgeMinigunMuzzle`, `DebugBrowseScreen`).
- **Свободные функции**: `OpenWebPage`, `BonusDisplayName`, хелперы
  клеток и выхода пули за экран, `ReadLevelTitle`, `DiscoverLevels`,
  `RunGame` (собственно main: конфиг → хост → реестр → игра).

---

## Инструменты

### `tools/TitleCard/` — генератор титров для трейлера (VCL-приложение)
Печатает произвольный текст игровым растровым шрифтом и сохраняет PNG.
Переиспользует `Sdl2.Core` и `Render.Font` по относительным путям.
- **`TitleCard.dpr`** — загрузчик VCL.
- **`TitleCard.Layout.pas`** — чистая математика вёрстки. Константы:
  измеренные метрики чернил шрифта (`InkTopRatio`, `CapHeightRatio`).
  Записи: `TCardGeometry` (размер, поля, оптический центр 0.45,
  межстрочный шаг), `TCardScale` (smFitInteger/FitFree/Explicit +
  фабрики), `TPlacedLine`, `TCardLayout` (высота клетки, строки,
  предел символов, запросы о переполнении). Функции: `BuildCardLayout`,
  `WrapCardText` (аварийный перенос по словам), `SplitCards` (разбивка
  батч-файла по пустым строкам), хелперы геометрии.
- **`TitleCard.Renderer.pas`** — **`TCardRenderer`**: скрытое SDL-окно +
  target-текстура, рисует вёрстку, `RenderCard → TBytes` (RGBA сверху
  вниз) через `SDL_RenderReadPixels`. `TCardBackground` =
  (cbTransparent, cbBlack).
- **`TitleCard.Config.pas`** — запись **`TTitleCardConfig`** (путь к
  атласу, драйвер рендера, геометрия, шаги масштаба, шаблон батча),
  загрузка из JSON.
- **`TitleCard.Main.pas`** — **`TMainForm`** (VCL): мемо и комбобоксы для
  пропорций/масштаба/полей, живой предпросмотр, одиночное сохранение и
  пакетный рендер.
- **`Image.Png.pas`** — свободная функция `SavePngRgba`, самописный
  писатель PNG.

---

## Данные JSON (bin\)

### `config.json` (крошечный)
`window` (width/height/fullscreen/vsync/fpsCap) + `game` (tickRate, id
сложности, id языка). Читает `Game.Config`; сложность и язык сохраняются
поштучно.

### `monsters.json` (~11 КБ)
Ключи: `version`, `comment`, `defaults` (bound, spritesToDeath, animFreq,
score, dangerous — наследуются монстрами), массив `monsters`.
15 идентификаторов: `gravel`, `gravelFemale`, `winter`, `zombieShooter`,
`betoner`, `platform`, `tank`, `mount`, `barrel`, `medkit`,
`weaponShotgun`, `weaponGrenade`, `weapon3`, `weapon4`, `boss1`.
Разбирается `TMonsterRegistry` в `TMonsterDef` (полный лист полей —
в разделе Monsters.Defs выше: блоки movement/attack/pickup/boss,
локализованные displayName и deathText, deathSounds).

### `level1.json` (~49 КБ) / `level2.json` (~19 КБ)
Единый формат уровня, разбирается `TLevel`. Ключи: `version`, `id`,
`title`/`titleEn`, `assetsDir`, `music`, `legacyTrailing` (артефакт
миграции, чистка в очереди), `grid` (16×12), `backgrounds` (fromScreen +
image), `tilePalette` (имена текстур; индекс N в тайлах → palette[N-1]),
`tiles` (`encoding`, `emptyValue`, массив `screens` из сеток
[ряд][колонка]), `entities` (расстановки: monsterId, screen, x, y,
spriteList, опционально `difficulty` — грейды, `overrides`, `triggers` —
сообщения/подсказки/changeMusic/heroX-heroY/gravelBoss),
`introText`/`introTextEn`.
- level1: 17 экранов, 145 сущностей, палитра на 156 тайлов, 4 фона.
- level2: 9 экранов, 38 сущностей, палитра на 35 тайлов, 3 фона
  (испытание грейвелов и босс живут здесь; завершает оригинальную
  кампанию).

### `lang/en.json` / `lang/ru.json` (~2–3 КБ)
Плоские словари ключ→строка для текстов интерфейса и геймплея (все ключи
`S*` из `Localization.pas`): тикеры, серии убийств, хенсин и бонусы,
экран финала, полный словарь меню. Контента уровней и монстров здесь НЕТ
— он локализуется на месте, в JSON уровней и монстров, по схеме
«базовое поле + соседнее поле с суффиксом `En`».

---

## Быстрая таблица маршрутизации задач

| Задача пахнет как… | Смотреть |
| --- | --- |
| Движение героя / коллизии / ощущение прыжка | Hero.pas |
| Паттерны оружия / прицел | Hero.pas (+Bullets.pas) |
| Поведение монстров / ИИ / босс | Monsters.pas + Monsters.Defs.pas + monsters.json |
| Новый монстр (только данные) | monsters.json (+ассет .mns) |
| Взрывы / партиклы / визуал хенсина | Bullets.pas (+кластер хенсина в dpr) |
| Контент уровня / триггеры / экраны | levelN.json + Levels.Defs.pas |
| Поток игры / автомат состояний / очки / бонусы / испытание грейвелов | Moon2D.dpr |
| Переходы между экранами / чекпойнты | Moon2D.dpr (HandleScreenTransitions, ArriveOnScreen) |
| Меню / переключение языка | Menu.pas + Localization.pas |
| Отрисовка текста / новые подписи | Render.Font.pas + Hud.Messages.pas + языковые JSON |
| Ритм кадров / окно / vsync | Game.Loop.pas (+Sdl2.Core.pas) |
| Звук / музыка | Audio.pas (+поля данных в JSON) |
| Отрисовка тайлов и фонов | Render.Tiles.pas + Render.Sprites.pas |
| Титры для трейлера | tools/TitleCard/* |
