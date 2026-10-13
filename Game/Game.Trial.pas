{
  Game.Trial - the gravel trial of level 2: its rules, with no monster
  field, no hero and no SDL in them.

  The trial runs in acts. An act is a batch of gravels let down a wave at
  a time. The next act does not come until every gravel of the batch is
  dead; then the room takes a short breath and the next batch starts. The
  gate of the last act ends the trial. Every fifteenth gravel killed pays
  one medkit, counted across the acts.

  A gravel fallen into the pit comes back one at a time, a beat apart:
  a crowd dropped at once does not land on the hero at once.

  The first gravel of every act comes as a herald, in a light of its own.
  From the second act on every third gravel of a batch is aimed: the
  light marks the column the hero stands in, and the gravel follows it a
  moment later - time enough to step aside, if he looks up.

  The game tells the trial how many gravels are alive and which of them
  died, and does what the cue of a tick says: lets a gravel down, marks
  the column of an aimed one and lets it down there, brings one gravel
  back from the pit, lets a medkit down, or ends the trial.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Trial;
{$I ..\Moon2D.inc}

interface

const
  TrialActs = 5;
  // The pace of 2008: the first wave this many ticks after the start of
  // the trial, then one every TrialWaveTicks
  TrialFirstWaveTicks = 25;
  TrialWaveTicks = 18;
  // The breath of the room between two acts, before the next batch falls
  TrialActBreakTicks = 40;
  TrialKillsPerMedkit = 15;
  TrialAimedFromAct = 2;
  TrialAimedEvery = 3;
  // The mark of an aimed gravel leads it by this much: shorter than a wave,
  // so no more than one is ever on its way
  TrialAimedLeadTicks = 10;
  TrialPitReturnTicks = 10;

type
  TTrialCue = record
    SpawnGravel: Boolean;
    // The gravel let down is the first of its act
    Herald: Boolean;
    // Mark the hero's column for an aimed gravel; let it down there
    MarkAimed: Boolean;
    SpawnAimed: Boolean;
    // Bring back one gravel fallen into the pit, if one is down there
    ReturnFromPit: Boolean;
    SpawnMedkit: Boolean;
    Finished: Boolean;
  end;

  TGravelTrial = class
  private
    FActive: Boolean;
    FBatch: Integer;
    FAct: Integer;
    FBatchLeft: Integer;
    FTicksToWave: Integer;
    FKills: Integer;
    FMedkitsOwed: Integer;
    // Ticks until the aimed gravel follows its mark; 0 - none on its way
    FAimedIn: Integer;
    FTicksToReturn: Integer;
    procedure TickAimed(var ACue: TTrialCue);
    procedure TickPitReturn(var ACue: TTrialCue);
    procedure DealWave(AGravelsAlive: Integer; var ACue: TTrialCue);
    procedure DealGravel(var ACue: TTrialCue);
    procedure EndAct(var ACue: TTrialCue);
  public
    // ABatch - the gravels of one act
    procedure Start(ABatch: Integer);
    procedure Stop;
    // A gravel of the trial died
    procedure NoteGravelKilled;
    // One logic tick; AGravelsAlive - the live gravels of the trial
    function Tick(AGravelsAlive: Integer): TTrialCue;
    property Active: Boolean read FActive;
    // 1..TrialActs
    property Act: Integer read FAct;
  end;

implementation

procedure TGravelTrial.Start(ABatch: Integer);
begin
  FActive := True;
  FBatch := ABatch;
  FAct := 1;
  FBatchLeft := ABatch;
  FTicksToWave := TrialFirstWaveTicks;
  FKills := 0;
  FMedkitsOwed := 0;
  FAimedIn := 0;
  FTicksToReturn := TrialPitReturnTicks;
end;

procedure TGravelTrial.Stop;
begin
  FActive := False;
  FAimedIn := 0;
end;

procedure TGravelTrial.NoteGravelKilled;
begin
  if not FActive then
    Exit;
  Inc(FKills);
  if FKills mod TrialKillsPerMedkit = 0 then
    Inc(FMedkitsOwed);
end;

function TGravelTrial.Tick(AGravelsAlive: Integer): TTrialCue;
begin
  Result := Default(TTrialCue);
  if not FActive then
    Exit;

  if FMedkitsOwed > 0 then
  begin
    Dec(FMedkitsOwed);
    Result.SpawnMedkit := True;
  end;
  TickAimed(Result);
  TickPitReturn(Result);

  Dec(FTicksToWave);
  if FTicksToWave > 0 then
    Exit;
  FTicksToWave := TrialWaveTicks;
  DealWave(AGravelsAlive, Result);
end;

procedure TGravelTrial.TickAimed(var ACue: TTrialCue);
begin
  if FAimedIn = 0 then
    Exit;
  Dec(FAimedIn);
  ACue.SpawnAimed := FAimedIn = 0;
end;

procedure TGravelTrial.TickPitReturn(var ACue: TTrialCue);
begin
  Dec(FTicksToReturn);
  if FTicksToReturn > 0 then
    Exit;
  FTicksToReturn := TrialPitReturnTicks;
  ACue.ReturnFromPit := True;
end;

procedure TGravelTrial.DealWave(AGravelsAlive: Integer;
  var ACue: TTrialCue);
begin
  // No cap on the living: a gravel left alive does not hold the next one
  // back - the batch is the only limit
  if FBatchLeft > 0 then
  begin
    DealGravel(ACue);
    Exit;
  end;

  // An aimed gravel still on its way is of the batch, alive or not yet
  if (AGravelsAlive = 0) and (FAimedIn = 0) then
    EndAct(ACue);
end;

procedure TGravelTrial.DealGravel(var ACue: TTrialCue);
begin
  Dec(FBatchLeft);
  var Dealt := FBatch - FBatchLeft;
  var Aimed := (FAct >= TrialAimedFromAct) and (Dealt mod TrialAimedEvery = 0);
  if Aimed then
  begin
    ACue.MarkAimed := True;
    FAimedIn := TrialAimedLeadTicks;
    Exit;
  end;
  ACue.SpawnGravel := True;
  ACue.Herald := Dealt = 1;
end;

procedure TGravelTrial.EndAct(var ACue: TTrialCue);
begin
  if FAct >= TrialActs then
  begin
    FActive := False;
    ACue.Finished := True;
    Exit;
  end;

  Inc(FAct);
  FBatchLeft := FBatch;
  FTicksToWave := TrialActBreakTicks;
end;

end.
