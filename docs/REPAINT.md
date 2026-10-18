# Repainting the old levels

How a screen of levels 1-2 goes from the tile art of 2008 to HD art, and
what was learned doing it. Written for a session that arrives cold: read
this, then the last repaint session in `PORTING-NOTES.md` for where the
work stands.

## What a repaint is

A screen of 2008 is tiles on a 16x12 grid. A repainted screen keeps the
grid as matter and loses it as a picture:

- `tiles.screens[n].rows` of the screen go to zero - nothing is drawn
  from the palette;
- `tiles.screens[n].collision` stays - the hero stands where he stood;
- the picture comes back as level objects (`objects`), which collide with
  nothing;
- what moves is not painted: pads (`pads`), fans, lamps, smoke, sparks
  (`dynamics`) are the game's.

The palette is never trimmed: every index after a removed name would
shift.

Level 1 is repainted whole (screens 1-17, set `level1-structures`).
Level 2: screens 1-4 so far (set `level2-objects`).
Levels 1-2 stay 4:3.

## The order of work on a screen

1. **The idea.** What the room is, in a sentence, and what each part of
   the old screen becomes. Agreed before anything is drawn.
2. **The plan and the blockout.** Two pictures made by script from the
   level file: a numbered plan to read, and a clean blockout to feed the
   generator.
3. **The prompts.** One for the main picture, ready to paste. Separate
   things (a gate, a cabinet) get a prompt each, after the room is
   accepted. A long list of small pieces is not wanted.
4. **Generation** happens outside the session, in ChatGPT.
5. **Seating.** The picture is measured against the grid, set in place,
   wired into the level file and packed into the set.
6. **A preview and the checks**, then a live run.

## What each thing becomes

| On the old screen | Becomes |
|---|---|
| Ground, walls, floors | Matter as before, drawn by an object |
| A room | One object for the whole screen, `sNN-room`, at 0, 0, width 512 |
| A separate structure (a gate, a crane) | Its own object, `sNN-name` |
| Platforms hanging in the air | Pads; their cells leave `collision` |
| A fan, a vent | A dynamic `fan`; the picture keeps an empty well |
| A lamp | Painted lit; see "Life on a screen" |
| Wires, pipes, panels | Part of the room's picture |

Pads were pictures-with-collision once (objects over solid cells) on
level 2: a pad that does not move is still a pad, not a tile.

## Pads

A pad of the old levels is `s16-platform` (or `s16-platform-out`, the
broken one), `width` 32, `bullets` "block", `bob` 1 or 1.5, the rig
`pad` (or `padBroken`), a tag `sNN-plat-NN` numbered in file order. The
rigs are written again in each level file's `rigs`.

- A pad's cell leaves `collision`; a pad may not stand in a wall or pass
  through one on its path.
- Nothing static stands on a pad. A pad sways and travels, a static
  object does not, and the two part company: the crystals of level 1
  were taken off the pads of level 2 for it. What rides a pad hangs on
  it as a rig.
- The hero comes onto a screen where the backdrop shows him and where
  the picture has ground for him: on the line of the cliff, not high
  among the lit mountains, where he is lost, and not deep in the black
  under it, where he hangs in nothing.
- A pad that carries the hero across a gap: `path`, route `pingpong`,
  one stop, `speed` about 30, `pause` 1. Pads of one screen get different
  periods so they never fall into step.
- Jumps are judged by the hero's own arc. `Hero.JumpReach(rise)`: up 0-1
  rows - 3 empty cells across, up 2 - 2, up 3 - none, down 1-4 - 4. Port
  the function for a check, do not copy the table.
- A crossing must hold at every phase of the pads, and what the crossing
  guards must be out of reach without them: check both.
- `JumpReach` knows nothing of ceilings. In a corridor three rows high
  the hero's head stops the rise and the jump is cut short: his middle
  travels 72 units floor to floor, 56 onto a deck a row up, 54 down
  from one; the ice form's boost makes it shorter, not longer. A pit of
  two cells there is jumped, a pit of three is not. For a pit under a
  ceiling run the arc of `Tick` with `BumpCeiling`, not the table.
- A passage one cell high cannot be jumped into. A pad that delivers the
  hero to one stops flush with its floor and waits there.
- A respawn point needs a floor: a wall below, or a pad with no path and
  no group under the cell's middle.
- A monster that carries a trigger (a title, `heroY`) and loses its floor
  falls into the pit with it: move it.

## The blockout

Drawn by script from `collision`, 1440x1080 (90 px a cell), nothing by
hand:

- transparent outside the structure;
- solid cells - flat mid-grey, with a lighter line on every edge between
  a solid cell and an open one;
- open cells inside the structure - flat dark navy. "Inside" is a flood
  fill from a cell of each room; a sealed chamber is filled from a cell
  of its own;
- a fan well - a black disc in a grey ring;
- a lamp - a white bar; a hazard mark - a yellow bar;
- no text, no numbers, no figures.

The plan is the same picture over the screen's backdrop, with the real
fans and a hero for scale, and numbers on it. **The plan never goes to
the generator**: it paints what it sees, blades included.

Nothing in the blockout may cross a floor. Two pipes drawn through a
corridor floor came back as a gap in the floor with a door in it.

## The seam between two screens

The game flips screens, it does not scroll: two screens are never seen
together. A seam has to read as a continuation - the same things at
about the same heights - and no more. What must be exact is the floor
line and the height of the doorway, and those the grid gives.

- Measure the neighbour's edge in its seated picture (level 2 screen 3,
  right edge: duct 105-143 units, ceiling slab 161-192, cables at 210,
  floor line 288) and put the same things at the same heights into the
  blockout.
- Send the generator a strip of that edge as a reference of its own,
  beside the blockout, and say the edge continues it line for line.
- Ten units of difference in a duct's thickness came back and are not
  seen across a flip.

## The prompt

Attach the blockout first, then the style references: art already
accepted next door (the tunnel gate, a finished room).

What a prompt must say, each line paid for by a generation that went
wrong:

- **One image only.** Asked for two variations, the generator returns
  both side by side on one canvas at half the size.
- **Transparent where the blockout is transparent**, and no rock, sky or
  background painted there.
- **Flat side view, no perspective.**
- **Floors strictly from the side: no visible top surface, no grating in
  perspective; the top edge of a floor is one straight line where the
  blockout has it.** A floor painted with its top face stands half a cell
  off the grid.
- **Which openings run off the edge of the image**, by name, and that no
  frame, door or wall closes them. Unsaid, the generator frames them.
- **Nothing hangs into a passage one figure tall.**
- **A fan well is empty**: a collar round a flat black opening, no
  blades, hub or grille.
- **What the game draws is not painted**: fan blades, smoke, steam,
  sparks, halos in the air, figures, monsters.
- **The inside is darker and lower in contrast than the structure**, so
  a bright figure reads against it.
- **Text**: one stencilled letter, one TeK emblem, nothing else.

The reading of the blockout is spelled out colour by colour: what
mid-grey, navy, a black disc, a white bar, a yellow mark stand for.

A separate object is asked for as "only the artwork that goes inside the
frame, edge to edge", with its bands given as shares of the height.
Props come as one row of separate things on a transparent background.

## When the picture comes back

Look at the alpha, not at the preview.

- A checkerboard that is part of the pixels (the file is RGB) is no
  transparency: ask again.
- Real transparency keeps junk colour under alpha 1-15; a viewer shows
  it as grey smudges. It is still a hole.

Then measure. Scan lines of alpha and brightness across the walls give
every edge in cells; a structure that fits the grid has all its edges at
one fraction of a cell. Draw the grid over the picture and look.

**A picture that is wrong is generated again, not repaired.** Retouching
and warping it costs more than a new generation and shows: a warp that
blends two fits across a wall bends the wall, and a lean of three
degrees reads as crooked. The picture is never resampled piece by piece.

**The grid is not sacred.** A picture that lies by a few units is better
than a bent one. The hero stands by the cell under his middle, so a wall
face a few units off is not seen. What lies by a whole cell is fixed in
`collision`, not in the picture.

**The generator does not hold a width.** Asked for a pit of four cells,
it gave three and a half in one generation and seven in two more. Take
the generation whose proportions are nearest to the old screen and move
the matter to it: a pit, a pair of crates, a monster are a few
characters in `collision` and `entities`.

What may be done to an accepted picture, and nothing else:

- moved as a whole by whole pixels, the part past the screen cut off;
- a fan well painted black, by its own alpha - through a transparent
  well the backdrop shows between the blades;
- a doorway at the edge of the screen carried to the edge by mirroring
  the columns beside it;
- as a last resort for a floor half a cell off, rows inserted above it
  as a palindrome of the rows right above (726, 725 .. 707, 708 .. 726,
  727): every row stays beside its neighbour, nothing is stretched. Over
  a dozen units of it is a reason to generate again.
- a band of whole columns taken out, from top to bottom, where all it
  crosses runs straight across or straight down (a duct, a slab, the
  back wall of a shaft): the place is the one where the column before
  the band differs least from the column after it, and the join is
  looked at. 41 columns left the shaft of level 2 screen 4 to make its
  pit 96 units. What stands on the band's line elsewhere (a junction
  box, a lamp, an emblem) rules the place out.

Whatever was done goes into the sprite's description in the set.

## Seating

- An object's `x`, `y` and `width` are whole units; its height follows
  the picture. A shift under a unit is put into the canvas, not into the
  numbers.
- A room is a canvas of 4:3 at 0, 0, width 512 - 1448x1086 as the
  generator gives it is fine, backdrop density. A small object is kept
  at 6 px a unit.
- No sprite past 2048 px on either side - the oldest cards refuse the
  texture (MSET-FORMAT, "How big a sprite may be"). A wide structure at
  6 px a unit runs into it at 341 units: cut it into strips, or keep it
  at the density it was generated at.
- A prop asked for as squares comes back as it likes: the crates of
  level 2 screen 4 are 1.16 wide to 1 tall. Scale it whole and split
  the lie between its top and its sides (70 units over two cells: 3 a
  side, 2 on top), feet on the floor line.
- Feet stand on a floor's top line. That line is the one to get right;
  ceilings and wall faces forgive a few units.
- Objects are drawn in file order: the room goes before what stands on
  it.
- Draw order of a frame: backdrop, sky, objects, pads, the back layer of
  the dynamics, tiles, figures, the front layer. A fan is in the back
  layer: over the room, under the hero.

## Fans

The art is ready in `ventilation.mset`; none is generated.

- `parent` is the room's tag; `x`, `y` - the middle of the well as
  measured in the seated picture, not as planned.
- `size`: the ring of the `spider` guard spans 82-95.5% of the half
  size, the blade tips of the `heavy` rotor end at 90.6%. A size of the
  opening divided by 0.9 lays the ring on the lip.
- `rpm`: blades are sharp up to 40, a smear from 110, a disc from 230. A
  big fan turns at about 20, a working pair at 60-70 with opposite
  signs, a turbine in a `bezel` plate at 150-180.
- `light` - the glow of the shaft; no `back` over a well painted black.
- A dynamic object rolls its dice from its place (`x`, `y`, `parent`):
  moved, it flickers anew; the order in the list is draw order only.

## Life on a screen

Every repainted screen gets a little life from the dynamics; the picture
is the steady state.

- One lamp a screen is painted unlit and lit by a `faulty` or `dying`
  beacon. Ask the generator for that one lamp switched off.
- **No beacon over a lamp painted lit**: it shows nothing.
- A slow pulse where something is alive, small indicators on machinery,
  sparks from a switchboard - each at its own pace.
- No beacon on the hero's path that would read as something to pick up
  or to avoid.

## Writing the level file

The file is formatted by hand in places: `rigs`, `pads`, `entities` and
`respawns` do not survive a round trip through a JSON writer. Rebuild
only the sections touched (`objects`, `dynamics`, `tiles` come out of a
two-space writer as they are) and carry the rest over as text. LF, no
BOM.

The level's own art lives in `<assetsDir>-objects.mset`, found by that
name, never declared. A new sprite is added at the end: the pictures
before it keep their bytes. A bare name carried by two attached sets
stops the level at load, and level 2 attaches `level1-structures`, which
holds `s01-` to `s17-` names of its own: check a new name against every
set the level declares.

## Checks without the compiler

- The file parses; only the sections meant to change differ from the
  one in the repository; `collision` and `entities` are as they were
  unless the change is about them.
- The loader's rules, ported: pad tags are unique; a stop keeps the pad
  on its screen; a `parent` is carried by exactly one of an object, a
  pad, an entity; a respawn point has a floor; no pad in a wall.
- Jumps, by the ported `JumpReach`, at every phase of every pad.
- The set reads back; the sprites before the new one are byte for byte.
- No sprite of the set is past 2048 px on either side (the test suite
  holds it too).
- A preview: the backdrop at its tint, the objects, the fans, a hero on
  every floor. It is put together by hand and says so; it is not a
  screenshot.

None of this is a live run. First things to look at in the game: the
level loads, the hero stands on every floor, nothing hangs into a
passage.

## Commits

Data only, so no version in the subject. The subjects so far:

- `Put the level 2 screen 1-2 platforms on pads`
- `Stand level 2 screen 3 on a repainted room`
- `Stand level 2 screen 4 on a repainted room`

The docs follow in a commit of their own: the session in
`PORTING-NOTES.md`, both maps, and a line in `ASSETS.md` for every
generated picture. The release script lives outside the repository and
names the sets one by one: a new set has to be added to it.

## Journal

### Сессия: картинки экранов для перерисовки арта (2026-10-02)

Шаг без версии: отладочная клавиша, механика не тронута. Это первый
кирпич конвейера, которым арт первых двух уровней дёшево переводится в
HD: игра выгружает чистые экраны, ChatGPT их перерисовывает, перерисовка
режется на объекты уровня (`objects`), тайлы экрана гасятся, коллизии
остаются как есть.

#### С чего началось
Проба: ChatGPT перерисовал целый скриншот игры (задник, герой, монстры,
HUD - всё в кадре). Вид понравился, как ассет картинка не годится.
Замеры по сетке 16x12:
- По X кромки совпали с оригиналом в пределах 0.1 клетки.
- По Y картинка уплывает сверху вниз: верх большой платформы - ноль, её
  низ - 0.14 клетки, крыша контейнера - 0.45, пол - 0.43 (около 14 игровых
  единиц). Положить как есть - герой идёт над полом.
- На тайлы не режется: платформа нарисована цельным уникальным куском,
  повторяющегося тайла в ней нет.
- Крюки, тросы, машина и опора запечены в горы задника - вырезать их
  оттуда значит получить грязные края.
- Платформы слились с задником по яркости: 70 против 65, в оригинале 108
  против 60.
- Размер выхода ChatGPT выбрал сам: из 1046x812 вернул 1448x1086, то есть
  90.5 px на клетку. Поле 4:3 на Full HD - 1440x1080, 90 px на клетку:
  родной размер генерации почти точно совпал с самым частым монитором.

#### Решения
- Картинка экрана - одни тайлы на прозрачном фоне: без задника, объектов,
  динамики, героя, монстров и HUD. Там, где тайла нет, альфа ноль (под
  ней чёрный). Первый вариант заливал фон чистым зелёным под вырезание по
  цвету и заменён до прогона: зелёный фон модель принимает за часть сцены
  и красит им металл, а ChatGPT умеет и принять прозрачную картинку, и
  отдать перерисовку с прозрачностью. Перерисовка режется по своей
  альфе, цвет фона на входе ни на что не влияет.
- Размер картинки - сетка уровня на `TileArtSize`: пиксель арта в пиксель
  картинки, 1024x768 для сетки 16x12. Берётся из сетки уровня, а не из
  константы и не из окна: широкий уровень даст широкую картинку, а окно,
  полный экран и поля по бокам на неё не влияют. Крупнее не нужно - это
  были бы те же тайлы, растянутые; размер выхода ChatGPT от размера
  входа не зависит.
- Рисуется мимо окна, в target-текстуру (`SaveScreenPictures`): состояния
  паузы нет, кадр в окне не трогается. Игра на время дампа замирает
  (главный поток занят), потом догоняет не больше восьми тиков -
  `MaxFrameSeconds` остальное отбрасывает. Логический размер цели - экран
  уровня в игровых единицах, отсюда масштаб 2 и клетка в 64 px.
- PNG пишет `IMG_SavePNG` из SDL2_image, которая и так лежит рядом с exe.
  `Image.Png` из TitleCard не тронут и в игру не переехал: он нарочно
  обходится без SDL2_image, чтобы инструменту хватало одной DLL.
- Клавиша P, файлы `dump\<id уровня>\screenNN.png` в рабочей папке
  (`bin`), папка - в .gitignore. Сколько экранов записано - строкой
  тикера (в полном экране заголовка нет); то же с папкой и, при неудаче,
  с текстом ошибки SDL - в заголовке окна, как у остальных отладочных
  клавиш.
- Разные картинки одного и того же предмета на разных экранах - можно:
  ящик на третьем экране не обязан совпасть с ящиком на пятом, так даже
  живее. Канона и реестра объектов нет, экран самодостаточен.
- Вес. Тайлами занято в среднем 39% клеток экрана на первом уровне (от 9
  до 100) и 59% на втором. Фотореалистичный PNG - около 2 байт на
  пиксель, так что два уровня (26 экранов) - около 20 МБ при 64 px на
  клетку и около 40 МБ при 90. Сжатие с потерями и ужатие до 64 px - не
  сейчас: объёмы смешные, а родной размер генерации как раз попадает в
  Full HD. Мастера хранятся в том размере, в каком пришли.
- Второй репозиторий и докачка арта самой игрой отклонены: при таких
  объёмах это лишняя машинерия. Игрок получает вес через релизы. В
  репозиторий идёт только принятый вариант экрана, черновики - снаружи.
- Свет: нарисованный свет на железе остаётся, поверх ставится маячок -
  отсвет на металле вокруг лампы маячок не умеет, а ореол в воздухе при
  нарезке отбрасывается, и его даёт маячок. Выключенный плафон
  просим только у ламп, которые мигают или меняют цвет: погасший маячок
  над нарисованным светом читается как "ярко - чуть менее ярко".
- Привязка при нарезке - по объекту: каждый сажается в свой прямоугольник
  клеток из JSON уровня, так что общий уплыв перерисовки по вертикали
  перестаёт иметь значение.
- Уровни 1-2 остаются 4:3 насовсем и в широкий кадр не переводятся: позже
  они сносятся и рисуются заново. 16:9 - только новые уровни из редактора;
  конвейер для них тот же, в начале вместо старых тайлов - набросок
  экрана в редакторе.

#### Проверка без компилятора
- Стенд: та же последовательность вызовов SDL, что в `SaveScreenPictures`
  и `SaveTargetAsPng`, исполнена из Python (pysdl2) на настоящей SDL
  2.32.10 - версия та же, что в `bin`; SDL_image на стенде 2.8.12, в
  `bin` 2.8.8, запись PNG в обеих идёт через встроенный miniz. Тайлы
  читаются из наборов уровня тем же путём, что в игре (`IMG_Load_RW`,
  чёрный color key, кроп 64x64, клетка 32 единицы). Окно стенда - 1920x1080
  при логическом размере 512x384, то есть с полями по бокам. Все 26
  экранов записаны.
- Сверка: независимый рендер тех же экранов на Pillow прямо из
  level*.json и .mset. Расхождений с картинками стенда - ноль пикселей на
  всех 26 экранах по всем четырём каналам: под тайлом альфа 255, вне его
  все четыре байта нули. Так на трёх бэкендах: software, opengl и
  opengles2.
- Очистка цели в (0, 0, 0, 0) пишет нули при любом режиме смешивания
  кисти (none, blend, add) на всех трёх: `Render.Brush` оставляет режим
  каким придётся, и дампу до него дела нет. Строка в TitleCard, ставящая
  перед очисткой режим none, для этой версии SDL не нужна и сюда не
  перенесена.
- Логический размер: на свежей цели он равен размеру текстуры при
  масштабе 1; после установки 512x384 - масштаб 2 и вьюпорт во всю цель;
  после возврата цели окну SDL сам возвращает окну его вьюпорт
  (85, 0, 512, 384), масштаб 2.8125 и логический размер. Кадр, нарисованный
  в окно после дампа, совпал с кадром до него пиксель в пиксель. Отдельной
  строки для возврата в коде поэтому нет.
- По исходникам SDL 2.32.10: запоминание и возврат вьюпорта, масштаба и
  логического размера при смене цели - общая часть, одна на все бэкенды.
  Чтение пикселей и сама цель - у каждого бэкенда свои. Под Direct3D 11
  ABGR8888 не родной формат: SDL заворачивает цель в родную
  ARGB8888-текстуру и при чтении переводит обратно в R,G,B,A. Завёрнутая
  цель на opengl и opengles2 проверена теми же 26 экранами - ноль
  расхождений.
- `SDL2_image.dll` из `bin`: экспорт `IMG_SavePNG` есть, путь записи через
  miniz собран (строка "Failed to convert and save image").
- Чтения: "за компилятор" - чисто; на исполнение - дефектов в коде нет,
  поправки ушли в эту запись и в имена.

#### Открытое
- Delphi это не собирал, и под Direct3D 11 это не исполнялось: его путь
  прочитан по исходникам, а target-текстура в игре - впервые. Первое, что
  смотреть на прогоне: файлы появились, размер 1024x768, после P игра
  рисуется в прежнем масштабе, в окне и в полном экране.
- Дамп трогает экраны, до которых игрок не дошёл. Имя тайла, которого нет
  в наборах, поднимет исключение на P и закроет игру тем же окном ошибки,
  что и в обычной отрисовке; на нынешних данных все 26 экранов рисуются.
- Проба на первых двух экранах должна показать: как ChatGPT читает
  прозрачный вход и насколько чистую альфу отдаёт (тросы, края, ореолы
  ламп); герой стоит на полу; тон первого и второго экрана совпадает
  (иначе тон подгоняется к первому при нарезке, а первый принятый экран
  прикладывается к ChatGPT образцом); реальный вес и время на экран.
- Конструкции переходят через границу экранов почти везде: тайлы стоят в
  одной строке по обе стороны стыка на 15 стыках из 16 на первом уровне и
  на 7 из 8 на втором; без строк, залитых во всю ширину обоих экранов
  (пол), - на 13 и на 5. Половины одного дома перерисовываются порознь;
  экраны листаются, а не прокручиваются, так что шва в кадре нет, но дом
  по обе стороны двери должен остаться тем же домом - вопрос пробы.
- Экраны 12-13 - тёмные тайлы поверх чёрного задника: что с ними делает
  перерисовка, неизвестно.
- Один пак объектов на уровень (`<assetsDir>-objects.mset`) значит, что
  правка одного экрана кладёт в историю гита весь пак заново. Пак на
  экран это снимает; не решено.
- Гашение тайлов экрана - только данные: строки `rows` обнуляются,
  `collision` остаётся (в формате они раздельны). Делается вместе с
  расстановкой объектов, не раньше.

#### Коммиты
Dump the level's screens as pictures on P; Update the docs for the
screen pictures.

---

### Сессия: перерисовка второго уровня, экраны 1-3, без версии (2026-10-07)

Первые три экрана второго уровня переведены с тайлов 2008 на объекты, пады
и динамику. Код не тронут: `bin/level2.json` и новый набор
`bin/sprites/level2-objects.mset`. По ходу записан конвейер -
`docs/REPAINT.md`.

#### Экран 1 - арена, сдвинутая влево
- Экран был собран из объектов первого уровня: арена экрана 17 на шесть
  клеток левее. Её платформы стояли картинками поверх твёрдых клеток.
- Семнадцать картинок `s01-plat-*` стали двенадцатью падами в обвесах
  `pad` и `padBroken` (обвесы записаны в `rigs` этого файла ещё раз);
  отдельные лампы на них ушли из `dynamics` - их несёт обвес, заодно
  появились марево и струи.
- Пять падов, изображавших пол, убраны: вернулся `s17-floor` (x -128,
  ширина 288). В `collision` остались земля и кран.
- В правой части паром: `s01-plat-12` ходит между x 288 и 352. Остров
  перед ним сокращён до двух клеток - иначе провал перепрыгивался без
  парома.
- Растения (`s14-growth`) с падов сняты вместе со своими лампами: пад
  качается и ездит, статичный объект - нет, и они расходятся.

#### Экран 2 - яма
- Нижний ряд тайлов убран, под ногами бездна.
- Вход опущен с y 64 на 160, на линию обрыва: наверху герой сливался с
  освещёнными горами задника, и так высоко его никто не ждал; ниже, в
  черноте (проба на y 288), он оторван от картинки. `heroY` и точка
  возрождения - строка 5.
- Три пада с разными периодами (4.6, 11.6 и 10.5 с): вбок, вверх-вниз и
  по диагонали. Диагональный в нижней точке встаёт вровень с полом
  туннеля и ждёт 1.5 с: проём в одну клетку, из прыжка в него не попасть.
- Два треугольных тайла входа тоже стали падами, неподвижными, и
  опущены вместе с входом: точка возрождения экрана стоит на первом из
  них.
- Грейвел экрана несёт заголовок "Спуск в туннели" и `heroY`; без пола он
  падал бы в яму при каждом входе. Переставлен в проём туннеля.
- Вход в туннели - объект `tunnel-gate` (678x700, 6 px на единицу, 113
  единиц). Генератор закрыл проём стойкой слева; стойка вырезана,
  интерьер сдвинут к краю.

#### Экран 3 - зал секции A
- Один объект `s03-room` на весь экран, тайлы погашены, `collision` и
  сущности прежние. Нижние турбины и жалюзи 3.0.25 остались.
- Три вентилятора `heavy` за `spider`: один в 100 единиц в зале (22
  об/мин), два по 53 в запечатанной камере под коридором, навстречу друг
  другу (64 об/мин). Поставлены по замеренным колодцам.
- Маячков на лампах нет: лампы нарисованы горящими.
- Принята третья генерация. В первой пол коридора был разрезан дверью
  (в блокауте сквозь пол шли две трубы), а пол ниши выхода стоял на
  клетку выше. Вторая отдала шахматку вместо прозрачности.
- Первая генерация была выправлена ретушью и кусочной подгонкой к сетке
  и отвергнута: подгонка, которая сшивает две раскладки поперёк стены,
  гнёт стену.
- Третья лежит как пришла, без пересэмплирования. Сделано с ней: колодцы
  закрашены чёрным; над настилом зала повторены 40 строк, над настилом
  ниши выхода - 18 (полы нарисованы с видимым верхом и стояли на
  полклетки выше линии, а полклетки материей не выразить); проёмы входа
  и выхода дотянуты до краёв экрана; картинка сдвинута вниз на 29 px.

#### Решения
- Неподвижная платформа - всё равно пад, а не тайл и не картинка поверх
  твёрдой клетки.
- Неверную картинку дешевле сгенерировать заново, чем чинить. Кусочная
  подгонка картинки запрещена.
- Сетка не святыня: враньё в несколько единиц лучше гнутой стены;
  расхождение в целую клетку правится в `collision`.
- В промпт вошло правило пола: строго сбоку, без видимого верха, верхняя
  кромка - одна линия там, где она в блокауте.
- План с номерами и настоящими вентиляторами - для чтения. Генератору
  идёт только чистый блокаут: он рисует то, что видит.

#### Находки
- Зёрна динамики идут от места (`x`, `y`, `parent`), а не от порядка в
  списке: лампа, переехавшая из `dynamics` в обвес, мигает иначе.
- Прозрачность генератора бывает нарисованной (файл RGB), а настоящая
  хранит под альфой 1-15 цветной мусор: смотреть альфу, а не превью.
- Просьба о двух вариантах возвращает оба на одном холсте в половину
  размера.
- Файл уровня местами отформатирован руками (`rigs`, `pads`, `entities`,
  `respawns`): через JSON-писатель его целиком гонять нельзя.
- `level1-structures`, который объявляет второй уровень, держит имена
  `s01-`..`s17-`: имя нового спрайта сверять со всеми объявленными
  наборами.

#### Проверка без компилятора
- `JumpReach` перенесён на Python, таблица сошлась с картой. Паром
  экрана 1 достижим с обеих сторон на любой фазе, без него уступ
  недостижим. На экране 2 каждый прыжок удаётся на любой фазе; мимо
  среднего пада есть редкий длинный прыжок (9% времени); ход падов в
  модели линейный.
- Правила загрузчика перенесены: теги падов, остановки в пределах
  экрана, родитель ровно одного рода, пол под точкой возрождения, пад не
  в стене.
- Набор читается обратно, `tunnel-gate` после дозаписи `s03-room` - байт
  в байт.
- Сетка наложена на посаженную комнату; превью экранов собраны руками
  из наборов, это не кадры игры.

#### Открытое
- Delphi это не собирал и никто не играл. Смотреть: уровень грузится;
  герой стоит на уступе входа экрана 3 и не уходит головой в потолок
  коридора; пад экрана 2 стыкуется с полом туннеля.
- Экран 2 по модели лёгкий: сложность в посадке на едущий пад, а не в
  окне. Ручки - ходы и скорости `s02-plat-01` и `s02-plat-02`.
- `s01-plat-02` недостижим, как и до перерисовки.
- Нижние турбины и жалюзи экрана 3 рыжее новой комнаты: их тинт
  80/80/82 подбирался под тайлы 2008.
- След вставки строк на экране 3: лишняя пара хомутов на трубах камеры
  и удвоенная планка над полом зала.
- Пропсы экрана 3 (пульт, тележка, баллоны) не сделаны; одна лампа,
  погашенная в картинке и зажжённая маячком, - тоже.
- Скрипты блокаута, посадки и упаковки набора в репозиторий не вошли.
- Скрипт релиза (вне репозитория) не знает `level2-objects.mset`.
- Экраны 4-9 - тайлы 2008.

#### Коммиты
Put the level 2 screen 1-2 platforms on pads; Stand level 2 screen 3 on
a repainted room; Update the docs for the level 2 repaint.

---

### Сессия: перерисовка второго уровня, экран 4, без версии (2026-10-08)

Четвёртый экран второго уровня переведён с тайлов 2008 на объекты, пад и
динамику. Код не тронут: `bin/level2.json` и два новых спрайта в
`bin/sprites/level2-objects.mset`. Конвейер - `docs/REPAINT.md`, в него
дописано найденное здесь.

#### Экран 4 - коридор над грузовой шахтой
- Воздуховод экрана 3 входит слева и кончается коробом на плите потолка
  над шахтой. Яма - шахта, уходит за нижний край.
- Яма расширена с двух клеток до трёх (колонки 8-10 от единицы): её
  нельзя перепрыгнуть. Через неё ходит один пад-паром `s04-plat-01`,
  x 224 - 288, скорость 30, пауза 1.5.
- Ящики сдвинуты на клетку вправо, вплотную к правому краю ямы: с пада
  на них запрыгивают. Они по-прежнему материя, картинка - объект
  `s04-tek-crates` (70 единиц на две клетки).
- Сущности не тронуты: винтер, бочка и стрелок стоят как стояли.
- Динамика на `s04-room`: погашенная в картинке лампа над ямой зажжена
  маячком `faulty`; щиток на левом берегу искрит и коротит (длина
  разряда 30); в глубине шахты медленный пульс.

#### Решения
- Задумана была яма в четыре клетки. Генератор отдал три с половиной в
  одной генерации и семь в двух других; у генерации с семью правому
  берегу не хватало места на ящики, бочку и стрелка. Взята первая, а
  материя подвинута к картинке.
- Три клетки хватает: под потолком этого коридора прыжок несёт героя на
  72 единицы, яма - 96.
- Из шахты вынута полоса в 41 колонку: нарисованная яма была 111 единиц,
  и края пола лгали бы на 7 единиц с каждой стороны, а там решается
  жизнь героя. Полоса взята там, где всё в ней идёт ровно поперёк или
  ровно вниз, по наименьшей разнице колонки до и колонки после.
- Картинка сдвинута целиком на 30 px вправо и 88 вниз; проёмы дотянуты
  до краёв зеркалом (37 и 18 колонок) - на краях вышли сдвоенные фланцы.
- Шов с экраном 3 - не пиксель в пиксель: игра листает экраны, оба разом
  не видны. Совпадают линия пола и проём; воздуховод на экране 4 толще
  на десять единиц.

#### Находки
- `JumpReach` не знает о потолках. В коридоре высотой в три ряда герой
  бьётся головой, и прыжок короче: 72 единицы с пола на пол, 56 на ящик,
  54 с ящика; ледяная форма делает его ещё короче. Яма 2008 в две клетки
  поэтому бралась с запасом в 8 единиц.
- Генератор не держит ширину проёма, заданную блокаутом.
- Ящики, заказанные квадратами, пришли 1.16 к 1.
- Одна из трёх генераций пришла шахматкой в RGB.

#### Проверка без компилятора
- Файл разбирается; против репозитория отличаются только `objects` (+2),
  `pads` (+1), `dynamics` (+4) и экран 4 в `tiles`; LF, без BOM.
- Правила загрузчика: теги падов, остановки в экране, пад на всём пути
  вне стен, родитель динамики ровно одного рода, пол под точкой
  возрождения и под каждой сущностью экрана.
- Прыжок посчитан по дуге `Tick` с `BumpCeiling`: без пада яма не
  берётся ни с пола, ни на ящики, ни с ящиков.
- Набор читается обратно, `tunnel-gate` и `s03-room` - байт в байт.
- Сетка наложена на посаженную комнату; превью собрано руками, это не
  кадр игры.

#### Открытое
- Delphi это не собирал и никто не играл. Смотреть: герой стоит на
  обоих краях ямы; с пада запрыгивается на ящики за паузу в 1.5 с;
  лампа над ямой и пульс в шахте не кричат.
- Подступенок ступени выхода нарисован на 6 единиц левее материи.
- Герой на ящиках стоит на 2 единицы выше нарисованного верха.
- Экран 3 по-прежнему без пропсов и без погашенной лампы.
- Скрипты блокаута, посадки и упаковки в репозиторий не вошли.
- Скрипт релиза (вне репозитория) не знает `level2-objects.mset`.
- Экраны 5-9 - тайлы 2008. На экране 5 тоже стоят ящики TeK.

#### Коммиты
Stand level 2 screen 4 on a repainted room; Update the docs for the
level 2 screen 4 repaint.

---
