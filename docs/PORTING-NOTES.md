# Moon 2D Remake - handoff notes (3.0.x: finishing after the 2008 mode left)

Status at 2026-11-07: **3.0.113** - arena 3 (the finale of level 2),
stage 18c-3: the Ram takes off on engine bays and nozzles out of its
wheel arches, with a new fire. In
work: arena 3, its file `docs/mechanics/arena-3.md`; what each version
brought, a paragraph each - `CHANGELOG.md`. The status here is a few
lines: the version, what is in work, where to read; the details of a
version live in CHANGELOG, not here.

What this file holds: the architecture, the coordinate constants, the
deliberate deviations from 2008, the debug keys, the open questions of
the original - what is, now. What it does not hold: the order of the
next steps (`ROADMAP.md`), the plans of things not built yet (`plans/`),
the journal of the 2.x port (`PORT-JOURNAL.md`). A working chat on a
mechanic reads this file and its mechanic's file - and does not go into
the roadmap and the plans: the future is not its context.

The 3.0 release ships at whichever 3.0.x ends the external
transformations; no number is set; its contents and what is left -
`ROADMAP.md`. For the old look, download release 2.5.3; the game itself
has no museum.

Code style of the project: CODESTYLE.md 4.9 in the project files; 3.x is
legacy.

## Architecture (units)

The units live in the folders Core/, Game/ (with Game/Events/), Hud/,
Menu/ (since the layout after 3.0.8); which unit lives where and the
layer rule - CODEBASE-MAP, section "Source layout". The table below is
about responsibility, not paths.

| Unit | Responsibility |
|---|---|
| Moon2D.dpr | Startup: config, language, the search for level*.json (DiscoverLevels by LevelFilePattern from Game.Moon), the monster registry, the SDL host, the game; a startup error goes to a message box. The uses clause with paths is the manifest of the project's units: a new unit goes here and into the dproj |
| Game.Moon | TMoonGame - the game the program runs (moved out of Moon2D.dpr word for word on 2026-10-25, before stage 8 of arena 3): LoadLevel from the menu assembles a level (sets, caches, renderers, field, HUD, event and scene directors). TMoonGame: states gsMenu/gsIntro/gsPlaying/gsEnding, bullet collisions, contacts, checkpoints, monster events (the blast and the rage sound live here too), the gravel trial, the bonus slot, LocateParent for dynamics (a pad or a monster; a sleeping pad is not alive), SceneStage for scenes, the layer order of a frame, CreateHud - the corner HUDs and the rows over the figures anew for every level; the ceremony goes through FHenshin, the look of blasts through FExplosions |
| Sdl2.Core | Minimal SDL2 bindings (window/render/events/mouse/textures) |
| Game.Loop | TGameHost + fixed timestep (Gaffer), the TGameApp base |
| Game.Config | Two layers: the shipped bin\config.json (read only) and the player's %APPDATA%\Moon2D\settings.json (difficulty, language, full screen; overrides key by key); tickRate=33 - the REAL rate of the original WM_Timer(20 ms) on a live Windows |
| Render.Sprites | Texture cache from .mset sets (PNG; black color key by default, DisableColorKey and EnableLinearFilter for HD art; a name with its set, set:name), TAnimSet 8+8 from the set's sequences, TSpriteRenderer: Draw 32x32, DrawTile (a 64 px crop into a cell), DrawTurned - a fractional square with rotation and alpha. TileSize=32 UNITS and TileArtSize=64 PIXELS - do not mix them up |
| Levels.Defs | level*.json: the grid, tiles + collisions (SolidAt), backdrops, the spriteSets/objectSets sets, static objects (Objects), dynamics (Dynamics, the list lives here), entities with overrides/triggers and a tag, events (Events), scenes (Scenes, 3.0.62), the entity shift shiftX (3.0.67), closed doors (shutDoors, DoorShutOn, 3.0.66 - the load rejects a door nothing opens, and an opening on an open screen); on load CheckEvents, CheckDynamics and CheckScenes reject a foreign screen, a tag and a parent with no carrier, a craft after its own child, a sleeping pad no scene wakes |
| Levels.Events | The events section of a level: TLevelEvent (screen, condition enterScreen/allDead/livesBelow/enraged, tag, lives threshold, delay, actions bigMessage/smallMessage/hint/music/intensity/sun, then the arena actions of 3.0.53-3.0.59 and scene 3.0.62, openDoor 3.0.66 (opens the screen's door and shows the arrow itself), condition heroStands 3.0.67 (the hero stands in cell x, y); hint has an optional header - the voice), dictionaries of conditions and actions as constants, ParseLevelEvents. Model and parser, no logic; action energy 3.0.70 (value 1..100 - the form's charge, orbs from the hero into the gauge); action respawn 3.0.71 (x, y from 1 - the checkpoint to a cell of the event's screen; on load Levels.Defs holds the cell to the rules of a respawn point, CheckRespawnCell) |
| Events.Director | TEventDirector - runs events on the live game: Tick(screen, field) checks the conditions of the screen's unfired events, counts down the delay, plays the actions once; ReArm(screen) on a restart; music through the game's ChangeMusic callback. Born with the level; the actions intensity and sun go to the level's dynamics (TDynamicObjects), ReArm rolls back to the file values of the intensity target; action scene is a StartScene signal to the scene director (3.0.62); since 3.0.70 the Energy callback (TEnergyCue); since 3.0.71 the Respawn callback (TRespawnCue, the game's MoveCheckpoint) |
| Render.Tiles | Backdrop + tiles cropped 64 into a cell; DrawBackground/DrawTiles are public - the shake moves them apart |
| Render.Shake | Screen shake: one trauma meter per game, three offset channels (world/hero/monsters). Render only, the logic does not see the offset |
| Render.Brush | The brush of panels drawn with primitives (HUD, difficulty cells in the menu), plus colour and chance (TRgb, Mix, TXorShift) for Render.Glow, Render.Globe, Render.Puff, Effects.Debris, the dynamics, the blasts, the boss disc and the menu sky: Fill/Glow/Frame/3x5 digits through SDL_RenderFillRectF, the health row cells (FullCell/EmptyCell/BonusCell), palette + HealthColor, the panel geometry 118x32, its own xorshift. Before the folder layout it was Hud.Draw; the class is still THudBrush; digits at any pixel size (DrawNumber/NumberWidth with APixel, 3.0.70 - the number in the charge disc) |
| Hud.Vitals | Health: THudVitals - the heart monitor (a row of 5 norm cells + the light-green bonus past the divider, the pulse by health); a wing on the right inside the panel frame (Wing, 3.0.70) - the form charge slot, drawn by Hud.Energy |
| Hud.Charge | Points: THudCharge - the bonus charge up to 50, the badge of a waiting reward, the streak row of 10 |
| Hud.Energy | Form charge (3.0.70): TEnergyReading - the reading (Tick(charge): the slot opens with the first charge and folds without it, the arc catches up with a rise in a flash, a fall is at once), THudEnergy - the eclipse in the slot right of the monitor: a black disc in a halo, the arc along the rim in strips of light (SDL_RenderGeometry over gsBeam), the number in the middle; Heart - where the orbs fly, WingWidth - how far to open the monitor panel |
| Hud.Marks | Health rows over figures: the hero's has the monitor's grammar (norm/outlines/bonus past the divider), a monster's has 6 cells - a pair per third, coloured by the crosshair's thirds; shown after a change, fades; rides on the figures' shake channels |
| Game.Bonus | TBonusKind + BonusCost=50 - the shared roulette vocabulary of the game and the HUD |
| Game.Shroud | The hero's shroud (3.0.47): smoke and light over the hero's frame on its own clock. TShroudLook - a record of a scene's look (the looks PitLook, EntryLook, ReviveLook, IceOnLook, HeatOnLook, IceOffLook); THeroShroud computes (clock, strips, slices, particles, mist; does not touch SDL, its own dice TXorShift); TShroudPainter draws (masks, halos and birth points from the hero's 24 frames at load; DrawUnder/DrawBody/DrawOver around the hero's drawing; SeedsOf gives a frame's points to the rite and the drawing-in, MaskOf (3.0.61) - a white mask of the frame to the burst's silhouette). A strip that reaches the feet tears off and lives on the screen as mist. Does not know the hero: takes sizes and shapes from the frames |
| Game.Henshin | THenshin - the transformation ceremony as one state machine: countdown 3..2..1, the rite of orbs (Orbs.Rite, 3.0.49), the burst (Orbs.Burst, 3.0.61), the suit put on at the strike of the burst (Finish) and taken off by a ring of orbs (RemoveIceForm), Reset on a restart. No clock of its own: listens to the events of the rite and the burst (HearRite, HearBurst). The stage THenshinStage (hero, sound, board, shake, shroud, rite, burst) + callbacks THenshinCalls (Cure, GrantMercy, BeginRite, ShedSuit, Burst); the shake dose, sounds; the suit's light - shroud looks (ChargeLook, IceOnLook, IceOffLook). Born with the hero for every level |
| Orbs.Flock | TOrb, TOrbFlock - the flock of orbs shared by the aura, the rain and the rite: the look, three ends (collapse, dust, release), a trail on the edge, depth and two layers around the hero (3.0.49). What an orb hits is decided by the dpr (ResolveOrbHits); the dark orb (TOrbTint.Dark, MoonOrbTint, 3.0.70): a black body over the world, a white rim, a dense halo, 2 units bigger than the ice one |
| Orbs.Harvest | Where orbs come out of matter: TMatter (screen cells and pad bodies), HarvestSpots for the aura, HarvestAround for the rite, in waves and from all sides. Knows neither the level nor the pads |
| Orbs.Aura | TAura - a ring of orbs around the hero: the aura reward and key G |
| Orbs.Rain | TOrbRain - a fire rain of orbs: the reward and key H |
| Orbs.Patterns | Henshin patterns (3.0.49): a pattern is a function of place and a word; snowflake and vortex, FindPattern; the word is henshinPattern in the level file |
| Orbs.Rite | TOrbRite - the henshin rite (3.0.49): three waves out of matter, the flight into the pattern, swaps, the freeze, the collapse over the body; taking the suit off with a ring (Shed). All the numbers are the score IceRiteScore. Speaks in events; what they mean is decided by Game.Henshin |
| Orbs.Burst | TOrbBurst - the suit's burst (3.0.61): the inhale (the world stands), a strike of 24 rays, the flight through walls past the screen with traces on the edges, an echo of dust motes. Look and timing only: what a ray hits is decided by the dpr over segments (ResolveBurstHits). The form's look TBurstLook: IceBurstLook, MoonBurstLook |
| Orbs.Feed | TOrbFeed (3.0.70) - orbs carrying charge into the gauge: the charge is split into 5 orbs at most, they come out of the hero one by one, hang over him and keep to him, fly off to the middle of the disc; TakeLanded - how many arrived, Pending - how many are on the way, Collapse - death. They hit nothing |
| Game.Space | Two sizes of space: the level SCREEN (ScreenCols/Rows 16x12, ScreenWidth/Height 512x384 - cells, walls, doors, bullets) and the window FRAME (FrameWidth/Height - the SDL logical size, HUD corners, centring, menu). Equal until the wide frame |
| Hud.Messages | Ticker, big headline, point popups and the comms terminal (owns THudTerminal); the ticker at 52 moves down under the terminal frame while the frame stands |
| Hud.Typewriter | TTypewriter - typing one letter a tick: a line break = a tick, a paragraph pause of 12 ticks, a click on every second letter, a blinking cursor. Logic only; shared by the terminal and the briefing |
| Hud.Terminal | THudTerminal - the comms frame under the monitor (x=6, y=40, 360): word wrap at 45 glyphs, typing, reading 1 s + a tick per letter, fade-out |
| Hud.Briefing | THudBriefing - the text before a level over the menu sky: the author's layout, a backing with no frame, the header `briefingHeader` ("ЖУРНАЛ МИССИИ", en "MISSION LOG"), the hint `pressAnyKey` after the typing |
| Monsters.Defs | monsters.json -> TMonsterDef (since 3.0.67 the picture can turn and hover - turn, hover; since 3.0.68 anchored - the body is moved by no hit, no blast and no pad under it, and invulnerable - loses no lives): movement/attack enums, spawnTable (PickSpawn), pickups with weapon parameters, deathSounds, the blast look (explosion: barrel/machine/boss), the material (material: metal - a bullet knocks out sparks), the disc section (TDiscDef: set, side, muzzle, spin, irisReach, wearFull; a broken disc fails at load), the hull section (THullDef: set, width, height, wearFull, eye, smoke, sparks; a broken hull, and a monster with both a disc and a hull, fail at load) |
| Hero | A verbatim port: physics, 6 collision oracles, mouse facing, arm + barrel in 4 branches, the HENSHIN form (hfIce), death/Revive. The frame pose - THeroPose/Pose (the only place a frame is chosen), DrawArm - one arm for the time the shroud assembles, SkinSet - the frame set for the shroud. Since 3.0.75 Throw - a throw off the machine (a jump sideways, 14 ticks without control) and InAir |
| Bullets | Ballistics dy+=g/100, Contact (bullet interception), k/t fans (SpawnFan); the barrel's 10x18 fan left in 3.0.41 |
| Monsters | Data-driven dispatch, spawn from the sky, rages, the blast by `blast` (the wave - in Game.Blasts); TicksSinceHit/HitWithin - the memory of a hit for the HUD, HealthTier/TierShare - the crosshair's thirds; the placement Tag + AnyAliveTagged for events; smoke and sparks of damaged machines; the disc monster: TickDisc feeds TDisc, a shot from the rim, the field owns the discs' art (DiscArtFor); the scene's hands (3.0.62): Held (fire held), Dormant (sleep), Smite (death with no reward), Stand, Vanish, by tag HoldTagged/SmiteTagged/ReleaseTagged/RemoveTagged, SpawnStanding |
| Monsters.Hull | A monster drawn as a hull of two layers (the flying platform): THullArt - the set's layers through its own cache with no key and the eye's glint, THull - wear, the eye with its shot charge, Spot (a point of the art on screen). The twin of Monsters.Disc without spin and iris; the hull is not mirrored. Since 3.0.75 Draw = DrawUnder (arches, wheels) + DrawBody (hull, wear, eye): the Ram puts its mast between them |
| Game.Wrecks | Pads knocked off by the sweeper's wave (3.0.81) and by the bunker's shells (3.0.94): TPadWrecks - the rules of a wreck's flight (slow course, fast spin, none falls onto the road; a new one takes the place of one gone), TPadWreckPainter - the pad's picture at an angle, fire, sparks, glow, lightning; the pad itself is put to sleep (TPad.Doze), a death gives it back |
| Game.Capsules | The shuttle's medkits in the Ram fight (3.0.84): TShuttleCapsules - a capsule's fall to a mark with braking, the landing, the shell opening, the medkit's mark; since 3.0.94 rides with the chase belt (Ride); TCapsulePainter - hull, cross, beacon, flare and shell halves in code; the game puts the medkit on the mark |
| Game.Belt | The treadmill of the Ram chase (3.0.86): only the road's motion - start and stop as a smooth step over 2 s, the tick speed, the distance travelled; knows neither the Ram, nor the hero, nor the picture; the game carries the world and moves the road |
| Game.FarPlane | How far each layer of the chase's far plane has travelled (3.0.88): the bench's rules tick for tick - the tunnel and the city until the rock leaves, a smooth way out to cruise, the city's brake at the end of the band, the ridge at a share of the city, the ground and the fangs (3.0.89) at their own speed, all at a share of the belt's speed; knows neither the belt nor the hero; since 3.0.92 Clock - the city's clock, ticks from the road's first motion; since 3.0.93 ClockAt(alpha) - the clock between ticks, like OffsetsAt |
| Game.Fangs | The chase's fangs (3.0.89): TFangRow - a row of basalt spurs by the run of their layer, every number from the dice, tall ones rarely and never two on a screen, none hangs; TFangPainter - a kit of level objects, a tint by the tunnel's leaving, a mirror |
| Pads.Drift | The chase's pads (3.0.87): from the screen's pool feeds them in from beyond the right edge by the road's run, in groups - a lone pad or a random climb to the hatch's height, a safety climb, no more than 10 at once; a medkit on the middle pad of one climb in three - gives the mark to the game (`TDriftCue`); since 3.0.97 at the game's word - the hunt wave, three dense rows, flying in at once; since 3.0.98 only on the pass, on the decks of a climb, rows from three sides, groups denser after it; knows neither the belt, nor the hero, nor the monsters |
| Game.StoneTank | The hidden tank of form charge in the Ram fight (3.0.85, 15b - 3.0.94): the heads' wounds go into the tank late, the gauge drinks in uneven pulses, a drop, the heads' ceilings (30, 55, 95, 100), a head's death tops up to its ceiling, the last one's to full; knows neither the Ram nor the gauge, the game reports wounds and deaths |
| Game.Ram | TEK-R13, the Ram (3.0.75): TRam - the rules (the drive-in whole and from a mark, the brake, the mast, the sway, the stop lights, the patrol, the contact with the pad rule, the shield over the silhouette), TRamArt - the tek-machine art and the hull mask from alpha, TRamPainter - draws through THull, the mast with a clip; the game runs TRamCue; since 3.0.94 the third head - the bunker (the hatch breathing, the shell throw, the column, a hit from above, honeycomb on the sides and in front); since 3.0.96 its second phase - falling back to the middle with a warning by the eye, the bunker's silence, a throw over the hull from the road behind the stern, shells in pairs; since 3.0.97 the third - the hunt, since 3.0.98: the change with the alarm and the wave, a pass through the hero past the left edge with a throw to the right, a turn off frame (the hull mirrored), driving in nose first, the nose a step behind the hero in the left half, now and then a dash almost to the right edge, back only toward a hero behind the stern, the ram to the right |
| Game.Shells | The bunker's shells in the Ram chase (3.0.94): TBunkerShells - an arc to the hero's feet aimed into the world (the road carries it), the fall ring every tick, a blast on the deck (the game knocks the pad off), rolling left faster than the road and a wound on touch; TShellPainter - ring, shell, trail in code; since 3.0.96 SecondShellMark - where the second shell of a pair goes, since 3.0.97 AheadShellMark - the same in the hunt, at a pad ahead along the row; knows neither the pads, nor the hero, nor the bunker |
| Monsters.Disc | A monster drawn as a spinning disc of layers (the level 1 boss): TDiscArt - the set's layers through its own cache with no key, TDisc - the pose of two ticks and the drawing between them (rim, core, iris, glint, battered copies, the sensor glow). Art and pose only, knows nothing of the monster's logic |
| Game.Blasts | What a blast does: `TBlast` - a wave from the heart of the body, 8 units a tick up to the radius; hits a body once, at the point nearest the heart, lives and the shove fall off with straight-line distance, something solid on the way gives cover. Knows neither monster nor hero: the game hands out the hits (`ResolveBlasts`) |
| Monsters.Damage | A monster's damage ceiling window (`TDamageCap` from monsters.json): `TDamageWindow` - a ring of `Ticks` cells, `Advance` once a tick, `Admit(losses)` returns what counts, the excess burns. Only the count of lives: the shove, the thresholds and the hit flashes stay with the monster |
| Render.Glow | Light in code: white textures with the shape in alpha (point, flare, starburst rays, a spark stroke, any surface), additive, linear filter; DrawGlow/DrawGlowRect - the hue by color mod, the level by alpha mod. BlurImage and CreateGlowFromImage (a glow out of an image of levels, moved out of Menu.Logo in 3.0.47). Stars, embers, halo, beacons, the boss's sensor, the shroud's halos; since 3.0.70 a disc with a sharp rim gsDisc and CreateShadeShape - the same shape by blending, draws a hole in black |
| Menu.Starfield | The menu stars: three layers by density per frame area, hues by temperature, twinkle, its own xorshift (seed "Moon"); Draw(alpha, zoom) - the share of the zoom per layer (0.4/0.7/1.0) |
| Render.Globe | A celestial body on the CPU (TGlobe): map -> a 4-level pyramid -> the disc table (row, longitude-turn, level, normal); LightFrom(sun) - regolith light (Lommel-Seeliger) or matte (Lambert), the night map, atmosphere (haze toward the limb, halo); redrawn only after changes; {$O+,R-,Q-} |
| Menu.Globe | The menu moon - a thin wrapper over TGlobe: the look MoonLook (512, regolith, earthshine, the cold tone of 2008), the sun still, a turn in 80 s |
| Menu.Logo | The logo and its light: letters + halo (alpha /4, three box blurs and normalisation through Render.Glow, the hue from the ink, a 16 s breath) + owns TEmbers; Draw(dest) - halo, letters, embers |
| Menu.Embers | Embers: an outline from alpha (an ink texel with air next to it, the normal along the slope), one spark per 200 outline texels, flight along the normal with rise and friction, orange -> red, seed "Fire" |
| Menu | The main menu: the sky setup (the CoverSource nebula, stars, globe, logo), a state machine of screens (main/levels/credits/exit), difficulty by a click in place + cells, flags, the zoom into a submenu (Depth 0..1, smoothstep, zooms by planes), the full screen toggle |
| Sdl2.Image | SDL2_image bindings: PNG for all art, delayed-load; without the DLL the game does not start (EnsureImageLib) |
| Sprites.Sets | The .mset container: 'MSET' + version + a JSON table of contents + PNGs in a row; TSpriteSet reads a picture at an offset, frame sequences in place of .mns; shared by the game, the packer and the editor |
| Localization | Dictionaries `lang\<id>.json` (en, ru): keys as constants, Tr(), LoadLanguage checks the full key list at startup; TLocalizedText for level and monster texts |
| Render.Font | TMoonFont: a 16x16-cell atlas, glyph = CP1251 - 1, DrawSmall/DrawBig/DrawScaled, the atlas orientation and filter |
| Audio | SDL2_mixer (delayed-load): TSoundBank - one-shots strict, music soft, PlayMusic, ToggleMusicMuted; for scenes (3.0.62) held sounds PlayHeld/StopHeld/PauseHeld/ResumeHeld and SetMusicLevel - the music's share of volume; 3.0.74 HandOverMusic/Tick; 3.0.75 PlayLooped (a held loop), Plays (this track is playing), FadeOutMusic (into silence) |
| Game.Version | GameVersion - the one place of the version (menu corner, window title) |
| Levels.Tint | "tint": [r, g, b] in percent - one reader (ReadTint, TColorTint) for backdrops, objects and dynamics |
| Levels.FarPlane | The chase's far plane as data (3.0.88): the level's farPlane section and the layout next to it (bin/chase-backdrop.json) - the sun, speeds, layers with a band and elements, four motions (ridge, city, tunnel, ground); the sun's tint by domes (SunCover), the band's shade by the tunnel's leaving (BandShade); since 3.0.89 the fangs (`fangs`, their own motion fmFangs, FangTint); since 3.0.90 the city camera (`camera`) - depth by the feet (DepthY, Nearness, ElementLeft), the dome frames (`frames`), their sun tint, the sun's colour ColorAt; since 3.0.92 the city's life - `cityLights` (TCityLights), `emblem` (TCityEmblem), `beacons` (TCityBeacons), `beaconsAbove` of a frame, an element's `paint` (TElementPaint), rejections of broken data (CheckCityLife); since 3.0.93 the train - `train` (TCityTrain), CityElements, fails without two stations |
| Levels.Monorail | Where the chase city's train stands (3.0.93), no SDL: the line at the stations' depth (MonorailLine - mouths, stops inside the stations), a run with acceleration and braking (TrainRun), the place by the clock with a fraction (TrainLeft, the stops - the dice of Levels.CityLife), the share between mouths (TrainShown). The reference is the bench tools/chase |
| Levels.CityLife | The clock of the chase city's lights (3.0.92), no SDL: the bench's dice to the bit (Mix - lowbias32, Roll, RollInt, LightSeed, BeaconSeed), the levels of a sign (NeonLevel), windows (WindowLevel), emblem parts (EmblemCycle, EmblemPartLevel), a beacon (BeaconLevel). The reference is the bench tools/chase |
| Render.Objects | Static level objects: art of any shape between the backdrop and the tiles, a cache with no key with a linear filter, the set `<assetsDir>-objects` plus objectSets |
| Render.FarPlane | Draws the chase's far plane in place of the screen's backdrop (3.0.88): a black sky, the sun as two glows and a disc, layers as geometry - alpha and colour in the vertices (feathering, shade, mirror); behind a layer whose backdrop covers the screen it draws nothing; since 3.0.90 the city's buildings by depth (ElementLeft), the frames around them: the shadows and the far half before the buildings, the near half and the glint after; since 3.0.92 Draw takes the clock tick, after each visible city building DrawLife - paint, lights (gsPoint, gsBeam), the emblem on the spire; the frames' beacons with their halves; since 3.0.93 the train (DrawTrain) at the line's depth, its picture and lights clipped at the stations' mouths (TScreenSpan, GlowWithin) |
| Render.DomeFrames | The chase city's dome frames (3.0.90): TDomeFrames - geometry without SDL (the geodesic once per frequency, projection by the city camera, far and near halves from far to near, the edge toward the sun, the shadows - since 3.0.91 strokes to the eye, softening over the sun's disc), TDomeFramePainter - triangle strips without a texture, colour and alpha in the vertices, edges fade within a window pixel, the shadows as a mesh with clipping, the glint as two glows. The reference is the bench tools/chase; since 3.0.92 beacons on the nodes above a share of the height (TFrameBeacon, FarBeacons/NearBeacons), the seed by the node's place |
| Levels.Dynamics | The dynamics section of a level: TDynamicObject and all kinds in one unit - TBeacon (beacon), TSmoke (smoke), TSparks (sparks), TSkyGlobe (celestial body), TFan (fan), THaze (haze), TLightning (lightning), TGraph (graph), since 3.0.62 TCraft (a craft of parts: does not move itself, its TAxisMotion axes are driven by a scene, parts by tag follow a mark) and TBeam (a beam, looks scan and tractor), since 3.0.65 TDust (depth dust: TDustBand strips roll and sway, seen only in the light of the TDustLight field - the beam from the hole, the floor's glow, the background; additive, the sky layer; since 3.0.67 runs on its own clock at the tempo pace - a scene stops it), since 3.0.67 TEclipse (the black glow of the moon stone: look void - a dark disc and a soft cold halo, look wave - a dark ring running as intensity rises; the back layer); since 3.0.67 every kind has the clock tempo pace (PaceTo, PaceTagged); ease back - with an overshoot; place, parent by tag (object, pad, monster, craft), layer backdrop/sky/aloft/back/front, the turns flag, intensity under events; ParseDynamics. Does not look for the parent |
| Levels.Scenes | The scenes section of a level (3.0.62; since 3.0.67 the steps pace and fly with ease, since 3.0.68 the step jolt - a one-off shove): a scene is a screen, once (level / life), steps on a tick scale (at, or after + delay; wait until deckEmpty - the steps after it count from it; Plan and sorting by it), aftermath - the end state at once; ParseLevelScenes. Model and parser, no logic |
| Scenes.Director | TSceneDirector (3.0.62) - plays scenes on the live game one at a time: Start by an event (since 3.0.69 a scene started in the middle of another takes over on the next tick - TakeOver; ReArm first rewinds, then sets aftermath), Tick - steps by plan and waits, the end when everything has played; leaving the screen midway - Finish (its own things at once + aftermath), a death midway - rewind to the start, after the end - aftermath on any death, a scene once per life is rewound. Hands by tag on the field, Wake/FlyTo of pads, crafts and beams, held sounds, the shade (DrawShade), the tremor (Trauma), shoves (TakeJolt, 3.0.68 - the game takes them once a tick), music volume. Born with the level |
| Render.Dynamics | TDynamicScreenRenderer: tick and drawing of the dynamics by layers; where an object stands (a screen, a span of screens, a static parent, a pad or a monster by tag through the LocateParent callback, a craft by reference, a child drawn from its CornerAt between ticks); a point with turns rides with the disc (OriginOf), Reseat on a restart; the game's solid probe (TDynamicWorld) reaches objects only on the hero's screen (SolidInView) |
| Render.Puff | Smoke puffs in code: 4 shapes, white with the shape in alpha, normal blending, not additive; DrawPuff, DrawPuffRect (a puff into a rectangle, no rotation - the shroud's strips) |
| Effects.Emitter | TParticleSwarm - a swarm of particles with no look: place, speed, spin, life, friction and thrust; the owner spawns and draws them itself (smoke, for now) |
| Effects.Sparks | The base sparks module: TSparkField - a field of sparks of one look (TSparkLook): flight, cooling, meeting a wall (past / dies / bounce at a cost of life), forks at the end of flight; solid through the TSolidProbe probe, the stroke texture comes with the drawing; pure decoration. Clients: the blast, TSparks, Game.Impacts |
| Effects.Debris | What a blast throws: shards (fly, ring off walls, settle, cool, melt away) and sparks (an Effects.Sparks field); solid through the TSolidProbe probe; pure decoration |
| Game.Explosions | TExplosions - the blast look by size (explosion in monsters.json): flash, fireball, shards, smoke plume, after-pops at the boss; Detonate. Look only: the wave wounds, Game.Blasts |
| Game.Impacts | TImpacts - what a bullet knocks out of armour (material: metal): a flash, a fan of sparks along the ricochet, now and then a tracer; under heavy fire - thinner. TraceEntry / FaceFromCenter - the hit point and normal. Look only: damage, knockback and sound - in the dpr (SpendBullet, SoundArmorHit) |

## Key constants of the coordinate system
- Logic: 512x384 game units (SetMaxC of the original), a cell 32,
  hero/monster 32
- Tile ART 64x64 px (top-left crop), drawn into a 32-unit cell
- Y is the line of the FEET; bullet/contact hitboxes go DOWN from Y
  (y..y+32); bodies are drawn UP (y-32..y)
  THE MAIN TRAP OF THE PORT: the junior code of 2008 has TWO versions of
  every oracle (hero/monster) with different signs (the hero probes the
  floor at y-3, the monster at y+3). Do not reuse!
- HD art off the 32 grid: backdrops and objects 1440 px per 512 units,
  the boss's disc layers 144 px per 36-unit square (4 px per unit), the
  disc's centre is the middle of the sprite (X + 16, Y - 16)

## Deliberate deviations from 2008
1. RoundHalfUp for animation frames (banker's rounding limped in the
   original too)
2. A corpse obeys gravity + a one-time landing (in the original it hung
   in the air)
3. Crosshair: DX=9 DY=10 - calibrated by a player on the live screen
   (NumPad tuner)
4. Healing up to 10 (original 15), by agreement
5. Teleports drop the hero (SetY->haFall) - no standing on air
6. Death respawns at the checkpoint of the current screen, the world is
   reborn (2008: death = menu; the checkpoint served only the pits) -
   part 5.1 (`PORT-JOURNAL.md`)
7. The menu item column is 17 again, as in 2008 (3.0.3): the deviation
   to 15 of 2026-07-21 held only for DIFFICULTY:NORMAL, and the grade is
   now shown in cells, not a word. The screen title left column 24 /
   row 1 for the left edge of the item column, vertically to the middle
   of the flags
8. Screen shake on blasts and henshin (an author's novelty of 2026, not
   in the original) - session 2026-09-26 in `mechanics/engine.md`.
   Purely visual: not one 2008 formula touched
9. Health HUD: a heart monitor in primitives in place of the round icons
   heroes\health.bmp (2.5.0). Norm 5 on every difficulty, hard/wild
   start wounded by empty outlines; a bonus above 5 - light-green cells
   past the divider. Since 3.0.0 the round icons are gone entirely (in
   2.5.x the 2008 mode brought them back)
10. The text lanes moved down: the running line 40, the ticker 52 (were
    24/36) - the monitor is taller than the icons. Since 3.0.8 lane 40
    holds the terminal frame, there is no running line (item 17)
11. Points HUD: the bonus charge in primitives in place of "Score: N"
    (2.5.2), plus the kill streak shown next to it as a row of 10 cells.
    Since 3.0.0 "Score: N" is gone entirely
12. The bonus payment moved from the drop to the activation (2.5.2): the
    score holds at 50+ while the reward waits, minus 50 on the right
    button; the next reward drops at once if >= 50 remains. The final
    arithmetic is the same, only the number on screen differs
13. The logo caption: "Computer Dragon 2008-2026" (2008 is the verbatim
    line2; "2DGames Software 2008 - 2026" lived until 3.0.3) - the
    author's signature, the author's decision. The credits rewritten to
    the same line: "Computer Dragon presents", the authors as in 2008,
    plus "Released in 2008, remade in 2026"; the 2DGames.ru portal left
    (the line did not fit anyway: 42 big glyphs = 562 units)
14. Health rows over the hero and monsters (2.5.3): a novelty of the
    remake, like the heart monitor; since 3.0.0 always shown. Purely
    visual, not one formula touched; the crosshair's thirds moved into
    TMonster.HealthTier with no change to the numbers
15. Difficulty in the menu (3.0.3): a click on the item cycles the grade
    in place, the 2008 submenu (three lines + back) is gone; the grade is
    shown by three health cells next to the caption, the name and
    `diffHintLive` ("С рестарта или нового уровня", en "On restart or
    next level") in a small line under the menu while the cursor is on
    the item. The value is as it was; since 3.0.9 saved in the player's
    settings.json, not in config.json
16. The menu sky (3.0.3): in place of sky.bmp 512x512 + fullmoon.bmp +
    10 star sprites - a 16:9 nebula cropped to the frame, the stars and
    the moon in code (Menu.Starfield, Menu.Globe). The moon's diagonal
    drift is verbatim 2008, the moon itself is a globe. The logo without
    a painted glow: the halo and the embers are computed from its alpha
    (Menu.Logo, Menu.Embers). Entering a submenu is a zoom: the planes
    grow from the centre by 4/8/14/20% over 0.8 s, and back the same way.
    Purely visual
17. The comms terminal in place of the running line (3.0.8): hintText is
    typed letter by letter in a frame under the monitor and holds for
    reading instead of crawling from right to left; the ticker moves
    down under the frame. The text before a level is typed the same way
    on a backing over the sky (2008 showed it as a finished block), the
    first key finishes the typing, the second starts the level. The
    hints of two level1 screens moved: TEK-R1 to screen 16, before the
    door; the medlab waited for two tanks (hintHoldWhileAlive; dropped in
    3.0.10, see 18)
18. Level events from JSON (3.0.10): the events section in level*.json -
    screen, condition (enterScreen, allDead by placement tag), delay in
    ticks, action list (bigMessage, smallMessage, hint, music).
    Levels.Events - model and parser (Core, the editor will write them),
    Events.Director - the executor (Game/Events). The medlab hint is the
    first event: four labGuard (two tanks, a betoner over the hole, a
    gravel female) dead - a second later the text is typed. Since
    3.0.14-3.0.16 the vocabulary is wider: conditions livesBelow and
    enraged, actions intensity and sun
19. The level 1 boss is a disc of HD layers in place of eight spin
    frames (3.0.19): code spins the rim (9 degrees a tick against about
    13.3 in the 2008 frames, twice as fast in rage), drawn between ticks,
    the eye follows the hero, wear shows through as lives are lost, two
    lamps on the disc. The death frames are as before. The look itself
    is purely visual; items 20 and 21 touch the mechanics
20. The top of the boss's route - the turn at y < 96 in place of y < 64
    (3.0.19): at 64 it went under the HUD plates. The top of the flight
    rectangle a cell lower, the bottom as before; the lap shorter by 22
    ticks (432 in place of 454), by 12 in rage
21. The boss's bullets leave from the disc's rim (3.0.19): from a point
    15 units from the middle toward the hero, not from (X + 8, Y + 8).
    The angle is as before, verbatim - from the boss's X, Y to the
    hero's X, Y, so the line of fire goes through the middle of the
    hero's hitbox, not along its left edge: the boss got more accurate
22. Manoeuvres of the level 1 boss (3.0.21, fixes 3.0.22): the lap as
    before, but from the smoke on (below 150 lives) the boss leaves it
    now and then - a ponder in place with volleys from the disc's ports,
    then a dive by cells after the hero; in rage - a ram in a straight
    line at the hero's place, a hit on the wall, a stun and a prize for
    the dodge; below 30 lives it does not return to the lap and does not
    ponder. In a manoeuvre the aimed gun fires half as often, and in the
    ponder, the aim, the dash and the stun it is silent; a bullet does
    not knock the body back; after a manoeuvre the lap is flown the
    other way. Without manoeuvres (tactic laps) the motion is the same as
    before the pilot, tick for tick
23. Grid decks on level 1 (3.0.60): 17 wall cells of 2008 - the
    balconies of screens 14 and 15, the beam of screen 3, the ledge of
    screen 4 - became decks ('2'): they hold only from above, are
    passable from below and from the sides, one can drop off them by
    S/down. Bullets hit them as a wall
24. The suit's burst (3.0.61): in 2008 the world did not stop for a
    single tick of the ceremony; now it stands for the two ticks of the
    inhale - monsters, their bullets and guns freeze, the hero does not.
    The burst's rays wound monsters (a life per burst) and put out
    bullets - damage 2008 did not have at that moment. The suit, the +3
    heal, the shake and the caption come two ticks later
25. Screen 9 of the first level (3.0.62): the house lowered to the
    ledge's level and moved 3 cells toward the right edge, the pit is 6
    cells, the 2008 tank removed from the file - the cordon scene brings
    it; the bridge over the pit is a pad that flies in with the scene.
    The betoner in the pit holds its fire while alive and burns in the
    beam with no points and no streak. The medkit next to it removed

## Debug (under {$DEFINE DEBUGKEYS} in Moon2D.inc; the Release configuration drops the define itself)
PgUp/PgDn - screens, End - straight to the screen under construction
(level 2, screen 10), with the music the road there would have brought,
T - the inspector of the tile under the cursor, F - the raw font atlas,
N - cycle the font filter, P - the tiles of every screen of the level as
pictures in `dump\<level id>\` (sources for repainting).
Orbs and henshin: G - the protective aura on the hero, H - a fire rain
on the hero's screen, J - henshin at once (no boss, no countdown), K -
taking the suit off: the ring of orbs and its mercy (no suit needed), L
- the suit's burst on the hero (no rite and no suit: the look, the
world's freeze, the hits), U - the same burst in the moon's look. Pads:
R - rebuild the group of pads on the hero's screen at once, Y - return
it to its places from the level file. NumPad 4/6/8/2 and +/- - the
minigun muzzle tuner, NumPad 7/9/3/1 - the crosshair tuner (calibrated,
kept in reserve), in the menu V/B - trailer frames (the logo / the bare
sky); in the game M - all music on/off (sounds stay; for shooting the
trailer under an overlay of one's own track). Implementation:
Mix_VolumeMusic(0/128) - the mixer channel is muted, under the hood the
game keeps changing tracks by triggers, unmuting brings back the
screen's current track with no bookkeeping. Music volume is global
mixer state, it survives Halt/Load/Play.

## Strategy, roadmap, tools

Moved out of this file on 2026-11-07:
- the order of steps after 3.0, the debt of version 3.0, the boundary of
  the 3.0 release, the version lines, the phases - `ROADMAP.md`;
- the wide frame, the hero and the monsters from video, the editor with
  an assistant, level 3, the train, big rooms, the hero's forms, Selene
  in the menu, wad - `plans/<name>.md`, a file per plan;
- the journal of the 2.x port (its heading "Следующая часть" - the next
  part; parts 2-7 and the bugfix queue) - `PORT-JOURNAL.md`.

## Open questions of the original
- weapon4 / "Оружие 4" - the fire rate decided by the author (6, part
  5.2 in `PORT-JOURNAL.md`); the other stats are cloned from weapon3,
  check against the release monst.pas
- The tail of the .moon manifest: "4" + boss2.ogg x2 - probably a
  backdrop counter + the boss music
- DeathType 2-3 (brutal deaths, frames 17-32) - only 16 rows in the
  .mns, groundwork
