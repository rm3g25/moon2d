{
  Game.Henshin - the transformation ceremony: the 3..2..1 prelude, the
  rite of orbs about the hero, the suit going on, and the suit coming
  off. The countdown and the rite (Orbs.Rite) are of 2026: the ceremony
  of 2008 was five rings of bullets closing in on the hero and a fan.

  The rite leads the orbs and tells what has come to pass; the ceremony
  listens and does the game's side of it: the shout, a point of health
  as each wave sits, the mercy from the pause on, the light that fills
  the body as the orbs go in, the suit as the last of them does. It has
  no clock of its own.

  The ceremony acts on the stage it is given - the hero, the sound bank,
  the message board, the shake meter, the shroud, the rite - and asks
  the game for what it does not own, through its calls. The game ticks
  it every logic tick, right after the rite, even over the hero's
  corpse; a restart resets it.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Henshin;
{$I ..\Moon2D.inc}

interface

uses
  Hero, Audio, Hud.Messages, Render.Shake, Render.Font, Game.Shroud,
  Orbs.Rite;

const
  // bottle.wav is the barrel burst that doubles as the henshin flash,
  // the shatter of the suit, the bonus explosion and the pops of a
  // wreck - the game reads the name from here for its own blasts
  BottleSoundFile = 'bottle.wav';

type
  // +1 health for the hero, owned by the game
  TCureHero = reference to procedure;
  // Mercy for the hero for ATicks, owned by the game
  TGrantMercy = reference to procedure(ATicks: Integer);
  // The rite begins about the hero, owned by the game: it knows his
  // center, the matter of his screen and the level's pattern
  TBeginRite = reference to procedure;

  // What the ceremony acts on
  THenshinStage = record
    Hero: THero;
    Audio: TSoundBank;
    Messages: TMessageBoard;
    Shake: TScreenShake;
    Shroud: THeroShroud;
    Rite: TOrbRite;
  end;

  // What the ceremony asks the game for: methods of the game passed
  // directly, no wrappers
  THenshinCalls = record
    Cure: TCureHero;
    GrantMercy: TGrantMercy;
    BeginRite: TBeginRite;
  end;

  THenshin = class
  private
    FHero: THero;
    FAudio: TSoundBank;
    FMessages: TMessageBoard;
    FShake: TScreenShake;
    FShroud: THeroShroud;
    FRite: TOrbRite;
    FCalls: THenshinCalls;
    // The 3..2..1 prelude; 0 = idle
    FCountdownDigit: Integer;
    FCountdownTick: Integer;
    procedure TickCountdown;
    procedure HearRite;
    procedure Finish;
  public
    constructor Create(const AStage: THenshinStage;
      const ACalls: THenshinCalls);

    // The prelude, then the ceremony: the boss path
    procedure StartCountdown;
    // The ceremony straight away: the gravel trial of level 2
    procedure Start;
    // Once per logic tick, after the rite's own: the prelude, then what
    // the rite has told since the last one
    procedure Tick;
    // The digit of the prelude, topmost on the display
    procedure DrawCountdown(const AFont: TMoonFont; AAlpha: Double);
    // The suit shatters with a fan; nothing if the hero is not wearing it
    procedure RemoveIceForm;
    // A fresh boss means a fresh ceremony: the countdown and the ice
    // form die with the hero - the suit comes off silently. The rite is
    // the game's to clear.
    procedure Reset;
  end;

implementation

uses
  System.SysUtils, System.Math, Bullets, Localization, Game.Space;

const
  HenshinSoundFile = 'evolution.wav'; // the transformation sting (878/966)
  // Synthesized tick for the countdown - see PORTING-NOTES for why this
  // one is code-generated instead of downloaded
  CountdownBeepFile = 'countdown.wav';

  RegenTicks = 100; // 'регенерировала здоровье +1' (457 et al.)
  PerkTicks = 300;  // 'ICE FORM: прыжок +25%' (501)

  // The screen-shake dose of the suit going on (2026 addition), a trauma
  // share - see Render.Shake for the meter
  FinishTrauma = 0.7;

  // Pre-henshin countdown (author's 2026 addition, not in the original):
  // 3..2..1 in screen center telegraphs the ceremony - one second of
  // logic per digit, three seconds to pick the ground: the orbs fly to
  // the hero from every wall and wound what stands in their way
  CountdownStartValue = 3;
  CountdownTicksPerDigit = 33;      // = one second at tickRate 33
  CountdownFadeStartRatio = 0.6;    // opaque for 60%, dissolves over 40%
  CountdownMinGlyphHeight = 24.0;   // birth size, game units
  CountdownMaxGlyphHeight = 132.0;  // size at the moment it dies
  CountdownCenterY = 168.0;         // above true center: clears hero/HUD

constructor THenshin.Create(const AStage: THenshinStage;
  const ACalls: THenshinCalls);
begin
  inherited Create;
  FHero := AStage.Hero;
  FAudio := AStage.Audio;
  FMessages := AStage.Messages;
  FShake := AStage.Shake;
  FShroud := AStage.Shroud;
  FRite := AStage.Rite;
  FCalls := ACalls;
  // Strict loads: a bad name blows up here, not mid-boss
  FAudio.Load(HenshinSoundFile);
  FAudio.Load(CountdownBeepFile);
  FAudio.Load(BottleSoundFile);
end;

procedure THenshin.Reset;
begin
  FCountdownDigit := 0;
  FCountdownTick := 0;
  FHero.HeroForm := hfNormal;
end;

// ---------------------------------------------------------------------------
// COUNTDOWN - the 3..2..1 prelude. Each digit is born small in screen
// center, grows for its whole second of life and dissolves near the
// peak; when the last one dies, the ceremony starts.
// ---------------------------------------------------------------------------

procedure THenshin.StartCountdown;
begin
  FCountdownDigit := CountdownStartValue;
  FCountdownTick := 0;
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
    Start // EVOLUTION shout replaces the tick
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
// CEREMONY - the shout, what the rite tells, the suit
// ---------------------------------------------------------------------------

procedure THenshin.Start;
begin
  FMessages.ShowBig(Tr(SEvolution), BigMessageTicks);
  // The sting fires twice back to back (878-879 / 966-967) - a poor
  // man's volume boost, kept verbatim
  FAudio.Play(HenshinSoundFile);
  FAudio.Play(HenshinSoundFile);
  FCalls.BeginRite();
end;

procedure THenshin.Tick;
begin
  TickCountdown;
  HearRite;
end;

// The body fills with light as the orbs go in: the look of the suit with
// no frost and no motes, its light climbing all through the rite's
// collapse. It tops out a tick past the collapse, so the suit's look
// takes the light over at its top, with no dip between.
function ChargeLook: TShroudLook;
const
  TopAt = 0.9; // the share of the look's life its top falls on
begin
  Result := IceOnLook;
  Result.Bands := 0;
  Result.Motes := 0;
  Result.FlashAt := TopAt;
  Result.Life := Ceil((IceRiteScore.CollapseTicks + 1) / TopAt);
end;

procedure THenshin.HearRite;
begin
  var Event := FRite.DrainEvent;
  while Event <> reNone do
  begin
    case Event of
      reWaveSeated:
        begin
          FCalls.Cure();
          FMessages.AddTicker(Tr(SIceRegen), RegenTicks);
        end;
      rePaused:
        // To the suit: while the orbs hover and while they draw in
        FCalls.GrantMercy(IceRiteScore.HoverTicks +
          IceRiteScore.CollapseTicks);
      reCollapsing:
        FShroud.Start(ChargeLook);
      reFinished:
        Finish;
    end;
    Event := FRite.DrainEvent;
  end;
end;

procedure THenshin.Finish;
const
  // With the point of each wave that sat, the six of the 2008 ceremony
  Cures = 3;
begin
  FMessages.AddTicker(Tr(SIceFormPerk), PerkTicks);
  for var i := 1 to Cures do
    FCalls.Cure();
  FHero.HeroForm := hfIce;
  FShroud.Start(IceOnLook);
  FAudio.Play(BottleSoundFile);
  FShake.AddTrauma(FinishTrauma);
  FMessages.ShowBig(Tr(SIceForm), BigMessageTicks);
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
  FShroud.Start(IceOffLook);
end;

end.
