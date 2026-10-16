{
  Game.Press - the press of the gravel trial's finale: its rules, with no
  pads, no monsters and no SDL in them.

  The press is a stack of rows of shelves, top first - balconies at the
  walls, the bodies of the wave stand on them. The rows that are out ride
  down together like a conveyor: on every beat each row out goes into the
  wall and the row under it comes out, so whoever stood on a row falls one
  row lower. The bottom row going in drops its bodies onto whatever is
  under it. A row whose body is dead rides on all the same: the room keeps
  pressing, whoever stands on it.

  A newcomer comes down onto the top row: its arrival brings the top row
  out, should it be in, and the beat waits while the newcomer is on its
  way - the top row does not go from under a body still in the air.

  Two rows out one over the other: the lower one goes in with the beat, to
  drop its own body, and comes out again a moment later to catch the body
  of the row over it, which falls a row only - before that one gets there.

  The press only counts which rows are out and which are told to move. The
  game tells the shelves.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Press;
{$I ..\Moon2D.inc}

interface

const
  // A beat waits this long after a newcomer is let down onto the top row:
  // the fall from the sky to the top row and a little more
  PressArrivalTicks = 45;
  // A row that goes in on a beat and has to catch the body of the row over
  // it comes out again this long after: its own body has fallen through by
  // then (the shelf's warning and slide), the one from above not yet (that
  // shelf's warning and slide, and a fall of two cells)
  PressRewakeTicks = 40;

type
  // What the shelves are told on a tick: the rows (banks) that go into the
  // wall and those that come out and hold
  TPressCall = record
    Sleep: TArray<string>;
    Wake: TArray<string>;
    function IsEmpty: Boolean;
  end;

  TPress = class
  private
    FRows: TArray<string>;
    FBeatTicks: Integer;
    FActive: Boolean;
    // In step with FRows: the row is out
    FOut: TArray<Boolean>;
    // In step with FRows: ticks until the row comes out again; 0 - it does
    // not
    FRewakeIn: TArray<Integer>;
    FTicksToBeat: Integer;
    FHoldTicks: Integer;
    procedure Beat(var ACall: TPressCall);
    procedure TickRewakes(var ACall: TPressCall);
  public
    // ARows - the banks of the rows, top first; ABeatTicks - the beat. Every
    // row starts in. Nothing for no rows or a beat below a tick.
    procedure Start(const ARows: TArray<string>; ABeatTicks: Integer);
    // The press stops where it stands: no more beats, no rows told
    procedure Shut;
    // A newcomer is let down onto ABank: the top row comes out if it is in,
    // and the beat waits for the newcomer. Nothing for another bank.
    function Arrive(const ABank: string): TPressCall;
    function Tick: TPressCall;
    // The row is out, or told to come out again; False for a bank not in
    // the press
    function RowOut(const ABank: string): Boolean;
    property Active: Boolean read FActive;
    property Rows: TArray<string> read FRows;
  end;

// Seconds of the level file to ticks of the press, a tick at least
function PressBeatTicks(ASeconds: Single): Integer;

implementation

uses
  System.Math;

const
  LogicTicksPerSecond = 33;

function PressBeatTicks(ASeconds: Single): Integer;
begin
  Result := Max(1, Round(ASeconds * LogicTicksPerSecond));
end;

function TPressCall.IsEmpty: Boolean;
begin
  Result := (Length(Sleep) = 0) and (Length(Wake) = 0);
end;

procedure TPress.Start(const ARows: TArray<string>; ABeatTicks: Integer);
begin
  Shut;
  if (Length(ARows) = 0) or (ABeatTicks < 1) then
    Exit;
  FRows := Copy(ARows);
  FBeatTicks := ABeatTicks;
  SetLength(FOut, Length(FRows));
  SetLength(FRewakeIn, Length(FRows));
  for var i := 0 to High(FRows) do
  begin
    FOut[i] := False;
    FRewakeIn[i] := 0;
  end;
  FTicksToBeat := FBeatTicks;
  FHoldTicks := 0;
  FActive := True;
end;

procedure TPress.Shut;
begin
  FActive := False;
  FRows := nil;
  FOut := nil;
  FRewakeIn := nil;
  FHoldTicks := 0;
end;

function TPress.Arrive(const ABank: string): TPressCall;
begin
  Result := Default(TPressCall);
  if not FActive or (ABank <> FRows[0]) then
    Exit;
  FHoldTicks := PressArrivalTicks;
  if FOut[0] then
    Exit;
  FOut[0] := True;
  FRewakeIn[0] := 0;
  Result.Wake := [FRows[0]];
end;

function TPress.RowOut(const ABank: string): Boolean;
begin
  for var i := 0 to High(FRows) do
    if FRows[i] = ABank then
      Exit(FOut[i]);
  Result := False;
end;

// The rows out ride a row down: the bottom one off the press, the top one
// left in. A row out over a row out: the lower goes in and comes out again.
procedure TPress.Beat(var ACall: TPressCall);
begin
  var WasOut := Copy(FOut);
  for var i := 0 to High(FRows) do
  begin
    var Above := (i > 0) and WasOut[i - 1];
    if WasOut[i] then
    begin
      ACall.Sleep := ACall.Sleep + [FRows[i]];
      if Above then
        FRewakeIn[i] := PressRewakeTicks;
      FOut[i] := Above;
    end
    else if Above then
    begin
      ACall.Wake := ACall.Wake + [FRows[i]];
      FOut[i] := True;
    end;
  end;
end;

procedure TPress.TickRewakes(var ACall: TPressCall);
begin
  for var i := 0 to High(FRows) do
  begin
    if FRewakeIn[i] = 0 then
      Continue;
    Dec(FRewakeIn[i]);
    if FRewakeIn[i] = 0 then
      ACall.Wake := ACall.Wake + [FRows[i]];
  end;
end;

// The beat comes due and waits out a newcomer on its way
function TPress.Tick: TPressCall;
begin
  Result := Default(TPressCall);
  if not FActive then
    Exit;
  TickRewakes(Result);
  if FHoldTicks > 0 then
    Dec(FHoldTicks);
  if FTicksToBeat > 0 then
    Dec(FTicksToBeat);
  if (FTicksToBeat > 0) or (FHoldTicks > 0) then
    Exit;
  FTicksToBeat := FBeatTicks;
  Beat(Result);
end;

end.
