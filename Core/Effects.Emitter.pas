{
  Effects.Emitter - a swarm of particles: each born with a place, a
  speed, a spin and a life, carried by drag and a steady pull, aged
  tick by tick and let go when its life runs out.

  The swarm knows nothing of looks: the owner spawns the particles,
  stirs them if it wants and draws them its own way. They are kept in
  order of birth, so drawing them in order puts the newest on top.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Effects.Emitter;
{$I ..\Moon2D.inc}

interface

type
  TParticle = record
    X, Y: Single; // units, in the owner's frame
    SpeedX, SpeedY: Single; // units per tick
    Angle: Single; // degrees
    Spin: Single; // degrees per tick
    Age, Life: Integer; // ticks
    Shape: Integer; // which of the owner's pictures
    Scale: Single; // the owner's size factor for this one
    Weight: Single; // the owner's density factor for this one
  end;
  PParticle = ^TParticle;

  TParticleSwarm = class
  private
    FParticles: TArray<TParticle>;
    FCount: Integer;
    function GetParticle(AIndex: Integer): PParticle;
  public
    procedure Add(const AParticle: TParticle);
    // One tick of flight: move, keep ADrag of the speed, add the pull
    // (units per tick per tick), age, and drop the particles whose life
    // is over
    procedure Advance(ADrag, APullX, APullY: Single);
    // The owner's frame moved by (ADX, ADY); what is already in flight
    // stays where it is on the screen
    procedure ShiftFrame(ADX, ADY: Single);
    procedure Clear;
    property Count: Integer read FCount;
    property Particles[AIndex: Integer]: PParticle read GetParticle; default;
  end;

implementation

const
  InitialCapacity = 32;

procedure TParticleSwarm.Add(const AParticle: TParticle);
begin
  if FCount = Length(FParticles) then
  begin
    var Capacity := 2 * Length(FParticles);
    if Capacity < InitialCapacity then
      Capacity := InitialCapacity;
    SetLength(FParticles, Capacity);
  end;
  FParticles[FCount] := AParticle;
  Inc(FCount);
end;

procedure TParticleSwarm.Advance(ADrag, APullX, APullY: Single);
begin
  var Kept := 0;
  for var i := 0 to FCount - 1 do
  begin
    var Particle := FParticles[i];
    Inc(Particle.Age);
    if Particle.Age >= Particle.Life then
      Continue;
    Particle.X := Particle.X + Particle.SpeedX;
    Particle.Y := Particle.Y + Particle.SpeedY;
    Particle.SpeedX := Particle.SpeedX * ADrag + APullX;
    Particle.SpeedY := Particle.SpeedY * ADrag + APullY;
    Particle.Angle := Particle.Angle + Particle.Spin;
    FParticles[Kept] := Particle;
    Inc(Kept);
  end;
  FCount := Kept;
end;

procedure TParticleSwarm.ShiftFrame(ADX, ADY: Single);
begin
  for var i := 0 to FCount - 1 do
  begin
    FParticles[i].X := FParticles[i].X - ADX;
    FParticles[i].Y := FParticles[i].Y - ADY;
  end;
end;

procedure TParticleSwarm.Clear;
begin
  FCount := 0;
end;

function TParticleSwarm.GetParticle(AIndex: Integer): PParticle;
begin
  Result := @FParticles[AIndex];
end;

end.
