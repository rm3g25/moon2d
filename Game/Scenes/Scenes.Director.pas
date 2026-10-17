{
  Scenes.Director - plays the level's scenes (Levels.Scenes) against the
  live game: one at a time, cue by cue on its timeline, while the player
  keeps the controls.

  An event starts a scene (Events.Director); the director runs its clock
  from there. It moves the crafts among the level's dynamic objects,
  plays the scene's sounds and keeps hold of them, sets the volume of the
  level's music, and keeps two values the game reads every tick: the
  shade over the world and the rumble of the ground.

  A scene cut short - the hero gone from its screen, or dead on it -
  ends at once: every cue lands where it would have, the sounds it still
  holds stop. A scene played once a level stays played; one played once
  a life is rewound by a death and waits for its event again.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Scenes.Director;
{$I ..\..\Moon2D.inc}

interface

uses
  Sdl2.Core, Levels.Scenes, Levels.Dynamics, Audio;

type
  TSceneDirector = class
  private
    FScenes: TArray<TLevelScene>;
    FDynamics: TDynamicObjects;
    FAudio: TSoundBank;
    FPlayed: TArray<Boolean>; // in step with FScenes
    FActive: Integer; // the scene under way; -1 - none
    FTick: Integer; // of the scene under way
    FNextCue: Integer;
    FHeld: TArray<THeldSound>;
    FShade: TValueFade; // 0..1
    FRumble: TValueFade; // 0..1
    FMusic: TValueFade; // 0..1 of the music's volume
    function IndexOf(const AId: string): Integer;
    procedure Play(const ACue: TSceneCue; AAtOnce: Boolean);
    procedure MoveCrafts(const ACue: TSceneCue; ATicks: Integer);
    procedure RewindCrafts(const AScene: TLevelScene);
    procedure StopHeld;
    procedure Finish;
  public
    // The level owns the dynamic objects and must outlive the director,
    // and the sound bank must too
    constructor Create(const AScenes: TArray<TLevelScene>;
      const ADynamics: TDynamicObjects; const AAudio: TSoundBank);
    destructor Destroy; override;
    // The scene AId begins, unless one is under way or it has played
    procedure Start(const AId: string);
    // One logic tick with the hero on AScreen
    procedure Tick(AScreen: Integer);
    // Death re-enters AScreen: a scene under way there ends at once, and
    // its scenes of a life are rewound
    procedure ReArm(AScreen: Integer);
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

const
  // Trauma a tick at the full rumble: the shake settles where the decay
  // of Render.Shake takes back what this adds, about a unit each way
  RumbleTraumaPerTick = 0.05;
  // Under this the shade is not drawn at all
  ShadeVisible = 1 / 255;
  WholeFrame: PSdlFRect = nil;

constructor TSceneDirector.Create(const AScenes: TArray<TLevelScene>;
  const ADynamics: TDynamicObjects; const AAudio: TSoundBank);
begin
  inherited Create;
  FScenes := AScenes;
  FDynamics := ADynamics;
  FAudio := AAudio;
  SetLength(FPlayed, Length(FScenes));
  FActive := -1;
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
  Result := -1;
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
  FNextCue := 0;
  FHeld := nil;
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

// AAtOnce lands the cue where it would have ended, and plays no sound:
// the scene is being cut short
procedure TSceneDirector.Play(const ACue: TSceneCue; AAtOnce: Boolean);
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
  end;
end;

procedure TSceneDirector.StopHeld;
begin
  for var Sound in FHeld do
    FAudio.StopHeld(Sound);
  FHeld := nil;
end;

// Every cue in order, at once: a later one overrides an earlier one as
// it would have on the timeline
procedure TSceneDirector.Finish;
begin
  if FActive < 0 then
    Exit;
  for var Cue in FScenes[FActive].Cues do
    Play(Cue, True);
  StopHeld;
  FAudio.SetMusicLevel(FMusic.Current);
  FActive := -1;
end;

procedure TSceneDirector.Tick(AScreen: Integer);
begin
  if FActive < 0 then
    Exit;
  var Scene := FScenes[FActive];
  if Scene.Screen <> AScreen then
  begin
    Finish;
    Exit;
  end;

  while (FNextCue < Length(Scene.Cues)) and
    (Scene.Cues[FNextCue].At <= FTick) do
  begin
    Play(Scene.Cues[FNextCue], False);
    Inc(FNextCue);
  end;
  FShade.Tick;
  FRumble.Tick;
  FMusic.Tick;
  FAudio.SetMusicLevel(FMusic.Current);

  Inc(FTick);
  // Done: the sounds play out their tails on their own
  if FTick > Scene.EndTick then
  begin
    FHeld := nil;
    FActive := -1;
  end;
end;

procedure TSceneDirector.RewindCrafts(const AScene: TLevelScene);
begin
  for var Cue in AScene.Cues do
    if Cue.Kind = ckMove then
      FDynamics.RewindTagged(Cue.Target);
end;

procedure TSceneDirector.ReArm(AScreen: Integer);
begin
  if (FActive >= 0) and (FScenes[FActive].Screen = AScreen) then
    Finish;
  for var i := 0 to High(FScenes) do
  begin
    if (FScenes[i].Screen <> AScreen) or (FScenes[i].Once <> soLife) then
      Continue;
    FPlayed[i] := False;
    RewindCrafts(FScenes[i]);
    FShade.Settle(0);
    FRumble.Settle(0);
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
