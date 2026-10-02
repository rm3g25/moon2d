{
  Game.Henshin - the transformation ceremony: the 3..2..1 prelude, the
  five healing waves closing in on the hero, the suit going on, and the
  suit coming off. 'Henshin'/'HenshinTime' of 2008 plus the 2026
  countdown, lifted out of the game loop as one automaton.

  The ceremony acts on the stage it is given - the hero, the sound bank,
  the message board, the shake meter - and asks the game for the one
  thing it does not own: a point of health, through the cure callback.
  The game ticks it every logic tick, even over the hero's corpse, as
  the 2008 timer did; a restart resets it.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Henshin;
{$I ..\Moon2D.inc}

interface

uses
  Hero, Audio, Hud.Messages, Render.Shake, Render.Font;

const
  // bottle.wav is the barrel burst that doubles as the henshin flash,
  // the shatter of the suit, the bonus explosion and the pops of a
  // wreck - the game reads the name from here for its own blasts
  BottleSoundFile = 'bottle.wav';

type
  // +1 health for the hero, owned by the game (each wave and the finish
  // heal once). A method of the game passed directly, no wrapper.
  TCureHero = reference to procedure;

  THenshin = class
  private
    FHero: THero;
    FAudio: TSoundBank;
    FMessages: TMessageBoard;
    FShake: TScreenShake;
    FCure: TCureHero;
    // The cinematic: a tick counter walks the wave schedule while the
    // game keeps running
    FActive: Boolean;
    FTick: Integer;
    // The 3..2..1 prelude; 0 = idle. Carries the AtTick for the
    // cinematic it hands over to when the last digit dissolves.
    FCountdownDigit: Integer;
    FCountdownTick: Integer;
    FCountdownHenshinAtTick: Integer;
    procedure TickCountdown;
    procedure TickCinematic;
    procedure Finish;
  public
    constructor Create(const AHero: THero; const AAudio: TSoundBank;
      const AMessages: TMessageBoard; const AShake: TScreenShake;
      const ACure: TCureHero);

    // The prelude, then the cinematic from AHenshinAtTick
    procedure StartCountdown(AHenshinAtTick: Integer);
    // The cinematic straight away. AAtTick 0 = the boss path; 30 skips
    // the first wave - the gravel trial of level 2 starts mid-sequence
    procedure Start(AAtTick: Integer);
    // Once per logic tick: the prelude and the cinematic in one breath
    procedure Tick;
    // The digit of the prelude, topmost on the display
    procedure DrawCountdown(const AFont: TMoonFont; AAlpha: Double);
    // The suit shatters with a fan; nothing if the hero is not wearing it
    procedure RemoveIceForm;
    // A fresh boss means a fresh ceremony: the countdown, the cinematic
    // and the ice form die with the hero - the suit comes off silently
    procedure Reset;
  end;

implementation

uses
  System.SysUtils, Bullets, Localization, Game.Space;

type
  // One healing wave of the cinematic
  TWave = record
    AtTick: Integer;
    Bullets: Integer;
    RadiusX: Integer;
  end;

const
  HenshinSoundFile = 'evolution.wav'; // the transformation sting (878/966)
  WaveSoundFile = 'platform.wav';     // the waves ring the platform burst
  // Synthesized tick for the countdown - see PORTING-NOTES for why this
  // one is code-generated instead of downloaded
  CountdownBeepFile = 'countdown.wav';

  RegenTicks = 100; // 'регенерировала здоровье +1' (457 et al.)
  PerkTicks = 300;  // 'ICE FORM: прыжок +25%' (501)

  // The five converging waves of moon.dpr 453-497: the ring tightens
  // (40 -> 5) while the fragment count grows (50 -> 100) - the ice
  // closing in on the hero. Each wave heals +1 and rings platform.wav.
  Waves: array [0..4] of TWave = (
    (AtTick: 20; Bullets: 50; RadiusX: 40),
    (AtTick: 40; Bullets: 60; RadiusX: 30),
    (AtTick: 60; Bullets: 70; RadiusX: 20),
    (AtTick: 80; Bullets: 80; RadiusX: 10),
    (AtTick: 100; Bullets: 100; RadiusX: 5));
  FlashTick = 135;  // bottle.wav teaser before the finale (498)
  FinishTick = 140; // the suit goes on (499-513)

  // Screen-shake doses (2026 addition), in trauma shares - see
  // Render.Shake for the meter
  WaveTrauma = 0.4;   // each of the five rings
  FinishTrauma = 0.7; // the suit-on fan

  // Pre-henshin countdown (author's 2026 addition, not in the original):
  // 3..2..1 in screen center telegraphs the ceremony - one second of
  // logic per digit, three seconds to run INTO the monster crowd (ring
  // fragments are live hero bullets, positioning is a damage buff)
  CountdownStartValue = 3;
  CountdownTicksPerDigit = 33;      // = one second at tickRate 33
  CountdownFadeStartRatio = 0.6;    // opaque for 60%, dissolves over 40%
  CountdownMinGlyphHeight = 24.0;   // birth size, game units
  CountdownMaxGlyphHeight = 132.0;  // size at the moment it dies
  CountdownCenterY = 168.0;         // above true center: clears hero/HUD

constructor THenshin.Create(const AHero: THero; const AAudio: TSoundBank;
  const AMessages: TMessageBoard; const AShake: TScreenShake;
  const ACure: TCureHero);
begin
  inherited Create;
  FHero := AHero;
  FAudio := AAudio;
  FMessages := AMessages;
  FShake := AShake;
  FCure := ACure;
  // Strict loads: a bad name blows up here, not mid-boss
  FAudio.Load(HenshinSoundFile);
  FAudio.Load(WaveSoundFile);
  FAudio.Load(CountdownBeepFile);
  FAudio.Load(BottleSoundFile);
end;

procedure THenshin.Reset;
begin
  FCountdownDigit := 0;
  FCountdownTick := 0;
  FActive := False;
  FTick := 0;
  FHero.HeroForm := hfNormal;
end;

// ---------------------------------------------------------------------------
// COUNTDOWN - the 3..2..1 prelude. Each digit is born small in screen
// center, grows for its whole second of life and dissolves near the
// peak; when the last one dies, the cinematic starts.
// ---------------------------------------------------------------------------

procedure THenshin.StartCountdown(AHenshinAtTick: Integer);
begin
  FCountdownDigit := CountdownStartValue;
  FCountdownTick := 0;
  FCountdownHenshinAtTick := AHenshinAtTick;
  FAudio.Play(CountdownBeepFile); // '3' announces itself too
end;

procedure THenshin.TickCountdown;
begin
  if FCountdownDigit = 0 then
    Exit;
  Inc(FCountdownTick);
  if FCountdownTick < CountdownTicksPerDigit then
    Exit;

  FCountdownTick := 0;
  Dec(FCountdownDigit);
  if FCountdownDigit = 0 then
    Start(FCountdownHenshinAtTick) // EVOLUTION shout replaces the tick
  else
    FAudio.Play(CountdownBeepFile);
end;

procedure THenshin.DrawCountdown(const AFont: TMoonFont; AAlpha: Double);
begin
  if FCountdownDigit = 0 then
    Exit;

  // Fractional progress through the digit's life: logic runs at 33 Hz,
  // rendering at ~164 fps - without the timestep alpha the growth would
  // stutter in 3.3-unit jumps (the marquee lesson of part 2). Stays
  // below 1.0 by construction: the tick resets at the boundary and the
  // timestep alpha never reaches a full tick.
  var Progress := (FCountdownTick + AAlpha) / CountdownTicksPerDigit;
  var GlyphHeight := CountdownMinGlyphHeight +
    (CountdownMaxGlyphHeight - CountdownMinGlyphHeight) * Progress;

  var Opacity := 255;
  if Progress > CountdownFadeStartRatio then
    Opacity := Round(255 * (1 - (Progress - CountdownFadeStartRatio) /
      (1 - CountdownFadeStartRatio)));

  var Digit := IntToStr(FCountdownDigit);
  AFont.DrawScaled(Digit,
    (FrameWidth - AFont.ScaledTextWidth(Digit, GlyphHeight)) / 2,
    CountdownCenterY - GlyphHeight / 2,
    GlyphHeight, Opacity);
end;

// ---------------------------------------------------------------------------
// CINEMATIC - the waves, the flash, the suit
// ---------------------------------------------------------------------------

procedure THenshin.Start(AAtTick: Integer);
begin
  FMessages.ShowBig(Tr(SEvolution), BigMessageTicks);
  // The sting fires twice back to back (878-879 / 966-967) - a poor
  // man's volume boost, kept verbatim
  FAudio.Play(HenshinSoundFile);
  FAudio.Play(HenshinSoundFile);
  FActive := True;
  FTick := AAtTick;
end;

procedure THenshin.Tick;
begin
  TickCountdown;
  TickCinematic;
end;

procedure THenshin.TickCinematic;
begin
  if not FActive then
    Exit;
  Inc(FTick);

  for var Wave in Waves do
    if FTick = Wave.AtTick then
    begin
      FAudio.Play(WaveSoundFile);
      FCure;
      FMessages.AddTicker(Tr(SIceRegen), RegenTicks);
      FHero.Bullets.SpawnConvergingRing(FHero.X, FHero.Y,
        Wave.Bullets, Wave.RadiusX);
      FShake.AddTrauma(WaveTrauma);
    end;

  if FTick = FlashTick then
    FAudio.Play(BottleSoundFile);
  if FTick = FinishTick then
    Finish;
end;

procedure THenshin.Finish;
const
  FinishFan: TFanShape = (Rows: 12; Cols: 42; BaseSpeed: 6; SpeedSpread: 3);
begin
  FMessages.AddTicker(Tr(SIceFormPerk), PerkTicks);
  FCure;
  FHero.HeroForm := hfIce;
  FAudio.Play(BottleSoundFile);
  FHero.Bullets.SpawnFan(FHero.X, FHero.Y, FinishFan);
  FShake.AddTrauma(FinishTrauma);
  FMessages.ShowBig(Tr(SIceForm), BigMessageTicks);
  FActive := False;
  FTick := 0;
end;

procedure THenshin.RemoveIceForm;
const
  ShatterFan: TFanShape = (Rows: 12; Cols: 16; BaseSpeed: 4; SpeedSpread: 3);
begin
  if FHero.HeroForm = hfNormal then
    Exit;
  // Verbatim 940-947: the suit shatters with a fan but NO sound of its
  // own - the victory music covers the moment (2008 played nothing here)
  FHero.HeroForm := hfNormal;
  FHero.Bullets.SpawnFan(FHero.X, FHero.Y, ShatterFan);
end;

end.
