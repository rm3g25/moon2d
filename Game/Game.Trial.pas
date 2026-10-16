{
  Game.Trial - the gravel trial of level 2: its rules, with no monster
  field, no hero and no SDL in them.

  The trial runs in acts. An act is a batch of gravels let down a wave at
  a time. The next act does not come until every gravel of the batch is
  dead - the gate is watched every tick once the batch is spent, so the
  room rebuilds the moment the last one dies; then the room takes a short
  breath and the next batch starts. A room that is busy with a scene of
  its own holds the next batch back until the scene is over. The gate of
  the last act ends the trial. Every fifteenth gravel killed pays one
  medkit, counted across the acts; and every act pays one more at its
  middle, when half its batch - or half the wave - is killed.

  A gravel fallen into the pit comes back one at a time, a beat apart:
  a crowd dropped at once does not land on the hero at once.

  The first gravel of every act comes as a herald, in a light of its own.
  From the second act on every third gravel of a batch is aimed: the
  light marks the column the hero stands in, and the gravel follows it a
  moment later - time enough to step aside, if he looks up.

  The game tells the trial how many bodies hold the gate - the gravels
  alive and whoever else it counts in - and which gravels died, and does
  what the cue of a tick says: lets a gravel down, marks the column of an
  aimed one and lets it down there, lets a body of the wave down, brings
  one gravel back from the pit, lets a medkit down, or ends the trial.

  The trial also says how far its batch is dealt, for the events that wait
  on that, and tells the game when an act is over.

  An event may open the sky for the act it waits for: from then on a body
  falls from it every so many seconds, until that act is over. The trial
  keeps the pace; which body falls is the game's.

  A trial may end in a wave: one act more after the gravels, dealt by
  another rule. The wave has a count, not a batch, and never more of it
  alive than its cap: a body comes a wave apart while the room fills up,
  and a dead one is replaced a beat after it dies. Only the wave's own
  living are counted against the cap; whoever else holds the gate does
  not hold the wave back. No body of the wave is aimed; its first is a
  herald. Which body comes is the game's, and so is telling the trial
  which of them died.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Trial;
{$I ..\Moon2D.inc}

interface

const
  // The acts of gravels; a wave, when the trial has one, is an act more
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
  // A dead body of the wave is replaced this long after it dies
  TrialWaveRefillTicks = 33;
  LogicTicksPerSecond = 33;

type
  TTrialCue = record
    SpawnGravel: Boolean;
    // Let down a body of the wave
    SpawnWave: Boolean;
    // The gravel or the body of the wave let down is the first of its act
    Herald: Boolean;
    // Mark the hero's column for an aimed gravel; let it down there
    MarkAimed: Boolean;
    SpawnAimed: Boolean;
    // Bring back one gravel fallen into the pit, if one is down there
    ReturnFromPit: Boolean;
    SpawnMedkit: Boolean;
    // The open sky lets its body down
    SkyFall: Boolean;
    // The gate opened: the act is over, the last one too
    ActEnded: Boolean;
    Finished: Boolean;
  end;

  // Where the trial stands, for the events that wait on it; all zero while
  // it does not run. In the act of the wave the batch is the wave's count.
  TTrialProgress = record
    Act: Integer;
    Batch: Integer;
    // Gravels of the batch let down so far, an aimed one from its mark
    Dealt: Integer;
    // Bodies of the wave killed; 0 outside the act of the wave
    WaveKilled: Integer;
  end;

  TGravelTrial = class
  private
    FActive: Boolean;
    FGravelBatch: Integer;
    // Of the act in progress: the gravel batch, or the wave's count
    FBatch: Integer;
    FAct: Integer;
    FActs: Integer;
    FBatchLeft: Integer;
    // The wave: its count (0 - the trial has none) and its cap of the living
    FWaveCount: Integer;
    FWaveCap: Integer;
    FWaveKills: Integer;
    FTicksToWave: Integer;
    FKills: Integer;
    // Gravels killed in the act in progress
    FActKills: Integer;
    FMedkitsOwed: Integer;
    // Ticks until the aimed gravel follows its mark; 0 - none on its way
    FAimedIn: Integer;
    FTicksToReturn: Integer;
    // The pace of the open sky, 0 - it is shut; the ticks to its next body
    FSkyEvery: Integer;
    FTicksToSky: Integer;
    FRoomBusy: Boolean;
    procedure TickAimed(var ACue: TTrialCue);
    procedure TickPitReturn(var ACue: TTrialCue);
    procedure TickSky(var ACue: TTrialCue);
    procedure WatchGate(AGateHolders: Integer; var ACue: TTrialCue);
    procedure DealGravel(var ACue: TTrialCue);
    procedure DealWave(AWaveAlive: Integer; var ACue: TTrialCue);
    procedure EndAct(var ACue: TTrialCue);
    function InWaveAct: Boolean;
    procedure PayMiddle(AActKills: Integer);
  public
    // ABatch - the gravels of one act. AWaveCount above zero ends the trial
    // in a wave of that many bodies, no more than AWaveCap alive at once.
    procedure Start(ABatch: Integer; AWaveCount: Integer = 0;
      AWaveCap: Integer = 0);
    procedure Stop;
    // A gravel of the trial died
    procedure NoteGravelKilled;
    // A body of the wave died; nothing outside the act of the wave
    procedure NoteWaveKilled;
    // A body falls from the sky every AEverySeconds, the first one that long
    // from now, until the act in progress is over. Told again, the sky takes
    // the new pace from now.
    procedure OpenSky(AEverySeconds: Single);
    // One logic tick; AGateHolders - the live bodies that hold the gate:
    // the gravels of the trial, the bodies of its wave and whoever else
    // the game counts in; AWaveAlive - the bodies of the wave alive alone,
    // counted against its cap
    function Tick(AGateHolders: Integer; AWaveAlive: Integer = 0): TTrialCue;
    function Progress: TTrialProgress;
    property Active: Boolean read FActive;
    // 1..Acts
    property Act: Integer read FAct;
    // TrialActs, one more with a wave
    property Acts: Integer read FActs;
    // A scene plays in the room: the first wave of the next act waits
    property RoomBusy: Boolean read FRoomBusy write FRoomBusy;
  end;

implementation

procedure TGravelTrial.Start(ABatch: Integer; AWaveCount: Integer;
  AWaveCap: Integer);
begin
  FActive := True;
  FGravelBatch := ABatch;
  FBatch := ABatch;
  FWaveCount := 0;
  FWaveCap := 0;
  FWaveKills := 0;
  FActs := TrialActs;
  if (AWaveCount > 0) and (AWaveCap > 0) then
  begin
    FWaveCount := AWaveCount;
    FWaveCap := AWaveCap;
    FActs := TrialActs + 1;
  end;
  FAct := 1;
  FBatchLeft := ABatch;
  FTicksToWave := TrialFirstWaveTicks;
  FKills := 0;
  FActKills := 0;
  FMedkitsOwed := 0;
  FAimedIn := 0;
  FTicksToReturn := TrialPitReturnTicks;
  FSkyEvery := 0;
end;

procedure TGravelTrial.Stop;
begin
  FActive := False;
  FAimedIn := 0;
  FSkyEvery := 0;
  FRoomBusy := False;
end;

// A pace under a tick is a tick: the sky never pours more than one body a
// tick
procedure TGravelTrial.OpenSky(AEverySeconds: Single);
begin
  if not FActive then
    Exit;
  var Ticks: Integer := Round(AEverySeconds * LogicTicksPerSecond);
  if Ticks < 1 then
    Ticks := 1;
  FSkyEvery := Ticks;
  FTicksToSky := FSkyEvery;
end;

procedure TGravelTrial.NoteGravelKilled;
begin
  if not FActive then
    Exit;
  Inc(FKills);
  if FKills mod TrialKillsPerMedkit = 0 then
    Inc(FMedkitsOwed);
  if InWaveAct then
    Exit;
  Inc(FActKills);
  PayMiddle(FActKills);
end;

procedure TGravelTrial.NoteWaveKilled;
begin
  if not (FActive and InWaveAct) then
    Exit;
  Inc(FWaveKills);
  PayMiddle(FWaveKills);
end;

// The medkit of the act's middle: on the kill that makes half of it. An act
// of one has no middle.
procedure TGravelTrial.PayMiddle(AActKills: Integer);
begin
  var Half := FBatch div 2;
  if (Half > 0) and (AActKills = Half) then
    Inc(FMedkitsOwed);
end;

function TGravelTrial.Tick(AGateHolders: Integer;
  AWaveAlive: Integer): TTrialCue;
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
  TickSky(Result);

  if FBatchLeft = 0 then
  begin
    WatchGate(AGateHolders, Result);
    Exit;
  end;
  // No gravel of the act let down yet: this is the breath between acts
  if FRoomBusy and (FBatchLeft = FBatch) then
    Exit;
  if InWaveAct then
  begin
    DealWave(AWaveAlive, Result);
    Exit;
  end;
  Dec(FTicksToWave);
  if FTicksToWave > 0 then
    Exit;
  FTicksToWave := TrialWaveTicks;
  // No cap on the living: a gravel left alive does not hold the next one
  // back - the batch is the only limit
  DealGravel(Result);
end;

function TGravelTrial.Progress: TTrialProgress;
begin
  Result := Default(TTrialProgress);
  if not FActive then
    Exit;
  Result.Act := FAct;
  Result.Batch := FBatch;
  Result.Dealt := FBatch - FBatchLeft;
  if InWaveAct then
    Result.WaveKilled := FWaveKills;
end;

function TGravelTrial.InWaveAct: Boolean;
begin
  Result := (FWaveCount > 0) and (FAct > TrialActs);
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

procedure TGravelTrial.TickSky(var ACue: TTrialCue);
begin
  if FSkyEvery = 0 then
    Exit;
  Dec(FTicksToSky);
  if FTicksToSky > 0 then
    Exit;
  FTicksToSky := FSkyEvery;
  ACue.SkyFall := True;
end;

procedure TGravelTrial.WatchGate(AGateHolders: Integer;
  var ACue: TTrialCue);
begin
  // An aimed gravel still on its way is of the batch, alive or not yet -
  // and so is one let down this very tick, which the count has not seen
  var AimedOnItsWay := (FAimedIn > 0) or ACue.SpawnAimed;
  if (AGateHolders = 0) and not AimedOnItsWay then
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

// The wave is capped, as the gravels are not: while it is full the beat to
// the next body stands at the refill, so a dead one is replaced a beat
// after it dies; while it fills up a body comes a wave apart
procedure TGravelTrial.DealWave(AWaveAlive: Integer; var ACue: TTrialCue);
begin
  if AWaveAlive >= FWaveCap then
  begin
    FTicksToWave := TrialWaveRefillTicks;
    Exit;
  end;
  Dec(FTicksToWave);
  if FTicksToWave > 0 then
    Exit;
  FTicksToWave := TrialWaveTicks;
  Dec(FBatchLeft);
  var Dealt := FBatch - FBatchLeft;
  ACue.SpawnWave := True;
  ACue.Herald := Dealt = 1;
end;

// The sky is the act's: it shuts with it, and lets nothing fall on the tick
// it shuts
procedure TGravelTrial.EndAct(var ACue: TTrialCue);
begin
  ACue.ActEnded := True;
  ACue.SkyFall := False;
  FSkyEvery := 0;
  if FAct >= FActs then
  begin
    FActive := False;
    ACue.Finished := True;
    Exit;
  end;

  Inc(FAct);
  FBatch := FGravelBatch;
  if InWaveAct then
    FBatch := FWaveCount;
  FBatchLeft := FBatch;
  FActKills := 0;
  FTicksToWave := TrialActBreakTicks;
end;

end.
