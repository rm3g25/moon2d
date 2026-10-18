{
  Scenes.Director - plays the level's scenes (Levels.Scenes) against the
  live game: one at a time, cue by cue on its timeline, while the player
  keeps the controls.

  An event starts a scene (Events.Director); the director runs its clock
  from there. It moves the crafts among the level's dynamic objects,
  turns their parts, aims their beams and points their lightning, lights
  and puts out what the cues name, plays the scene's sounds and keeps
  hold of them, prints its lines on the terminal, sets the volume of the
  level's music, and keeps two values the game reads every tick: the
  shade over the world and the rumble of the ground. A part told to
  follow, and a beam or lightning aimed at a mark, are told where the
  mark is every tick until the scene ends or sends them elsewhere.

  It acts on the world too: it holds the fire of monsters, kills them,
  brings new ones and takes them away, wakes the pads the level keeps
  asleep and flies them. The field is reborn on every restart, so it
  arrives with every tick in the stage, as the hero's place does; the
  pads are the level's, as the director is.

  A cue may wait for another to play, and a wait for the world: for the
  deck of a pad to carry no live monster. The hero does not hold a pad
  up - he rides it where it goes. The scene is over once every cue has
  played and run its ticks.

  A scene the hero leaves its screen in the middle of ends at once: every
  cue of its own things lands where it would have, the sounds it still
  holds stop, no line is printed; the world it acts on is put as its
  aftermath says. A death on its screen in the middle of it takes it back
  to its start instead - what its cues set going goes back to the level
  file, the world is reborn anyway - and it waits for its event again:
  the player sees it from the beginning. Played to the end, a scene
  played once a level stays played: every death after it puts its
  aftermath again, whatever screen the hero dies on, over the monsters
  reborn and the pads rewound. One played once a life is rewound by a
  death on its screen and waits for its event again.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Scenes.Director;
{$I ..\..\Moon2D.inc}

interface

uses
  Sdl2.Core, Levels.Scenes, Levels.Dynamics, Audio, Hud.Messages, Monsters,
  Bullets, Pads.World;

type
  // What a scene acts on that it does not own, as of this tick
  TSceneStage = record
    Hero: TSdlFPoint; // the middle of the hero, screen units
    Field: TMonsterField;
    Bullets: TBurst; // the monsters'
  end;

  TSceneDirector = class
  private
    FScenes: TArray<TLevelScene>;
    FDynamics: TDynamicObjects;
    FPads: TPadWorld;
    FAudio: TSoundBank;
    FMessages: TMessageBoard;
    FPlayed: TArray<Boolean>; // in step with FScenes
    FActive: Integer; // the scene under way; -1 - none
    FTick: Integer; // of the scene under way
    // The tick each cue of the scene under way played at; NotPlayed yet
    FPlayedAt: TArray<Integer>;
    FHeld: TArray<THeldSound>;
    // The track and aim cues whose marks are followed now
    FPursuits: TArray<TSceneCue>;
    FShade: TValueFade; // 0..1
    FRumble: TValueFade; // 0..1
    FMusic: TValueFade; // 0..1 of the music's volume
    function IndexOf(const AId: string): Integer;
    function Due(const AScene: TLevelScene; AIndex: Integer;
      const AStage: TSceneStage): Boolean;
    function Holds(const ACue: TSceneCue; const AStage: TSceneStage): Boolean;
    function DeckEmpty(const APadTag: string; const AStage: TSceneStage): Boolean;
    function Over(const AScene: TLevelScene): Boolean;
    procedure PlayDue(const AScene: TLevelScene; const AStage: TSceneStage);
    procedure Play(const ACue: TSceneCue; AAtOnce: Boolean; AScreen: Integer;
      const AStage: TSceneStage);
    procedure MoveCrafts(const ACue: TSceneCue; ATicks: Integer);
    procedure Track(const ACue: TSceneCue; const AStage: TSceneStage);
    procedure Aim(const ACue: TSceneCue; ATicks: Integer;
      const AStage: TSceneStage);
    procedure Pursue(const ACue: TSceneCue);
    procedure FollowMarks(const AStage: TSceneStage);
    procedure Tell(const ACue: TSceneCue; const APoint: TSdlFPoint);
    procedure Speak(const ACue: TSceneCue);
    procedure Spawn(const ACue: TSceneCue; AScreen: Integer;
      const AStage: TSceneStage);
    procedure FlyPad(const ACue: TSceneCue; ATicks: Integer);
    procedure Settle(const AScene: TLevelScene; const AStage: TSceneStage);
    procedure RewindTargets(const AScene: TLevelScene);
    procedure StopHeld;
    procedure Finish(const AStage: TSceneStage);
    procedure Rewind(AIndex: Integer);
  public
    // The level owns the dynamic objects and must outlive the director,
    // and the pads, the sound bank and the message board must too
    constructor Create(const AScenes: TArray<TLevelScene>;
      const ADynamics: TDynamicObjects; const APads: TPadWorld;
      const AAudio: TSoundBank; const AMessages: TMessageBoard);
    destructor Destroy; override;
    // The scene AId begins, unless one is under way or it has played
    procedure Start(const AId: string);
    // One logic tick with the hero on AScreen
    procedure Tick(AScreen: Integer; const AStage: TSceneStage);
    // Death re-enters AScreen with the monsters reborn and the pads
    // rewound: a scene under way there and its scenes of a life are
    // rewound, every other scene played once a level puts its aftermath
    procedure ReArm(AScreen: Integer; const AStage: TSceneStage);
    // The game leaves for the menu and comes back: the held sounds wait
    // with the timeline, the music plays at full volume under the menu
    procedure Pause;
    procedure Resume;
    // What the rumble adds to the screen's trauma this tick
    function Trauma: Single;
    // The shade over the world: over all of it, under the marks over the
    // figures and the HUD
    procedure DrawShade(ARenderer: PSdlRenderer);
  end;

implementation

uses
  Render.Sprites, Hud.Terminal;

const
  // Trauma a tick at the full rumble: the shake settles where the decay
  // of Render.Shake takes back what this adds, about a unit each way
  RumbleTraumaPerTick = 0.05;
  // Under this the shade is not drawn at all
  ShadeVisible = 1 / 255;
  WholeFrame: PSdlFRect = nil;
  NotPlayed = -1;
  NoScene = -1;

constructor TSceneDirector.Create(const AScenes: TArray<TLevelScene>;
  const ADynamics: TDynamicObjects; const APads: TPadWorld;
  const AAudio: TSoundBank; const AMessages: TMessageBoard);
begin
  inherited Create;
  FScenes := AScenes;
  FDynamics := ADynamics;
  FPads := APads;
  FAudio := AAudio;
  FMessages := AMessages;
  SetLength(FPlayed, Length(FScenes));
  FActive := NoScene;
  FMusic.Settle(1);
end;

// The level goes with the director: nothing of its scene outlives it
destructor TSceneDirector.Destroy;
begin
  StopHeld;
  if FActive >= 0 then
    FAudio.SetMusicLevel(1);
  inherited;
end;

function TSceneDirector.IndexOf(const AId: string): Integer;
begin
  for var i := 0 to High(FScenes) do
    if FScenes[i].Id = AId then
      Exit(i);
  Result := NoScene;
end;

procedure TSceneDirector.Start(const AId: string);
begin
  if FActive >= 0 then
    Exit;
  var Index := IndexOf(AId);
  if (Index < 0) or FPlayed[Index] then
    Exit;
  FActive := Index;
  FPlayed[Index] := True;
  FTick := 0;
  SetLength(FPlayedAt, Length(FScenes[Index].Cues));
  for var i := 0 to High(FPlayedAt) do
    FPlayedAt[i] := NotPlayed;
  FHeld := nil;
  FPursuits := nil;
  FShade.Settle(0);
  FRumble.Settle(0);
  FMusic.Settle(1);
end;

procedure TSceneDirector.MoveCrafts(const ACue: TSceneCue; ATicks: Integer);
begin
  for var DynamicObject in FDynamics do
  begin
    if (DynamicObject.Placement.Tag <> ACue.Target) or
      not (DynamicObject is TCraft) then
      Continue;
    var Craft := TCraft(DynamicObject);
    if ACue.MovesX then
      Craft.MoveX(ACue.X, ATicks, ACue.Ease);
    if ACue.MovesY then
      Craft.MoveY(ACue.Y, ATicks, ACue.Ease);
  end;
end;

// Where the mark of ACue stands now: the middle of the hero, of the body
// carrying the tag, dead or alive, or the point itself. False when no
// body carries the tag - what follows it keeps to where it last was.
function MarkOf(const ACue: TSceneCue; const AStage: TSceneStage;
  out APoint: TSdlFPoint): Boolean;
begin
  case ACue.Mark of
    smHero:
      begin
        APoint := AStage.Hero;
        Exit(True);
      end;
    smPoint:
      begin
        APoint.X := ACue.X;
        APoint.Y := ACue.Y;
        Exit(True);
      end;
    smNothing:
      Exit(False);
  end;
  var Body := AStage.Field.FirstTagged(ACue.MarkTag);
  if Body = nil then
    Exit(False);
  var Box := Body.HitBox;
  APoint.X := Box.X + Box.W / 2;
  APoint.Y := Box.Y + Box.H / 2;
  Result := True;
end;

// The parts the cue names, or its beam, learn where the mark is
procedure TSceneDirector.Tell(const ACue: TSceneCue; const APoint: TSdlFPoint);
begin
  for var DynamicObject in FDynamics do
  begin
    if DynamicObject.Placement.Tag <> ACue.Target then
      Continue;
    if (ACue.Kind = ckTrack) and (DynamicObject is TCraft) then
      TCraft(DynamicObject).Watch(ACue.Part, APoint)
    else if (ACue.Kind = ckAim) and (DynamicObject is TBeam) then
      TBeam(DynamicObject).Follow(APoint)
    else if (ACue.Kind = ckAim) and (DynamicObject is TLightning) then
      TLightning(DynamicObject).PointAt(APoint);
  end;
end;

// A later cue for the same parts or the same beam takes the place of the
// earlier one; a track on nothing ends the pursuit
procedure TSceneDirector.Pursue(const ACue: TSceneCue);
begin
  for var i := High(FPursuits) downto 0 do
  begin
    var Same := (FPursuits[i].Kind = ACue.Kind) and
      (FPursuits[i].Target = ACue.Target) and (FPursuits[i].Part = ACue.Part);
    if Same then
      Delete(FPursuits, i, 1);
  end;
  if ACue.Mark <> smNothing then
    FPursuits := FPursuits + [ACue];
end;

procedure TSceneDirector.Track(const ACue: TSceneCue;
  const AStage: TSceneStage);
var
  Point: TSdlFPoint;
begin
  Pursue(ACue);
  if ACue.Mark = smNothing then
  begin
    for var DynamicObject in FDynamics do
      if (DynamicObject.Placement.Tag = ACue.Target) and
        (DynamicObject is TCraft) then
        TCraft(DynamicObject).Unwatch(ACue.Part);
    Exit;
  end;
  if MarkOf(ACue, AStage, Point) then
    Tell(ACue, Point);
end;

procedure TSceneDirector.Aim(const ACue: TSceneCue; ATicks: Integer;
  const AStage: TSceneStage);
var
  Point: TSdlFPoint;
begin
  Pursue(ACue);
  if not MarkOf(ACue, AStage, Point) then
    Exit;
  for var DynamicObject in FDynamics do
  begin
    if DynamicObject.Placement.Tag <> ACue.Target then
      Continue;
    if DynamicObject is TBeam then
      TBeam(DynamicObject).AimAt(Point, ATicks, ACue.Ease)
    else if DynamicObject is TLightning then
      TLightning(DynamicObject).PointAt(Point);
  end;
end;

procedure TSceneDirector.FollowMarks(const AStage: TSceneStage);
var
  Point: TSdlFPoint;
begin
  for var Pursuit in FPursuits do
    if MarkOf(Pursuit, AStage, Point) then
      Tell(Pursuit, Point);
end;

procedure TSceneDirector.Speak(const ACue: TSceneCue);
begin
  var Place := tlTop;
  if ACue.AtBottom then
    Place := tlBottom;
  FMessages.StartTerminal(ACue.Header.Current, ACue.Text.Current, Place);
end;

// A body the tag already names is not born twice: alive, it stands where
// the cue says; dead, it lies where it fell
procedure TSceneDirector.Spawn(const ACue: TSceneCue; AScreen: Integer;
  const AStage: TSceneStage);
begin
  var X: Double := ACue.X;
  var Y: Double := ACue.Y;
  if ACue.Seat <> '' then
  begin
    var Pad := FPads.FindTagged(ACue.Seat);
    X := Pad.Left + Pad.Placement.Width / 2 - SpriteSize / 2;
    Y := Pad.Top;
  end;
  var Body := AStage.Field.FirstTagged(ACue.Target);
  if Body = nil then
    Body := AStage.Field.SpawnStanding(ACue.Monster, ACue.SpriteList, AScreen,
      X, Y, ACue.Target, ACue.FacesRight)
  else if Body.Life = mlAlive then
    Body.Stand(X, Y, ACue.FacesRight)
  else
    Exit;
  Body.Dormant := ACue.Asleep;
end;

procedure TSceneDirector.FlyPad(const ACue: TSceneCue; ATicks: Integer);
begin
  var Pad := FPads.FindTagged(ACue.Target);
  if Pad <> nil then
    Pad.FlyTo(ACue.X, ACue.Y, ATicks);
end;

// AAtOnce lands the cue where it would have ended, and plays no sound and
// prints no line: the scene is being cut short, or its aftermath put
procedure TSceneDirector.Play(const ACue: TSceneCue; AAtOnce: Boolean;
  AScreen: Integer; const AStage: TSceneStage);
begin
  var Ticks := ACue.Ticks;
  if AAtOnce then
    Ticks := 0;
  case ACue.Kind of
    ckSound:
      if not AAtOnce then
        FHeld := FHeld + [FAudio.PlayHeld(ACue.FileName)];
    ckMusic:
      FMusic.HeadFor(ACue.Level, Ticks);
    ckShade:
      FShade.HeadFor(ACue.Level, Ticks);
    ckShake:
      FRumble.HeadFor(ACue.Level, Ticks);
    ckMove:
      MoveCrafts(ACue, Ticks);
    ckTrack:
      Track(ACue, AStage);
    ckAim:
      Aim(ACue, Ticks, AStage);
    ckIntensity:
      FDynamics.FadeTagged(ACue.Target, ACue.Level, Ticks);
    ckHint:
      if not AAtOnce then
        Speak(ACue);
    ckHold:
      AStage.Field.HoldTagged(ACue.Target, True);
    ckKill:
      AStage.Field.SmiteTagged(ACue.Target, AStage.Bullets);
    ckSpawn:
      Spawn(ACue, AScreen, AStage);
    ckRelease:
      AStage.Field.ReleaseTagged(ACue.Target);
    ckRemove:
      AStage.Field.RemoveTagged(ACue.Target);
    ckWake:
      begin
        var Pad := FPads.FindTagged(ACue.Target);
        if Pad <> nil then
          Pad.Wake;
      end;
    ckFly:
      FlyPad(ACue, Ticks);
  end;
end;

// No live body stands on the deck; a corpse rides along, and so does the
// hero
function TSceneDirector.DeckEmpty(const APadTag: string;
  const AStage: TSceneStage): Boolean;
begin
  var Pad := FPads.FindTagged(APadTag);
  if Pad = nil then
    Exit(True);
  for var Monster in AStage.Field.Monsters do
    if (Monster.Life = mlAlive) and (Monster.DeckUnderFeet = Pad) then
      Exit(False);
  Result := True;
end;

function TSceneDirector.Holds(const ACue: TSceneCue;
  const AStage: TSceneStage): Boolean;
begin
  case ACue.Waits of
    swDeckEmpty:
      Result := DeckEmpty(ACue.Target, AStage);
  else
    Result := True;
  end;
end;

// Its tick has come - counted from the start, or from the cue it plays
// after - and a wait finds its condition holding
function TSceneDirector.Due(const AScene: TLevelScene; AIndex: Integer;
  const AStage: TSceneStage): Boolean;
begin
  var Cue := AScene.Cues[AIndex];
  var From := Cue.At;
  if Cue.After >= 0 then
  begin
    var CountedFrom := FPlayedAt[Cue.After];
    if CountedFrom = NotPlayed then
      Exit(False);
    From := CountedFrom + Cue.Delay;
  end;
  if FTick < From then
    Exit(False);
  Result := (Cue.Kind <> ckWait) or Holds(Cue, AStage);
end;

// In the order of the plan: a cue that plays after another stands
// behind it, so a chain with no delay plays out on one tick
procedure TSceneDirector.PlayDue(const AScene: TLevelScene;
  const AStage: TSceneStage);
begin
  for var i := 0 to High(AScene.Cues) do
  begin
    if (FPlayedAt[i] <> NotPlayed) or not Due(AScene, i, AStage) then
      Continue;
    Play(AScene.Cues[i], False, AScene.Screen, AStage);
    FPlayedAt[i] := FTick;
  end;
end;

function TSceneDirector.Over(const AScene: TLevelScene): Boolean;
begin
  for var i := 0 to High(AScene.Cues) do
  begin
    if FPlayedAt[i] = NotPlayed then
      Exit(False);
    if FPlayedAt[i] + AScene.Cues[i].Ticks >= FTick then
      Exit(False);
  end;
  Result := True;
end;

procedure TSceneDirector.StopHeld;
begin
  for var Sound in FHeld do
    FAudio.StopHeld(Sound);
  FHeld := nil;
end;

procedure TSceneDirector.Settle(const AScene: TLevelScene;
  const AStage: TSceneStage);
begin
  for var Cue in AScene.Aftermath do
    Play(Cue, True, AScene.Screen, AStage);
end;

// Every cue of the scene's own things in order, at once: a later one
// overrides an earlier one as it would have on the timeline. The world
// is the aftermath's: replayed at once, a pad would leave before what it
// carries got off.
procedure TSceneDirector.Finish(const AStage: TSceneStage);
begin
  if FActive < 0 then
    Exit;
  var Scene := FScenes[FActive];
  for var Cue in Scene.Cues do
    if not (Cue.Kind in SceneWorldCues) then
      Play(Cue, True, Scene.Screen, AStage);
  Settle(Scene, AStage);
  StopHeld;
  FPursuits := nil;
  FAudio.SetMusicLevel(FMusic.Current);
  FActive := NoScene;
end;

procedure TSceneDirector.Tick(AScreen: Integer; const AStage: TSceneStage);
begin
  if FActive < 0 then
    Exit;
  var Scene := FScenes[FActive];
  if Scene.Screen <> AScreen then
  begin
    Finish(AStage);
    Exit;
  end;

  PlayDue(Scene, AStage);
  FollowMarks(AStage);
  FShade.Tick;
  FRumble.Tick;
  FMusic.Tick;
  FAudio.SetMusicLevel(FMusic.Current);

  Inc(FTick);
  // Done: the sounds play out their tails on their own
  if Over(Scene) then
  begin
    FHeld := nil;
    FPursuits := nil;
    FActive := NoScene;
  end;
end;

// What the scene's cues set going goes back to the level file
procedure TSceneDirector.RewindTargets(const AScene: TLevelScene);
begin
  for var Cue in AScene.Cues do
    if Cue.Kind in [ckMove, ckTrack, ckAim, ckIntensity] then
      FDynamics.RewindTagged(Cue.Target);
end;

// Back to before its event: nothing of it is left playing or lit, the
// music at full volume until the scene fades it again
procedure TSceneDirector.Rewind(AIndex: Integer);
begin
  if AIndex = FActive then
  begin
    StopHeld;
    FPursuits := nil;
    FActive := NoScene;
  end;
  FPlayed[AIndex] := False;
  RewindTargets(FScenes[AIndex]);
  FShade.Settle(0);
  FRumble.Settle(0);
  FMusic.Settle(1);
  FAudio.SetMusicLevel(1);
end;

procedure TSceneDirector.ReArm(AScreen: Integer; const AStage: TSceneStage);
begin
  if (FActive >= 0) and (FScenes[FActive].Screen <> AScreen) then
    Finish(AStage);
  for var i := 0 to High(FScenes) do
  begin
    var OnScreen := FScenes[i].Screen = AScreen;
    var OfLife := FScenes[i].Once = soLife;
    var LifeHere := OfLife and OnScreen;
    var Replays := (i = FActive) or LifeHere;
    if Replays then
      Rewind(i)
    else if FPlayed[i] and not OfLife then
      Settle(FScenes[i], AStage);
  end;
end;

procedure TSceneDirector.Pause;
begin
  if FActive < 0 then
    Exit;
  for var Sound in FHeld do
    FAudio.PauseHeld(Sound);
  FAudio.SetMusicLevel(1);
end;

procedure TSceneDirector.Resume;
begin
  if FActive < 0 then
    Exit;
  for var Sound in FHeld do
    FAudio.ResumeHeld(Sound);
  FAudio.SetMusicLevel(FMusic.Current);
end;

function TSceneDirector.Trauma: Single;
begin
  Result := FRumble.Current * RumbleTraumaPerTick;
end;

procedure TSceneDirector.DrawShade(ARenderer: PSdlRenderer);
begin
  if FShade.Current < ShadeVisible then
    Exit;
  SDL_SetRenderDrawBlendMode(ARenderer, SdlBlendModeBlend);
  SDL_SetRenderDrawColor(ARenderer, 0, 0, 0, Round(255 * FShade.Current));
  SDL_RenderFillRectF(ARenderer, WholeFrame);
end;

end.
