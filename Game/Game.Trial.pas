{
  Game.Trial - the gravel trial of level 2: its rules, with no monster
  field, no hero and no SDL in them.

  The trial runs in acts. An act is a batch of gravels let down a wave at
  a time. The next act does not come until every gravel of the batch is
  dead; then the room takes a short breath and the next batch starts. The
  gate of the last act ends the trial. Every fifteenth gravel killed pays
  one medkit, counted across the acts.

  The game tells the trial how many gravels are alive and which of them
  died, and does what the cue of a tick says: lets a gravel down, lets a
  medkit down, or ends the trial.

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

type
  TTrialCue = record
    SpawnGravel: Boolean;
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
    procedure DealWave(AGravelsAlive: Integer; var ACue: TTrialCue);
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
end;

procedure TGravelTrial.Stop;
begin
  FActive := False;
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

  Dec(FTicksToWave);
  if FTicksToWave > 0 then
    Exit;
  FTicksToWave := TrialWaveTicks;
  DealWave(AGravelsAlive, Result);
end;

procedure TGravelTrial.DealWave(AGravelsAlive: Integer;
  var ACue: TTrialCue);
begin
  // No cap on the living: a gravel left alive does not hold the next one
  // back - the batch is the only limit
  if FBatchLeft > 0 then
  begin
    Dec(FBatchLeft);
    ACue.SpawnGravel := True;
    Exit;
  end;

  if AGravelsAlive = 0 then
    EndAct(ACue);
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
