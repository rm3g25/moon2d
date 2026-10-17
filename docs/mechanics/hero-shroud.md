# Покров героя - дизайн и план по коммитам

Статус (2026-10-08): этапы 1 и 2 в main, версия 3.0.47. Следом коммит
правок после живого прогона (`Polish the hero shroud`, версия та же):
туман, оторвавшийся от героя, и рука во время сборки. Дальше этап 3 -
тесты. В разделах ниже описано то, что есть в коде.

Числа облика сняты со стенда "Покров героя Moon2D" (артефакт, версия 3):
тот же счёт, что в игре (экран 512x384, 33 тика), настоящие кадры из
hero.mset. Запись под стендом вставляется в код как есть. Числам стенда
можно верить как отправной точке; судья - живой прогон.

## Зачем
Герой появляется и переодевается без картинки: после лунки он просто
стоит на чекпойнте, костюм льда надевается сменой кадра. Нужно:
- появление героя (после лунки, на первом экране уровня, после смерти) -
  классика: светлые горизонтальные дымные полосы;
- сразу после того, как костюм льда надет, герой светится.

Это одна задача, а не две: картинка поверх кадра героя, которая живёт по
своим часам и гаснет. Разное в ней только числа.

## Имя
`shroud` - покров. Модуль `Game/Game.Shroud.pas`, запись вида
`TShroudLook`, счёт `THeroShroud`, рисование `TShroudPainter`.
Внутри три слова, не путать:
- `band` - полоса дыма и света вокруг героя;
- `strip` - ломтик кадра героя (кадр режется на 16 горизонтальных);
- `mist` - туман: полоса, дошедшая до ступней и оторвавшаяся от героя.

Слово `aura` занято орбами (`Orbs.Aura`), `glow` - модулем `Render.Glow`.

## Решено
- Один модуль вида на все сценарии; сценарий - запись `TShroudLook`.
- Логика не сливается: церемония остаётся в `Game.Henshin`, чекпойнт и
  урон - в `Moon2D.dpr`. Они только зовут `Start` с нужной записью.
- Управление у героя не отбирается ни в одном сценарии. Эффект идёт
  поверх.
- Свечение костюма гаснет в ноль за жизнь эффекта. Постоянного тления
  нет.
- Льду - иней (туман стекает вниз). Жар (искры вверх) лежит рядом
  записью `HeatOnLook` без вызова и ждёт своей формы.
- Полоса, дошедшая до линии ступней, отрывается от героя и дальше живёт
  туманом на экране (раздел "Туман"). Решено после живого прогона: плоское
  облако под ногами ехало за героем в прыжке.
- Рука и оружие рисуются всегда, в том числе пока тело собирается из
  ломтиков: без руки герой не герой.
- Пощады на время сборки нет: решено после живого прогона, она не нужна.
- Цвет - поле записи (`Tint: TRgb`), не перечисление. Новая форма
  приносит запись со своим цветом.
- Герой и костюм будут перерисованы в 3.1+. Покров от арта не зависит:
  маски и точки рождения частиц собираются из альфы кадра при загрузке,
  размеры берутся с кадра.
- Отменяет запись в PORTING-NOTES ("вспышки героя - пресеты эмиттера,
  без своего модуля; красная вспышка при возрождении"): с полосами и
  ломтиками это больше пресета, а цвет появления - светлый дым.

## Образцы
- Blade, "Turn Up": плоскость энергии проходит сквозь героя, за ней уже
  костюм. Отсюда порядок "сверху вниз".
- Faiz: сначала свет по телу, потом вспышка. Отсюда: ломтик прилетает
  белым и остывает в спрайт.
- IXA, Burst Mode: волна жара в момент раскрытия брони. Отсюда свечение
  сразу после надевания; у льда волна холодная и течёт вниз.
- Celeste: респаун меньше секунды. Лунка - 14 тиков.
- Mega Man: всё сходится к герою, эффект показывает, где он.
- Katana Zero: горизонтальные полосы помех.

## Модель

### Запись вида
```pascal
type
  TShroudOrder = (soTogether, soTopDown, soBottomUp);

  // Ticks, screen units and shares
  TShroudLook = record
    Life: Integer;
    Bands: Integer;
    WidthFrom, WidthTo: Single; // a band at birth and at its end
    Travel: Single; // down the body over a band's life; up below zero
    Order: TShroudOrder;
    Stagger: Single; // the share of Life the last part waits, 0..0.7
    Smoke: Single; // the density of a band's puff
    Light: Single; // the level of a band's light
    Reveal: Boolean; // the body is put together out of strips
    Shift: Single; // how far aside a strip is born
    Flash: Single; // the halo at its peak; above 1 it is drawn twice
    FlashAt: Single; // the share of Life the peak falls on, 0..0.95
    Motes: Single; // born a tick at the peak
    Lift: Single; // a mote's pull, units a tick per tick; up below zero
    Tint: TRgb;
  end;
```

### Часы
- `Start(look)` запоминает запись, обнуляет возраст, бросает кости на
  полосы и ломтики. Идущий покров заменяется новым; частицы и туман
  прежнего долетают.
- `Tick`: возраст +1; дошёл до `Life` - покров кончился. Потом полёт
  тумана (всегда, пока есть); потом, если покров жив, отрыв полос в
  туман и рождение частиц; потом полёт частиц (всегда, пока есть).
- Время `t` = возраст / `Life`, 0..1. Между тиками рисование берёт
  (возраст + альфа шага) / `Life`.
- Своё время части тела (`PartTime`): у каждой полосы и каждого ломтика
  есть место по телу `at` (0 - макушка, 1 - ступни) и задержка:
  ```
  очередь = 0 (soTogether) | at (soTopDown) | 1 - at (soBottomUp)
  u = clamp((t - очередь * Stagger) / (1 - Stagger), 0, 1)
  ```
- Плавный ход: `ease(u) = 1 - (1 - u)^3`.

### Ореол
```
t < FlashAt:  Glow = Flash * (t / FlashAt)^2
иначе:        Glow = Flash * exp(-4 * (t - FlashAt) / (1 - FlashAt))
```
`FlashAt` = 0 - вспышка с первого тика и спад (костюм). `FlashAt` около
0.8 - разгон к концу сборки и короткий спад (появление). К концу жизни
остаётся меньше 2% от `Flash`.

### Полосы
`Start` создаёт `Bands` штук. У полосы `i` (с нуля):
- место `at = (i + 0.5) / Bands + (rnd - 0.5) * 0.5 / Bands`;
- сторона: нечётная справа (+1), чётная слева (-1);
- клуб `i mod 4` из четырёх клубов канвы;
- своя ширина `0.8 + 0.4 * rnd`;
- чётная рисуется перед героем, нечётная за ним.

Полоса рисуется, пока 0 < u < 1. Всё в единицах экрана; `H` = 32
(сторона кадра), `mid` - середина кадра по X, `top` - верх кадра:
```
e      = ease(u)
w      = lerp(WidthFrom, WidthTo, e) * своя ширина
slide  = WidthFrom > WidthTo ? сторона * (w - WidthTo) * 0.25 : 0
y      = min(top + at * H + Travel * e, top + H - 1)
th     = max(5, H / max(Bands, 3) * 1.5) * (1 + 0.9 * u)
wave   = sin(pi * u)
```
Два прохода:

| проход | чем | прямоугольник (центр, ширина x высота) | цвет | уровень |
|---|---|---|---|---|
| дым | клуб `Render.Puff`, обычная альфа | (mid + slide, y - 2u), 1.2w x th * (1.3 + 0.8u) | Tint | wave^0.5 * Smoke * 0.85 |
| свет | `gsPoint`, аддитивно | (mid + slide, y), 1.1w x 0.7th | Tint пополам с белым (0.55) | wave^1.4 * Light |

Дым шире по времени, чем свет: свет уходит, дым ещё висит. Полоса
`WidthFrom` > `WidthTo` сходится к герою с боков (появление), наоборот -
расходится от него (иней, снятие костюма).

### Туман
Полоса записи с `Travel` > 0 не должна лежать плоским облаком на линии
ступней и ездить за героем в прыжке. Дошедшая до ступней, она
отрывается от героя.
- Проверка раз в тик, по времени тика, для полос с 0 < u < 1: если
  `at * H + Travel * e` >= `H - 1` (линия ступней), полоса отрывается.
  Записи с `Travel` <= 0 тумана не дают.
- Оторвавшаяся полоса помечается (`Fallen`): на теле её больше нет. Её
  копия идёт в `Mist` (`TShroudCloud`): запись `Look` целиком, сама
  полоса, возраст покрова на этот тик, `X` = середина кадра героя, `Y` =
  линия ступней (`top + H - 1`), оба по позе этого тика, в координатах
  экрана.
- Туман рисуется теми же формулами и теми же двумя проходами, что полоса
  на теле, с центром в `(X, Y)` вместо `(mid, y)`. Его время - свой
  возраст по `Life` своей записи; возраст растёт на тик, на `Life`
  туман кончается.
- Оседание: пока проба материи (`TSolidProbe`) в `(X, Y)` говорит
  "пусто", `Y` растёт на `MistSink` = 1.2 юнита за тик. Стоящий в
  материи (на полу, на паде) не двигается. Пробы нет - не двигается.
- Рисуется с тряской канала героя, без `DeckLift`. Сторона (перед
  героем или за ним) остаётся от полосы. Рисуется и тогда, когда покров
  уже кончился.
- `Start` туман не стирает: новый покров, как и частицы, не обрывает
  прежнее. `Clear` и `LeaveMotes` стирают: над трупом и за дверью тумана
  нет.

### Ломтики
Только при `Reveal`. Кадр режется на `ShroudStrips` = 16 горизонтальных
ломтиков. У ломтика `j`: место `at = (j + 0.5) / 16`, сторона
`(нечётный ? 1 : -1) * (0.6 + 0.8 * rnd)`.
```
u      = PartTime(t, at)        // u = 0 - ломтика ещё нет
dx     = Round(сторона * Shift * (1 - ease(u)))   // целые единицы
тело   = ломтик кадра со сдвигом dx, уровень clamp(u * 2.5, 0, 1)
свет   = тот же ломтик белой маски, аддитивно,
         цвет Tint к белому на 0.7, уровень (1 - u)^1.5 * 0.8
```
Пока покров собирает тело (`Assembling`), игра не зовёт `FHero.Draw`:
тело рисует покров. Рука и оружие остаются: игра зовёт `FHero.DrawArm`
после ломтиков и до ближних полос. Кончилась сборка - герой рисуется
как всегда, целым кадром. Ломтики в покое не рисуются никогда: на
дробном масштабе окна между ними были бы волосяные швы.

### Свет на теле
При `Glow` > 0, вокруг обычного кадра героя:

| где | чем | размер | цвет | уровень |
|---|---|---|---|---|
| под телом | `gsPoint` | 80 x 80 по центру кадра | Tint | Glow * 0.35 |
| под телом | ореол кадра (размытая маска) | кадр + поля размытия | Tint | min(Glow, 1); при Glow > 1 второй проход Glow - 1 |
| над телом | сам кадр, аддитивно | кадр | как нарисован | Glow * 0.55 |
| над телом | белая маска кадра | кадр | Tint к белому на 0.7 | (Glow - 0.6) * 0.9, при Glow > 0.6 |

### Частицы
Рой `TParticleSwarm` из `Effects.Emitter`.
- Рождение, раз в тик: долг += `Motes * clamp(Glow / Flash, 0, 1.2)`;
  на каждую целую единицу долга - частица. `Flash` <= 0 или пустой
  список точек - никого.
- Точка рождения - случайная непрозрачная точка текущего кадра
  (`TSeedList`, единицы от угла кадра как нарисован). У зеркального кадра
  `x := 32 - x`.
- Скорость: `SpeedX = (rnd - 0.5) * 0.8`, `SpeedY = Lift * (0.5 + rnd) * 3`.
  Жизнь `18 + rnd * 26` тиков. Размер (`Scale`) `2.5 + 3.5 * rnd`.
- Полёт: `Advance(0.96, 0, Lift * 0.12)`.
- Тонущая частица (`Lift` > 0), вошедшая в материю (`TSolidProbe`),
  отступает на свой шаг по Y, теряет `SpeedY` и ползёт вбок:
  `SpeedX *= 1.06`. Туман ложится на пол и на пады.
- Частицы живут в координатах экрана: герой ушёл - след остался.
- Рисование, аддитивно, `gsPoint`: `k = (1 - возраст / жизнь)^1.2`;
  пятно `2 * Scale` цветом Tint на `0.8k`, ядро `0.8 * Scale` цветом
  Tint к белому на 0.8 на `k`. Между тиками место идёт по скорости.

### Записи
| запись | Life | Bands | Width | Travel | Order / Stagger | Smoke / Light | Reveal / Shift | Flash / At | Motes / Lift | Tint |
|---|---|---|---|---|---|---|---|---|---|---|
| `PitLook` | 14 | 5 | 150 -> 30 | -3 | Together / 0.15 | 0.75 / 0.70 | да / 18 | 0.9 / 0.80 | 1.5 / -0.15 | 236, 240, 255 |
| `EntryLook` | 40 | 9 | 190 -> 34 | -4 | TopDown / 0.55 | 0.80 / 0.60 | да / 26 | 1.1 / 0.85 | 2.0 / -0.20 | 236, 240, 255 |
| `ReviveLook` | 24 | 7 | 120 -> 32 | -6 | BottomUp / 0.40 | 0.90 / 0.50 | да / 12 | 0.8 / 0.80 | 1.0 / -0.25 | 236, 240, 255 |
| `IceOnLook` (иней) | 130 | 4 | 26 -> 110 | 30 | TopDown / 0.60 | 0.55 / 0.25 | нет / 0 | 1.3 / 0 | 2.5 / 0.12 | 120, 200, 255 |
| `HeatOnLook` (жар) | 110 | 0 | 30 -> 30 | 0 | Together / 0 | 0 / 0 | нет / 0 | 1.4 / 0 | 4.0 / -0.30 | 255, 120, 48 |
| `IceOffLook` | 18 | 4 | 28 -> 160 | 0 | Together / 0.10 | 0.60 / 0.60 | нет / 0 | 1.0 / 0 | 5.0 / -0.10 | 120, 200, 255 |

Туман дают только записи с `Travel` > 0: сейчас это `IceOnLook`.

## Архитектура
```
Core/Render.Glow.pas    + BlurImage, CreateGlowFromImage (из Menu.Logo)
Menu/Menu.Logo.pas      - свой блюр, зовёт Render.Glow
Core/Render.Puff.pas    + DrawPuffRect
Game/Hero.pas           + THeroPose, Pose, SkinSet, HeroFrameSequences,
                        DrawArm
Game/Game.Shroud.pas    новый: TShroudLook, записи, THeroShroud,
                        TShroudPainter
Game/Game.Henshin.pas   сцена записью THenshinStage, два вызова Start
Moon2D.dpr              владение, тик, рисование, три вызова Start, чистки
Moon2D.dproj            + Game\Game.Shroud.pas
Game/Game.Version.pas   версия
```

### Почему два класса
`THeroShroud` считает: часы, полосы, ломтики, туман, частицы. SDL не
трогает, ресурсов не держит. `TShroudPainter` рисует и держит текстуры
масок, собранные из арта героя. Причины меняться разные (ощущение против
рендера), сроки жизни разные, и тесты достают счёт без окна. Художник
читает счёт через его открытые методы - они открыты по делу, не ради
тестов.

### `Core/Render.Glow.pas`
Блюр и превращение картинки в свечение были закрыты в `Menu.Logo`
(`BlurLine`, `BoxBlur`, хвост `BuildHalo`). Второму клиенту они нужны
такими же - переехали сюда, логотип зовёт их отсюда:
```pascal
// APasses box blurs of ARadius: three make a near-Gaussian bloom.
// Outside the image counts as dark.
procedure BlurImage(var AImage: TArray<Single>; AWidth, AHeight, ARadius,
  APasses: Integer);
// A glow out of an image of levels: scaled so its peak is one, white
// with the levels in alpha
function CreateGlowFromImage(ARenderer: PSdlRenderer;
  const AImage: TArray<Single>; AWidth, AHeight: Integer): PSdlTexture;
```
В `Menu.Logo` остаётся своё: ужатие альфы в `HaloScale` раз в картинку с
полями, цвет букв, дыхание. Ошибку создания текстуры теперь поднимает
`Render.Glow` (`EGlowError`).

### `Core/Render.Puff.pas`
```pascal
// The puff stretched into ADest, unturned
procedure DrawPuffRect(ARenderer: PSdlRenderer; ATexture: PSdlTexture;
  const ADest: TSdlFRect; AColor: TRgb; ALevel: Single);
```

### `Game/Hero.pas`
Правки в герое, поведение не меняется:
```pascal
const
  // The hero's 1..24: walk, then death, then the transformed frames
  HeroFrameSequences: array [0..2] of string = ('walk', 'death', 'henshin');

type
  // What Draw puts on the screen this tick
  THeroPose = record
    Frame: Integer; // 1..24
    Texture: PSdlTexture;
    Left, Top: Integer; // the picture's corner, screen units
    Mirrored: Boolean;
  end;

  // в THero, public:
    function Pose: THeroPose;
    property SkinSet: TSpriteSet read FSkinSet;
    // The arm and the gun alone, for a body that is drawn some other way
    procedure DrawArm(const ASprites: TSpriteRenderer);
```
- Выбор кадра из `THero.Draw` (мёртвый / `case FAction` / `+16` для
  льда) переехал в `Pose` без изменений, вместе с углом
  `Round(FX)`, `Round(FY - HeroSize + Removal)` и зеркалом. `Draw`
  берёт позу и рисует её, потом `DrawArm`. Один источник правды: покров
  и герой не могут разойтись в кадре.
- `DrawArm` рисует руку и пушку, если герой жив. Игра зовёт его вместо
  `Draw` на время сборки из ломтиков.
- Конструктор берёт имена последовательностей из `HeroFrameSequences`.

### `Game/Game.Shroud.pas`
```pascal
unit Game.Shroud;
{$I ..\Moon2D.inc}

interface

uses
  System.SysUtils, Sdl2.Core, Render.Brush, Effects.Emitter, Effects.Sparks,
  Levels.Dynamics, Hero;

const
  ShroudStrips = 16;

type
  EShroudError = class(Exception);
  TShroudOrder = ...;
  TShroudLook = ...;

  TShroudBand = record
    At: Single; // 0 at the head .. 1 at the feet
    Side: Integer; // -1 comes from the left, 1 from the right
    Puff: Integer; // which of the canvas' puffs
    Wide: Single; // its own share of the look's width
    InFront: Boolean; // over the hero, else behind him
    Fallen: Boolean; // gone past the feet: it lives on as mist
  end;

  // A band at a place on the screen, under the look it was born with
  TShroudCloud = record
    Look: TShroudLook;
    Band: TShroudBand;
    Age: Integer; // ticks of the look's life gone, as a band's clock
    X, Y: Single; // where the band stands: its middle, on its row
  end;

  // Opaque points of one frame, in units from the picture's corner as painted
  TSeedList = TArray<TSdlFPoint>;

  THeroShroud = class
  public
    // ASolid answers in screen units
    constructor Create(const ASolid: TSolidProbe; ASeed: Cardinal);
    destructor Destroy; override;
    procedure Start(const ALook: TShroudLook);
    procedure Tick(const APose: THeroPose; const ASeeds: TSeedList);
    // A door: what has left the hero - the motes and the mist - stays
    // behind, the light goes with him
    procedure LeaveMotes;
    procedure Clear;
    // The share of life gone, 0..1; AAlpha - the step between two ticks
    function Time(AAlpha: Single): Single;
    // The own clock of a place along the body, 0..1
    function PartTime(ATime, AAt: Single): Single;
    function Glow(ATime: Single): Single;
    // Units aside a strip stands at ATime; zero once it is home
    function StripShift(AStrip: Integer; ATime: Single): Single;
    property Active: Boolean read FActive;
    // The body is being put together: the game leaves the hero undrawn
    property Assembling: Boolean read GetAssembling;
    property Look: TShroudLook read FLook;
    property Bands: TArray<TShroudBand> read FBands;
    property Motes: TParticleSwarm read FMotes;
    property Mist: TArray<TShroudCloud> read FMist;
  end;

  // What is made of one hero frame at load: seeds, masks, halo
  TShroudFrameArt = record ... end;
  // Where and when the shroud is drawn this frame
  TShroudView = record ... end;

  TShroudPainter = class
  public
    constructor Create(ARenderer: PSdlRenderer; const AHero: THero;
      const AShroud: THeroShroud);
    destructor Destroy; override;
    function SeedsOf(AFrame: Integer): TSeedList;
    // Behind the hero: the mist, the far bands, the halo
    procedure DrawUnder(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      ALift, AAlpha: Single);
    // On him: the strips while he is assembled, the light on the body
    procedure DrawBody(AOrigin: TSdlPoint; ALift, AAlpha: Single);
    // Over him: the near bands, the mist, the motes
    procedure DrawOver(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      ALift, AAlpha: Single);
  end;

const
  PitLook: TShroudLook = (...);
  // и остальные пять
```
- `Assembling` = `Active and Look.Reveal`.
- `AOrigin` - тряска канала героя, `ALift` - `FHero.DeckLift(AAlpha)`:
  всё, что привязано к кадру (ломтики, ореол, свет, полосы), рисуется с
  ними. Частицы и туман - только с `AOrigin`.
- Кости - свой `TXorShift`, не `Random`.
- Полоса на теле и туман рисуются одной процедурой (`DrawCloud`); для
  полосы на теле облако собирается на лету из записи, полосы и места по
  кадру.

Маски (`TShroudPainter.Create`), на каждый из 24 кадров:
- поверхность: `LoadImageSurface(AHero.SkinSet, имя)`, перевод в
  `SdlPixelFormatAbgr8888`, как в `Menu.Logo`; имена - по
  `HeroFrameSequences` в том же порядке, что у героя;
- точки рождения: каждый тексел с альфой >= 128, в единицах
  (`x * 32 / ширина`, от центра тексела);
- белая маска: белые пикселы с альфой кадра, через `CreateGlowTexture`;
- ореол: альфа кадра в картинку с полями, `BlurImage` (3 прохода),
  `CreateGlowFromImage`. Радиус - 2.5 единицы в текселах ореола; кадр
  шире 64 текселов сначала ужимается до 64 (как `HaloScale` у логотипа).
  На нынешних кадрах: радиус 5, поля 15 текселов.

Рисование ломтика и аддитивного кадра меняет состояние текстуры героя
(альфа, режим смешения). Оба живут в своих закрытых процедурах, которые
ставят состояние и возвращают его сами: альфа 255, смешение
`SdlBlendModeBlend`. Забытый возврат - герой навсегда прозрачный или
светящийся.

### `Game/Game.Henshin.pas`
Конструктор уже брал пять параметров, покров был бы шестым. Сцена
свёрнута в запись:
```pascal
  // What the ceremony acts on
  THenshinStage = record
    Hero: THero;
    Audio: TSoundBank;
    Messages: TMessageBoard;
    Shake: TScreenShake;
    Shroud: THeroShroud;
  end;

    constructor Create(const AStage: THenshinStage; const ACure: TCureHero);
```
- `Finish`: сразу после `FHero.HeroForm := hfIce` - `Start(IceOnLook)`.
- `RemoveIceForm`: после веера - `Start(IceOffLook)`.
- `Reset` покров не трогает: его чистит рестарт.

### `Moon2D.dpr`
- Поля `FShroud`, `FShroudPainter`. Создаются при загрузке уровня сразу
  после `FHero` и до `FHenshin` (тому нужен покров): `FreeAndNil` и
  `Create`, как `FHenshin`. Зерно - `RollDiceSeed`, проба материи -
  `SolidUnderPoint`. Освобождаются в деструкторе игры: художник раньше
  покрова, оба раньше героя.
- Тик, после `FAura.Tick`:
  `Pose := FHero.Pose; FShroud.Tick(Pose, FShroudPainter.SeedsOf(Pose.Frame))`.
- Рисование, вместо прежней тройки вокруг `FHero.Draw`:
  ```
  DrawUnder(канва, тряска scHero, DeckLift, альфа)
  Origin := тряска scHero; FineY := DeckLift
  если не FShroud.Assembling: FHero.Draw
  DrawBody(тряска scHero, DeckLift, альфа)
  если FShroud.Assembling: FHero.DrawArm
  FineY := 0
  DrawOver(канва, тряска scHero, DeckLift, альфа)
  Origin := тряска scWorld
  ```
- `HandlePitFall`: после `SetY` - `Start(PitLook)`, до `HurtHero`.
- `StartPlaying`: `Start(EntryLook)`.
- `RestartLevel`: после `FHero.Revive` и `SetY` - `Clear`, потом
  `Start(ReviveLook)`.
- `HurtHero`, ветка смерти (рядом с `FAura.Collapse`): `Clear`. Над
  трупом ничего не светится.
- `ArriveOnScreen`: `LeaveMotes`. Свет идёт с героем через дверь,
  частицы и туман остаются за ней.

## Этапы
1. **Блюр в `Render.Glow`.** Готово. `Render.Glow`, `Menu.Logo`.
   Поведение не меняется, версии нет.
   Коммит: `Lift the halo blur into Render.Glow`.
2. **Покров.** Готово, версия 3.0.47.
   Коммиты: `Shroud the hero on respawn and henshin (3.0.47)` и
   `Polish the hero shroud` (туман, рука; версия не меняется).
   Смотреть вживую по порядку:
   - герой рисуется как раньше во всех позах, включая смерть (правка
     `Pose`);
   - лунка; вход на уровень; смерть и возврат;
   - рука на месте с первого кадра сборки;
   - хеншин: вспышка и иней; снятие костюма (конец уровня и гравели);
   - после хеншина плоского облака под ногами нет; туман остаётся там,
     где герой стоял или прыгнул, оседает на пол и тает;
   - дверь во время свечения: свет едет, частицы и туман остаются;
   - лунка в костюме: полосы поверх ледяного кадра;
   - пад: покров качается вместе с героем.
3. **Тесты.** `Tests/Game/Tests.Game.Shroud.pas`, по конвейеру
   `docs/TESTING.md`: таблица в него, потом код. Версии нет. Кандидаты:
   - после `Create` покров не идёт, `Glow` ноль;
   - `Start` - идёт; через `Life` тиков - нет;
   - `Assembling` только у записи с `Reveal` и только пока идёт;
   - `Start` на ходу начинает часы заново;
   - `Clear` останавливает и убирает частицы и туман; `LeaveMotes`
     убирает частицы и туман и не останавливает;
   - `Glow`: с `FlashAt` > 0 растёт от нуля до `Flash` и падает; с
     `FlashAt` = 0 только падает; к концу почти ноль;
   - `PartTime`: вместе - одно время у макушки и ступней; сверху вниз -
     макушка впереди; снизу вверх - наоборот; при `t` = 1 у всех 1;
   - `StripShift`: при `t` = 1 ноль; соседи в разные стороны; `Shift` 0 -
     всегда ноль;
   - частицы рождаются только в точках списка; у зеркальной позы -
     отражённых; `Motes` 0 или пустой список - никого; после конца
     покрова рой пустеет;
   - тонущая частица не входит в материю;
   - туман: у записей с `Travel` <= 0 его нет; у `IceOnLook` за `Life`
     тиков он появляется, по одному облаку на полосу; `X` и `Y` по позе
     тика; `Start` его не стирает; он умирает по возрасту своей записи;
     с пробой "везде пусто" оседает на `MistSink` за тик, с пробой
     "везде материя" стоит;
   - одно зерно - один прогон.

   На глаз остаётся всё нарисованное: полосы, ломтики, ореол, цвета,
   слои руки и тумана.
4. **Документы.** Карта (оба языка, заплаткой), PORTING-NOTES: сессия и
   отмена старого решения про пресеты эмиттера.

## Правила для пишущего
- Истина - репозиторий: клонировать, перед правкой читать функции
  целиком. По памяти файлы не восстанавливать.
- Отдавать архивом готовых файлов целиком. Патчей нет. Ничего не
  коммитить и не пушить.
- `.pas` и `.dpr`: UTF-8 с BOM, CRLF.
- CODESTYLE 4.9. Комментариев мало и по делу, английский. Ссылок на
  строки исходника 2008 не писать.
- Не трогать ничего вне списка задачи. Попутных правок стиля нет.
- В документах репозитория решения безличные ("решено").
- Числа облика не подбирать: они в таблице "Записи" и в разделе "Модель".
- Что обычно не компилируется с первого раза:
  - новый юнит не добавлен в `uses` файла `Moon2D.dpr` (с путём
    `in 'Game\Game.Shroud.pas'`) и в `Moon2D.dproj` (`DCCReference`);
    для тестов - то же в `Tests\Moon2D.Tests.dpr` и `.dproj`;
  - `Power`, `Min`, `Max`, `EnsureRange` с `Single` и `Double`
    вперемешку - неоднозначная перегрузка; приводить к `Single`, как
    `StreakTailPower: Single` в `Render.Glow`;
  - вложенная запись в типизированной константе:
    `Tint: (R: 236; G: 240; B: 255)`;
  - типизированные константы-записи в `interface` идут после объявления
    типа;
  - поля в константе-записи идут в порядке объявления в типе, иначе не
    соберётся; запись под стендом уже в этом порядке;
  - `Hero` в `interface uses` у `Game.Shroud`, а `Game.Shroud` у героя не
    нужен вовсе - цикла нет и быть не должно;
  - функции SDL брать те, что уже объявлены в `Sdl2.Core`
    (`SDL_QueryTexture`, `SDL_SetTextureBlendMode`,
    `SDL_SetTextureAlphaMod`, `SDL_SetTextureColorMod`,
    `SDL_RenderCopyExF` есть). Новых привязок не добавлять без нужды.

## Как запускать
Каждый этап - свой чат, план приложен. Подсказки:
- этап 1: "SHROUD-PLAN, этап 1: вынеси блюр из Menu.Logo в Render.Glow.
  Поведение не меняется. Архив готовых файлов.";
- этап 2: "SHROUD-PLAN, этап 2: покров героя. Пиши по разделам Модель и
  Архитектура, числа из таблицы Записи. Архив готовых файлов.";
- этап 3: "спроектируй тесты для покрова героя" или "пиши сразу".

## Открыто
- Цвет льда записан в двух местах: `IceOrbTint` у орбов и `Tint` у
  `IceOnLook`. Со второй формой свести в одну палитру формы.
- Ореол нормируется к пику, как у логотипа; на стенде альфа множилась на
  1.5. Разница на глаз мала, доводится вживую.
- Кэш героя накладывает цветовой ключ, маска берёт чистую альфу кадра:
  чёрные пикселы внутри силуэта у маски непрозрачны, у текстуры -
  дырки. На ореол не влияет.
- Скорость оседания тумана (`MistSink` = 1.2) не со стенда, подобрана без
  него; судья - живой прогон.
- Свет на теле (аддитивный кадр и белая маска) рисуется и пока тело
  собирается, по буквальному чтению таблицы. Если на входе и возврате
  мелькает бледный призрак целого героя перед ломтиками, на сборке эти
  два прохода отключаются.

## Не входит
- Звук появления и звук свечения.
- Постоянное тление формы (поле `Smolder`): появится с формой, которой
  оно нужно.
- Свой покров у монстров и машин (танк, спущенный кордоном, - кандидат).
- Перерисовка героя и костюма - 3.1+.
- Второй хеншин и формы кроме льда.
- Привязка тумана к паду: туман стоит на экране и не едет с падом.

## Журнал

### Сессия: покров героя, 3.0.47 (2026-10-08)

Герой появлялся и переодевался без картинки: после лунки он просто
стоял на точке возрождения, костюм льда надевался сменой кадра. Теперь
вокруг него собираются дым и свет: светлые горизонтальные полосы
сходятся к телу, тело складывается из ломтиков, вспыхивает ореол,
разлетаются частицы. Ледяной костюм вспыхивает инеем, который стекает
вниз. Всё это одна вещь - картинка поверх кадра героя, которая живёт по
своим часам и гаснет. Разное в ней только числа.

#### Решения
- Один модуль, `Game.Shroud`, и одна запись вида на сцену,
  `TShroudLook`. Шесть записей: `PitLook`, `EntryLook`, `ReviveLook`,
  `IceOnLook`, `HeatOnLook` (его пока никто не зовёт), `IceOffLook`.
- Старая запись отменена. Решение "вспышки героя - пресеты эмиттера,
  без своего модуля; красная вспышка при возрождении" (шаг 4 стратегии
  3.0 и раздел "Эффекты героя") больше не действует: с полосами и
  ломтиками это больше пресета. Шаг 4 не был сделан - героя до этой
  сессии никто не рисовал вспышкой, - поэтому снимать нечего, кроме
  самой записи. Цвет появления - светлый дым, не красная вспышка.
  Синий цвет остался за льдом. Постоянного тления нет: свет костюма
  гаснет в ноль за жизнь эффекта. Старые места помечены "Отменено в
  3.0.47", не стёрты.
- Логика не сливается. Церемония остаётся в `Game.Henshin`, возврат из
  лунки, вход и возрождение - в `Moon2D.dpr`. Они только зовут `Start` с
  нужной записью. Управление у героя покров не отбирает ни в одной
  сцене.
- Два класса: `THeroShroud` считает и SDL не трогает, `TShroudPainter`
  рисует и держит текстуры. Причины меняться разные, сроки жизни
  разные, а тесты достают счёт без окна.
- Покров от арта не зависит. Маски, ореолы и точки рождения частиц
  собираются из альфы 24 кадров героя при загрузке, размеры берутся с
  кадра. Герой и костюм будут перерисованы в 3.1+, а покров поедет за
  ними сам.
- Цвет - поле записи (`Tint`), не перечисление. Новая форма приносит
  запись со своим цветом.
- Льду - иней: туман стекает вниз. Жар (искры вверх) лежит рядом
  записью `HeatOnLook` без вызова и ждёт своей формы.
- После живого прогона решено: полоса, дошедшая до линии ступней,
  отрывается от героя и живёт туманом на экране. Плоское облако под
  ногами ехало за героем в прыжке. Туману дают только записи с `Travel`
  больше нуля - сейчас `IceOnLook`.
- Рука и оружие рисуются всегда, в том числе пока тело собирается из
  ломтиков: без руки герой не герой.
- Пощады на время сборки нет: после живого прогона решено, что она не
  нужна.
- Версия 3.0.47: тег v3.0.46 закрыт, механика новая.

#### Цифры
Числа записей сняты со стенда "Покров героя Moon2D" (артефакт, версия
3): тот же счёт, что в игре (экран 512x384, 33 тика), настоящие кадры
из `hero.mset`. Стенду верили как отправной точке, судья - живой
прогон.
| запись | тиков | секунд | полос | цвет |
|---|---|---|---|---|
| `PitLook` | 14 | 0.42 | 5 | светлый дым |
| `EntryLook` | 40 | 1.2 | 9 | светлый дым |
| `ReviveLook` | 24 | 0.73 | 7 | светлый дым |
| `IceOnLook` | 130 | 3.9 | 4 | лёд |
| `HeatOnLook` | 110 | 3.3 | 0 | жар, не зовётся |
| `IceOffLook` | 18 | 0.55 | 4 | лёд |

- Светлый дым - `Tint` 236, 240, 255; лёд - 120, 200, 255; жар - 255,
  120, 48.
- Ломтиков 16 (`ShroudStrips`), точка рождения частицы - тексель кадра с
  альфой от 128. Ореол: три box-размытия радиусом 2.5 единицы; на
  нынешних кадрах радиус 5 текселов, поля 15.
- Туман оседает на `MistSink` = 1.2 единицы за тик, около 40 в
  секунду, пока проба материи не скажет "внутри". Число не со стенда,
  подобрано без него.
- Порядок тика: возраст +1 и конец на `Life`, потом полёт тумана, потом
  (пока покров жив) отрыв полос и рождение частиц, потом полёт и
  оседание частиц.

#### Как вышло в коде
- `Render.Glow`: `BlurImage` и `CreateGlowFromImage` вынесены из
  `Menu.Logo`; логотип зовёт их оттуда. Ошибку создания текстуры теперь
  поднимает `EGlowError`. Отдельный коммит, версии нет.
- `Render.Puff`: `DrawPuffRect` - клуб в прямоугольник без поворота.
- `Hero`: `THeroPose`, `Pose`, `SkinSet`, `HeroFrameSequences`,
  `DrawArm`. Выбор кадра из `Draw` переехал в `Pose` без изменений,
  `Draw` стал `Pose` плюс `DrawArm`: покров и герой не могут разойтись
  в кадре.
- `Game.Shroud`, новый юнит: `TShroudLook` и шесть записей,
  `THeroShroud`, `TShroudPainter`, `TShroudBand`, `TShroudCloud`.
  Рисование разрезано на три вызова вокруг героя: `DrawUnder`,
  `DrawBody`, `DrawOver`. Полоса на теле и туман рисуются одной
  процедурой, `DrawCloud`.
- `Game.Henshin`: сцена свёрнута в запись `THenshinStage` (конструктор
  уже брал пять параметров, покров был бы шестым); `Finish` зовёт
  `Start(IceOnLook)`, `RemoveIceForm` - `Start(IceOffLook)`; `Reset`
  покров не трогает.
- `Moon2D.dpr`: `FShroud` и `FShroudPainter` рождаются в `LoadLevel`
  после героя и до церемонии; `HandlePitFall` - `Start(PitLook)`;
  `StartPlaying` - `Start(EntryLook)`; `RestartLevel` - `Clear`, потом
  `Start(ReviveLook)`; `HurtHero` на смерти - `Clear`; `ArriveOnScreen` -
  `LeaveMotes`. Тик идёт после ауры. В рисовании на время сборки
  вместо `FHero.Draw` зовётся `FHero.DrawArm`.
- `Moon2D.dproj`: юнит в списке.
- `Tests/Game/Tests.Game.Shroud.pas`: 38 тестов счёта.
- `Game.Version`: 3.0.47.

#### Что изменилось для игрока
- Возврат из лунки, вход на уровень и возрождение после смерти
  показаны: светлые полосы сходятся к герою, тело собирается из
  ломтиков, вспышка, частицы. Рука на месте с первого кадра.
- Хеншин: на костюме льда вспыхивает иней и герой светится, потом
  гаснет за четыре секунды. Иней, дошедший до ног, остаётся туманом
  там, где герой стоял или прыгнул, оседает на пол и тает.
- Снятие костюма: короткий разлёт инея.
- Дверь во время свечения: свет едет с героем, частицы и туман
  остаются за ней.
- Над трупом ничего не светится.

#### Проверка
- Delphi собрал, на экране сыграно. Правок после прогона две: туман, оторвавшийся от героя, и рука во время
  сборки. Обе в коммите после основного.
- Тесты: 38 в `Tests.Game.Shroud.pas`, весь набор 151 из 151. Покрыт
  счёт: часы, свечение, своё время части тела при каждом порядке,
  ломтики, рождение и оседание частиц, туман (по облаку на полосу
  `IceOnLook`, место, оседание, возраст), кости. Нарисованное -
  полосы, ломтики, ореол, цвета, слои руки и тумана - остаётся глазу.

#### Открытое
- Частицы, уже летящие в момент нового `Start`, берут `Lift` нового
  облика (`FlyMotes`) и рисуются его `Tint` (`DrawMotes`). Видно ли это
  вживую, не решено.
- Цвет льда записан в двух местах: `IceOrbTint` у орбов и `Tint` у
  `IceOnLook`. Со второй формой свести в одну палитру формы.
- Ореол нормируется к пику, как у логотипа; на стенде альфа множилась
  на 1.5. Разница на глаз мала.
- Кэш героя накладывает цветовой ключ, маска берёт чистую альфу кадра:
  чёрные пикселы внутри силуэта у маски непрозрачны, у текстуры -
  дырки. На ореол не влияет.
- Свет на теле (аддитивный кадр и белая маска) рисуется и пока тело
  собирается. Если на входе и возврате мелькает бледный призрак целого
  героя перед ломтиками, на сборке эти два прохода отключаются. Не
  решено.
- Пощада на время сборки: нет, раздел не решается.
- Звука появления и свечения нет. Постоянного тления формы
  (`Smolder`) нет: появится с формой, которой оно нужно.
- Свой покров у монстров и машин - кандидат на потом.
- Туман не едет с падом: он стоит на экране.
- Крутить: числа записей в `Game.Shroud`, `MistSink`, `SeedAlpha`,
  `HaloReach`.

#### Коммиты
Lift the halo blur into Render.Glow; Shroud the hero on respawn and
henshin (3.0.47); Polish the hero shroud; Test the hero shroud; Update
the docs for the hero shroud.

---
