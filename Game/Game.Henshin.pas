{
  Game.Henshin - the transformation ceremony: the 3..2..1 prelude, the
  rite of orbs about the hero, the burst of the suit, and the suit coming
  off. The countdown, the rite (Orbs.Rite) and the burst (Orbs.Burst) are
  of 2026: the ceremony of 2008 was five rings of bullets closing in on
  the hero and a fan.

  The rite leads the orbs and tells what has come to pass; the ceremony
  listens and does the game's side of it: the shout, a point of health
  as each wave sits, the mercy from the pause on, the light that fills
  the body as the orbs go in. As the last of them does, the game is asked
  for the burst: the suit takes what light it holds, and the rest goes
  out of the hero. The burst inhales, then strikes and says so - and the
  suit is on with the strike. The ceremony has no clock of its own.

  The suit comes off the way it went on, in orbs: the game is asked to
  have the rite give them back, they come out of the body into a ring
  about the hero, and the mercy lasts as long as the ring does. The fan of
  bullets the suit shattered into in 2008 is gone.

  The ceremony acts on the stage it is given - the hero, the sound bank,
  the message board, the shake meter, the shroud, the rite, the burst -
  and asks the game for what it does not own, through its calls. The game
  ticks it every logic tick, right after the rite and the burst, even over
  the hero's corpse; a restart resets it.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Henshin;
{$I ..\Moon2D.inc}

interface

uses
  Hero, Audio, Hud.Messages, Render.Shake, Render.Font, Game.Shroud,
  Orbs.Rite, Orbs.Burst;

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
  // The rite begins about the hero, owned by his orbs (Game.HeroOrbs): it
  // knows his center, the matter of his screen and the level's pattern
  TBeginRite = reference to procedure;
  // The suit's orbs come out about the hero, owned by his orbs
  TShedSuit = reference to procedure;
  // The burst of the suit begins about the hero, owned by his orbs: it
  // knows his center, the matter of his screen and the level's pattern
  TBurstSuit = reference to procedure;

  // What the ceremony acts on
  THenshinStage = record
    Hero: THero;
    Audio: TSoundBank;
    Messages: TMessageBoard;
    Shake: TScreenShake;
    Shroud: THeroShroud;
    Rite: TOrbRite;
    Burst: TOrbBurst;
  end;

  // What the ceremony asks the game and the hero's orbs for: their methods
  // passed directly, no wrappers
  THenshinCalls = record
    Cure: TCureHero;
    GrantMercy: TGrantMercy;
    BeginRite: TBeginRite;
    ShedSuit: TShedSuit;
    Burst: TBurstSuit;
  end;

  THenshin = class
  private
    FHero: THero;
    FAudio: TSoundBank;
    FMessages: TMessageBoard;
    FShake: TScreenShake;
    FShroud: THeroShroud;
    FRite: TOrbRite;
    FBurst: TOrbBurst;
    FCalls: THenshinCalls;
    // The 3..2..1 prelude; 0 = idle
    FCountdownDigit: Integer;
    FCountdownTick: Integer;
    // The ceremony has asked for the burst and waits for its strike: a
    // burst it did not ask for puts no suit on
    FBursting: Boolean;
    procedure TickCountdown;
    procedure HearRite;
    procedure HearBurst;
    procedure Finish;
  public
    constructor Create(const AStage: THenshinStage;
      const ACalls: THenshinCalls);

    // The prelude, then the ceremony: the boss path
    procedure StartCountdown;
    // The ceremony straight away: the gravel trial of level 2
    procedure Start;
    // Once per logic tick, after the rite's and the burst's own: the
    // prelude, then what the rite and the burst have told since the last
    // one
    procedure Tick;
    // The digit of the prelude, topmost on the display
    procedure DrawCountdown(const AFont: TMoonFont; AAlpha: Double);
    // The suit comes off as a ring of orbs and the hero is spared as long
    // as it stands; nothing if he is not wearing it
    procedure RemoveIceForm;
    // A fresh boss means a fresh ceremony: the countdown and the ice
    // form die with the hero - the suit comes off silently. The rite is
    // the game's to clear.
    procedure Reset;
  end;

implementation

uses
  System.SysUtils, System.Math, Localization, Game.Space;

const
  HenshinSoundFile = 'evolution.wav'; // the transformation sting (878/966)
  // Synthesized tick for the countdown - see PORTING-NOTES for why this
  // one is code-generated instead of downloaded
  CountdownBeepFile = 'countdown.wav';

  RegenTicks = 100; // 'регенерировала здоровье +1' (457 et al.)
  PerkTicks = 300;  // 'ICE FORM: прыжок +25%' (501)

  // The screen-shake dose of the burst's strike (2026 addition), a trauma
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
  FBurst := AStage.Burst;
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
  FBursting := False;
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
// CEREMONY - the shout, what the rite and the burst tell, the suit
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
  HearBurst;
end;

// The body fills with light as the orbs go in: the look of the suit with
// no frost and no motes, its light climbing all through the rite's
// collapse. It tops out a tick past the collapse; the burst's inhale
// covers the body with a bare figure until the suit's look takes the
// light over at the strike.
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
        // To the strike: while the orbs hover, while they draw in and
        // while the burst inhales
        FCalls.GrantMercy(IceRiteScore.HoverTicks +
          IceRiteScore.CollapseTicks + InhaleTicks);
      reCollapsing:
        FShroud.Start(ChargeLook);
      reFinished:
        begin
          FBursting := True;
          FCalls.Burst();
        end;
    end;
    Event := FRite.DrainEvent;
  end;
end;

procedure THenshin.HearBurst;
begin
  var Event := FBurst.DrainEvent;
  while Event <> beNone do
  begin
    if (Event = beStruck) and FBursting then
      Finish;
    Event := FBurst.DrainEvent;
  end;
end;

// The strike of the burst: the suit is on
procedure THenshin.Finish;
const
  // With the point of each wave that sat, the six of the 2008 ceremony
  Cures = 3;
begin
  FBursting := False;
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
begin
  if FHero.HeroForm = hfNormal then
    Exit;
  FHero.HeroForm := hfNormal;
  FShroud.Start(IceOffLook);
  // The ring stands against what a dying boss throws in this very tick,
  // and the mercy lasts as long as the ring does
  FCalls.ShedSuit();
  FCalls.GrantMercy(IceRiteScore.ShedTicks);
end;

end.
