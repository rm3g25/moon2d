{
  Render.Shake - screen shake as one trauma meter for the whole game,
  read back as a draw offset per layer. Draw-side only: the world's
  arithmetic never sees the offset.

  Every blast pours into the same meter and the meter cools on its own,
  so a chain of barrels stacks without a queue. Amplitude is trauma
  SQUARED - a lone barrel barely nudges, a pile of them or a boss reaches
  the ceiling. The hero and the monsters ride the world's jolt with a
  little jitter of their own, so the figures look loose, not glued.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Render.Shake;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core;

type
  TShakeChannel = (scWorld, scHero, scMonsters);

  TScreenShake = class
  private
    FTrauma: Single;
    FSeed: Cardinal;
    FOffsets: array [TShakeChannel] of TSdlPoint;
    // Own xorshift stream, not Random: that one feeds the boss spawn
    // table, and a shake must not reshuffle what falls from the sky
    function NextUnit: Single;
    function Jitter(AAmplitude: Single): Integer;
  public
    constructor Create;

    // Not a clamp: each blast fills a share of the room LEFT, so a chain
    // of barrels climbs toward the ceiling without ever hitting it
    procedure AddTrauma(AAmount: Single);
    // Once per logic tick - the decay is per call, not per second
    procedure Tick;
    function Offset(AChannel: TShakeChannel): TSdlPoint;
  end;

const
  NoShake: TSdlPoint = (X: 0; Y: 0);

implementation

const
  // Game units at full trauma - two window pixels each at 1024x768
  MaxShakeOffset = 8;
  TraumaDecayPerTick = 0.03; // about one full meter per second at 33 Hz
  // The hero's and the monsters' own jitter, as a share of the world's.
  // Larger and the hero visibly detaches from the platform under him
  FigureJitterRatio = 0.25;
  XorshiftSeed = $2545F491; // anything but zero - xorshift never leaves zero

constructor TScreenShake.Create;
begin
  inherited Create;
  FSeed := XorshiftSeed;
end;

procedure TScreenShake.AddTrauma(AAmount: Single);
begin
  FTrauma := FTrauma + AAmount * (1 - FTrauma);
end;

function TScreenShake.NextUnit: Single;
begin
  FSeed := FSeed xor (FSeed shl 13);
  FSeed := FSeed xor (FSeed shr 17);
  FSeed := FSeed xor (FSeed shl 5);
  Result := FSeed / High(Cardinal);
end;

// A fresh roll in [-AAmplitude, AAmplitude] every tick: a jolt, not a
// glide - smoothing it would turn the shake into a sway
function TScreenShake.Jitter(AAmplitude: Single): Integer;
begin
  Result := Round(AAmplitude * (2 * NextUnit - 1));
end;

procedure TScreenShake.Tick;
begin
  FTrauma := FTrauma - TraumaDecayPerTick;
  if FTrauma < 0 then
    FTrauma := 0;

  var Amplitude := Sqr(FTrauma) * MaxShakeOffset;
  var World: TSdlPoint;
  World.X := Jitter(Amplitude);
  World.Y := Jitter(Amplitude);
  FOffsets[scWorld] := World;

  var FigureAmplitude := Amplitude * FigureJitterRatio;
  FOffsets[scHero].X := World.X + Jitter(FigureAmplitude);
  FOffsets[scHero].Y := World.Y + Jitter(FigureAmplitude);
  FOffsets[scMonsters].X := World.X + Jitter(FigureAmplitude);
  FOffsets[scMonsters].Y := World.Y + Jitter(FigureAmplitude);
end;

function TScreenShake.Offset(AChannel: TShakeChannel): TSdlPoint;
begin
  Result := FOffsets[AChannel];
end;

end.
