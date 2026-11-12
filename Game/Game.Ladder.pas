{
  Game.Ladder - the ladder of the Ram's air fight: which rung the fight is
  on, and whose the turn is between the magnet's cycles.

  The rung follows the share of the hull's lives spent, so every grade
  climbs the same ladder: the magnet alone; the bombs and the lift; the
  charge; the dive. On the last rung's last stretch the finisher joins
  them - the charge right through the screen and the dive out of the sky
  after it.

  After each of the magnet's windows one of the rung's weapons has a turn:
  the rung's newest the first time it is due, so it is seen alone; then
  one of them at random, never the one that had the last turn - with one
  weapon on the rung that one every time, with two they go by turns.

  On the last rung, once the dive has been seen alone, a cycle of the
  magnet may chain two threats as the magnet catches its barge: the dive
  the moment the barge is thrown, or a shell at his feet while it holds a
  shield - never in a lift. A chain is that cycle's turn: no weapon comes
  after its window, and it counts as the dive's or the mortar's for the
  rule of no repeats. None on the finisher's stretch till the finisher
  has been seen.

  The door of a rung is where a death past it comes back to: the hull's
  lives at that door. Point C is the door of the charge's rung.

  It knows no hull, no magnet and no barges: the caller asks at the
  window's end and at the catch, and carries the answer out. No SDL.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Ladder;
{$I ..\Moon2D.inc}

interface

uses
  Render.Brush;

const
  // The share of the hull's lives spent from which each rung holds: the
  // bombs and the lift come with the second, the charge with the third,
  // the dive with the fourth
  AirTierSpent: array [2..4] of Single = (0.15, 0.33, 0.6);
  AirTopTier = 4;
  BombsFromTier = 2;
  LiftFromTier = 2;
  ChargeFromTier = 3;
  DiveFromTier = 4;
  // The last rung's last stretch, the finisher's
  FinisherSpent = 0.85;
  // Point C: a death past this rung's door brings the hull's lives back
  // only to the door
  AirDoorTier = 3;
  // Shells a turn of the mortar: two where it is learned alone, one where
  // it is mixed with the others; one under the magnet's shield
  MortarShells: array [1..AirTopTier] of Integer = (0, 2, 1, 1);
  ShieldShells = 1;
  // On the last rung a cycle of the magnet chains this often
  ChainShare = 0.5;

type
  // Whose the turn after the magnet's window: atFinisher - the charge
  // through the screen and the dive from above after it
  TAirTurn = (atNone, atMortar, atCharge, atDive, atFinisher);
  TAirTurns = set of TAirTurn;

  // A cycle of the magnet that chains: acThrowDive - the dive the moment
  // the barge is thrown, its window lost; acShieldShells - a shell at his
  // feet while it holds its shield
  TAirChain = (acNone, acThrowDive, acShieldShells);

  TAirLadder = class
  private
    FDice: TXorShift;
    FLastTurn: TAirTurn;
    FSeen: TAirTurns;
    // One of AItems, as the dice fall
    function Pick<T>(const AItems: TArray<T>): T;
    procedure Take(ATurn: TAirTurn);
  public
    // ASeed - the dice of the choice
    constructor Create(ASeed: Cardinal);
    // A death, a new fight: nothing seen, no turn yet; the dice go on
    procedure Clear;
    // The magnet's window is over, ASpent of the hull's lives spent: whose
    // turn it is - atNone on the first rung
    function NextTurn(ASpent: Single): TAirTurn;
    // The magnet catches a barge, ASpent of the hull's lives spent; ALift -
    // with him aboard: whether this cycle chains, and how
    function ChainAt(ASpent: Single; ALift: Boolean): TAirChain;
    property LastTurn: TAirTurn read FLastTurn;
  end;

// The rung, 1 to AirTopTier, ASpent of the hull's lives spent
function AirTierOf(ASpent: Single): Integer;
// On the last rung's last stretch, the finisher's
function OnFinisherStretch(ASpent: Single): Boolean;
// The weapons that take turns there, the oldest first: none on the first
// rung
function AirTurnsOf(ASpent: Single): TArray<TAirTurn>;
// The hull's lives at the door of point C, of AFullLives: on its rung,
// not a life more
function AirDoorLives(AFullLives: Integer): Integer;

implementation

uses
  System.Math;

function AirTierOf(ASpent: Single): Integer;
begin
  Result := 1;
  for var i := Low(AirTierSpent) to High(AirTierSpent) do
    if ASpent >= AirTierSpent[i] then
      Result := i;
end;

function OnFinisherStretch(ASpent: Single): Boolean;
begin
  Result := ASpent >= FinisherSpent;
end;

function AirTurnsOf(ASpent: Single): TArray<TAirTurn>;
begin
  Result := nil;
  var Tier := AirTierOf(ASpent);
  if Tier >= BombsFromTier then
    Insert(atMortar, Result, Length(Result));
  if Tier >= ChargeFromTier then
    Insert(atCharge, Result, Length(Result));
  if Tier >= DiveFromTier then
    Insert(atDive, Result, Length(Result));
  if OnFinisherStretch(ASpent) then
    Insert(atFinisher, Result, Length(Result));
end;

function AirDoorLives(AFullLives: Integer): Integer;
begin
  // The door's share is a Single, a hair off its decimal either way: from
  // a life over the rounded count, down to the first count on the rung, the
  // most lives the rung has
  Result := Min(Round(AFullLives * (1 - AirTierSpent[AirDoorTier])) + 1, AFullLives);
  while (Result > 0) and (AirTierOf(1 - Result / AFullLives) < AirDoorTier) do
    Dec(Result);
end;

constructor TAirLadder.Create(ASeed: Cardinal);
begin
  inherited Create;
  // An xorshift seeded with zero stays at zero
  FDice.Seed := ASeed or 1;
  Clear;
end;

procedure TAirLadder.Clear;
begin
  FLastTurn := atNone;
  FSeen := [];
end;

function TAirLadder.Pick<T>(const AItems: TArray<T>): T;
begin
  Result := AItems[Min(Trunc(FDice.NextUnit * Length(AItems)), High(AItems))];
end;

procedure TAirLadder.Take(ATurn: TAirTurn);
begin
  Include(FSeen, ATurn);
  FLastTurn := ATurn;
end;

function TAirLadder.NextTurn(ASpent: Single): TAirTurn;
begin
  var Turns := AirTurnsOf(ASpent);
  if Length(Turns) = 0 then
    Exit(atNone);
  var Newest := Turns[High(Turns)];
  if not (Newest in FSeen) then
    Result := Newest
  else
  begin
    var Others: TArray<TAirTurn> := nil;
    for var Turn in Turns do
      if Turn <> FLastTurn then
        Insert(Turn, Others, Length(Others));
    if Length(Others) = 0 then
      Result := Turns[0]
    else
      Result := Pick<TAirTurn>(Others);
  end;
  Take(Result);
end;

function TAirLadder.ChainAt(ASpent: Single; ALift: Boolean): TAirChain;
begin
  if (AirTierOf(ASpent) < DiveFromTier) or not (atDive in FSeen) then
    Exit(acNone);
  var FinisherDue := OnFinisherStretch(ASpent) and not (atFinisher in FSeen);
  if FinisherDue then
    Exit(acNone);
  if FDice.NextUnit >= ChainShare then
    Exit(acNone);
  var Chains: TArray<TAirChain> := nil;
  if FLastTurn <> atDive then
    Insert(acThrowDive, Chains, Length(Chains));
  if not ALift and (FLastTurn <> atMortar) then
    Insert(acShieldShells, Chains, Length(Chains));
  if Length(Chains) = 0 then
    Exit(acNone);
  Result := Pick<TAirChain>(Chains);
  if Result = acThrowDive then
    Take(atDive)
  else
    Take(atMortar);
end;

end.
