{
  Tests.Game.Press - the press of the gravel trial's finale: every row in
  at the start; an arrival brings the top row out and holds the beat; a
  beat rides the rows out a row down, the bottom one off the press; a row
  out under a row out goes in and comes out again; an emptied row rides
  on; shut and started again. And the press action of a level's events,
  and the press of the gravel arena of level 2.

  The press only counts, so the tests tick it and read what it tells the
  shelves. Rows are four banks named of the test's own; the arena is read
  from level2.json beside the executable.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Press;

interface

uses
  DUnitX.TestFramework,
  Game.Press;

type
  [TestFixture]
  TPressTests = class
  private
    FPress: TPress;
    function TicksToNextCall(ALimit: Integer; out ACall: TPressCall): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestEveryRowStartsIn;
    [Test]
    procedure TestArrivalBringsTheTopRowOut;
    [Test]
    procedure TestBeatRidesTheRowsDownARow;
    [Test]
    procedure TestBottomRowFallsOffThePress;
    [Test]
    procedure TestBeatWaitsOutAnArrival;
    [Test]
    procedure TestRowUnderARowGoesInAndComesOutAgain;
    [Test]
    procedure TestShutAndStartedAgain;
    [Test]
    procedure TestNoRowsOrNoBeatIsNoPress;
    [Test]
    procedure TestBeatTicksFromSeconds;
  end;

  [TestFixture]
  TPressLevelTests = class
  public
    [Test]
    procedure TestPressIsRead;
    [Test]
    procedure TestBadPressRaises;
    [Test]
    procedure TestPressOntoAnUnknownBankRaises;
    [Test]
    procedure TestLevelTwoArenaPressesItsBalconies;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.JSON,
  Levels.Defs,
  Levels.Events,
  Levels.Pads,
  Tests.Rooms;

const
  RowNames: array [0..3] of string = ('r1', 'r2', 'r3', 'r4');
  Beat = 100;
  // Long enough for any call of the tests to come
  WatchTicks = 1000;

function Rows: TArray<string>;
begin
  Result := nil;
  for var Name in RowNames do
    Result := Result + [Name];
end;

function Joined(const ANames: TArray<string>): string;
begin
  Result := string.Join(',', ANames);
end;

procedure TPressTests.Setup;
begin
  FPress := TPress.Create;
end;

procedure TPressTests.TearDown;
begin
  FreeAndNil(FPress);
end;

// The ticks, counted from 1, to the first tick that tells the shelves
// anything; 0 when none does within ALimit
function TPressTests.TicksToNextCall(ALimit: Integer;
  out ACall: TPressCall): Integer;
begin
  for var Tick := 1 to ALimit do
  begin
    ACall := FPress.Tick;
    if not ACall.IsEmpty then
      Exit(Tick);
  end;
  ACall := Default(TPressCall);
  Result := 0;
end;

procedure TPressTests.TestEveryRowStartsIn;
var
  Call: TPressCall;
begin
  FPress.Start(Rows, Beat);

  Assert.IsTrue(FPress.Active, 'The press runs');
  for var Name in RowNames do
    Assert.IsFalse(FPress.RowOut(Name), Name + ' is out');
  // A beat over rows all in moves nothing
  Assert.AreEqual(0, TicksToNextCall(3 * Beat, Call), 'A beat over no row out');
end;

procedure TPressTests.TestArrivalBringsTheTopRowOut;
begin
  FPress.Start(Rows, Beat);

  var Call := FPress.Arrive('r1');
  Assert.AreEqual('r1', Joined(Call.Wake), 'The top row comes out');
  Assert.AreEqual('', Joined(Call.Sleep), 'and nothing goes in');
  Assert.IsTrue(FPress.RowOut('r1'), 'It is out');

  Assert.IsTrue(FPress.Arrive('r1').IsEmpty, 'A row out is not told again');
  Assert.IsTrue(FPress.Arrive('r3').IsEmpty, 'No arrival onto another row');
  Assert.IsFalse(FPress.RowOut('r3'), 'r3 stays in');
end;

procedure TPressTests.TestBeatRidesTheRowsDownARow;
var
  Call: TPressCall;
begin
  FPress.Start(Rows, Beat);
  FPress.Arrive('r1');

  Assert.AreEqual(Beat, TicksToNextCall(WatchTicks, Call), 'On the beat');
  Assert.AreEqual('r1', Joined(Call.Sleep), 'The top row goes in');
  Assert.AreEqual('r2', Joined(Call.Wake), 'the row under it comes out');
  Assert.IsFalse(FPress.RowOut('r1'), 'r1 is in');
  Assert.IsTrue(FPress.RowOut('r2'), 'r2 is out');
end;

// No newcomer after the first: its row rides to the bottom and off, a
// beat a row, whether its body lives or not
procedure TPressTests.TestBottomRowFallsOffThePress;
var
  Call: TPressCall;
begin
  FPress.Start(Rows, Beat);
  FPress.Arrive('r1');

  for var i := 1 to High(RowNames) do
  begin
    Assert.AreEqual(Beat, TicksToNextCall(WatchTicks, Call),
      Format('Beat %d', [i]));
    Assert.AreEqual(RowNames[i], Joined(Call.Wake), Format('Beat %d wakes', [i]));
  end;
  Assert.AreEqual(Beat, TicksToNextCall(WatchTicks, Call), 'The last beat');
  Assert.AreEqual('r4', Joined(Call.Sleep), 'The bottom row goes in');
  Assert.AreEqual('', Joined(Call.Wake), 'and nothing comes out under it');
  for var Name in RowNames do
    Assert.IsFalse(FPress.RowOut(Name), Name + ' is out');
  Assert.AreEqual(0, TicksToNextCall(3 * Beat, Call), 'The press is empty');
end;

procedure TPressTests.TestBeatWaitsOutAnArrival;
const
  ShortBeat = 30;
  ArrivalTick = 20;
var
  Call: TPressCall;
begin
  FPress.Start(Rows, ShortBeat);
  for var Tick := 1 to ArrivalTick do
    FPress.Tick;
  FPress.Arrive('r1');

  var Ticks := TicksToNextCall(WatchTicks, Call);
  Assert.AreEqual(PressArrivalTicks, Ticks,
    'The beat came due while the newcomer fell, and waited for it');
  Assert.AreEqual('r1', Joined(Call.Sleep), 'Then the top row goes in');
end;

// r2 carries a body, r1 a newcomer: on the beat both go in, r3 comes out
// for the body of r2, and r2 comes out again for the body of r1
procedure TPressTests.TestRowUnderARowGoesInAndComesOutAgain;
var
  Call: TPressCall;
begin
  FPress.Start(Rows, Beat);
  FPress.Arrive('r1');
  TicksToNextCall(WatchTicks, Call);
  FPress.Arrive('r1');

  Assert.AreEqual(Beat, TicksToNextCall(WatchTicks, Call),
    'The next beat, the newcomer down by then');
  Assert.AreEqual('r1,r2', Joined(Call.Sleep), 'Both rows out go in');
  Assert.AreEqual('r3', Joined(Call.Wake), 'the row under them comes out');
  Assert.IsTrue(FPress.RowOut('r2'), 'r2 is told to come out again');

  Assert.AreEqual(PressRewakeTicks, TicksToNextCall(WatchTicks, Call),
    'A moment later');
  Assert.AreEqual('r2', Joined(Call.Wake), 'r2 comes out again');
  Assert.AreEqual('', Joined(Call.Sleep), 'and nothing goes in');
end;

procedure TPressTests.TestShutAndStartedAgain;
var
  Call: TPressCall;
begin
  FPress.Start(Rows, Beat);
  FPress.Arrive('r1');
  FPress.Shut;

  Assert.IsFalse(FPress.Active, 'Shut');
  Assert.IsTrue(FPress.Arrive('r1').IsEmpty, 'An arrival on a shut press');
  Assert.AreEqual(0, TicksToNextCall(3 * Beat, Call), 'A beat on a shut press');

  FPress.Start(Rows, Beat);
  Assert.IsFalse(FPress.RowOut('r1'), 'Started again, every row is in');
  Assert.AreEqual('r1', Joined(FPress.Arrive('r1').Wake), 'and works');
end;

procedure TPressTests.TestNoRowsOrNoBeatIsNoPress;
begin
  FPress.Start(nil, Beat);
  Assert.IsFalse(FPress.Active, 'No rows');
  FPress.Start(Rows, 0);
  Assert.IsFalse(FPress.Active, 'No beat');
end;

procedure TPressTests.TestBeatTicksFromSeconds;
begin
  Assert.AreEqual(330, PressBeatTicks(10), 'Ten seconds');
  Assert.AreEqual(1, PressBeatTicks(0.001), 'A tick at least');
end;

// ---------------------------------------------------------------------------
// The level
// ---------------------------------------------------------------------------

const
  LevelTwoFile = 'level2.json';
  LevelTwoArenaScreen = 9;
  LevelTwoWaveAct = 6;
  LevelTwoPressRows: array [0..3] of string = ('s09-press-1', 's09-press-2',
    's09-press-3', 's09-press-4');
  // The decks of the rows, top first: rows 3, 5, 7 and 9
  LevelTwoPressDecks: array [0..3] of Integer = (96, 160, 224, 288);
  LevelTwoBalconyBank = 's09-balcony';
  LevelTwoFlock = 's09-strays';
  // A row: three shelves at each wall
  ShelvesARow = 6;
  // The balconies stand at columns 1-3 and 12-14; the strays keep between
  FirstStrayCol = 4;
  LastStrayCol = 11;

function PressEvents(const AMembers: string; AAct: Integer): TArray<TLevelEvent>;
begin
  var When := '"when":"enterScreen"';
  if AAct > 0 then
    When := Format('"when":"actReached","act":%d', [AAct]);
  var Json := Format('{"events":[{"id":"press","screen":1,%s,"then":[' +
    '{"action":"press"%s}]}]}', [When, AMembers]);
  var Root := TJSONObject.ParseJSONValue(Json) as TJSONObject;
  try
    Result := ParseLevelEvents(Root, 'test');
  finally
    Root.Free;
  end;
end;

// By value, not const: an anonymous method captures them
procedure ExpectPressRefused(AMembers: string; AAct: Integer; AWhy: string);
begin
  Assert.WillRaise(
    procedure
    begin
      PressEvents(AMembers, AAct);
    end, ELevelEventError, AWhy);
end;

procedure TPressLevelTests.TestPressIsRead;
begin
  var Events := PressEvents(',"rows":["a","b","c"],"every":7.5', 6);
  var Action := Events[0].Actions[0];
  Assert.AreEqual<TEventActionKind>(eaPress, Action.Kind, 'The action');
  Assert.AreEqual('a,b,c', Joined(Action.Press.Rows), 'Its rows, top first');
  Assert.IsTrue(Abs(Action.Press.EverySeconds - 7.5) < 0.0001, 'Its beat');
end;

procedure TPressLevelTests.TestBadPressRaises;
begin
  ExpectPressRefused(',"every":10', 6, 'No rows');
  ExpectPressRefused(',"rows":["a"],"every":10', 6, 'One row');
  ExpectPressRefused(',"rows":["a",""],"every":10', 6, 'A row of no bank');
  ExpectPressRefused(',"rows":["a","b"]', 6, 'No beat');
  ExpectPressRefused(',"rows":["a","b"],"every":0', 6, 'A beat of nothing');
  ExpectPressRefused(',"rows":["a","b"],"every":10', 0, 'No act');
end;

procedure TPressLevelTests.TestPressOntoAnUnknownBankRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      LevelFromRows(RoomRowsOf(0, 0, 0, 0), '"events":[{"id":"p","screen":1,' +
        '"when":"actReached","act":6,"then":[{"action":"press",' +
        '"rows":["nowhere","nothing"],"every":10}]}]').Free;
    end, ELevelError, 'A press of banks no shelf stands in');
end;

// The press of the arena: four rows of balconies, top first, six shelves
// each, all of them the balcony bank; the newcomers onto the top row; the
// strays kept between the balconies; the balconies in once the trial is won
procedure TPressLevelTests.TestLevelTwoArenaPressesItsBalconies;
begin
  var Level := TLevel.Create;
  try
    Level.LoadFromFile(TPath.Combine(ExtractFilePath(ParamStr(0)),
      LevelTwoFile));

    var Presses := 0;
    var WaveOnto := '';
    var EndSleeps := 0;
    for var Event in Level.Events do
      for var Action in Event.Actions do
      begin
        if Action.Kind = eaPress then
        begin
          Inc(Presses);
          Assert.AreEqual(LevelTwoArenaScreen, Event.Screen, 'The screen');
          Assert.AreEqual(LevelTwoWaveAct, Event.Act, 'The act of the wave');
          Assert.AreEqual(Integer(Length(LevelTwoPressRows)),
            Integer(Length(Action.Press.Rows)), 'Four rows');
          for var i := 0 to High(LevelTwoPressRows) do
            Assert.AreEqual(LevelTwoPressRows[i], Action.Press.Rows[i],
              Format('Row %d, top first', [i + 1]));
        end;
        if Action.Kind = eaWaveOnto then
          WaveOnto := Action.Target;
        if (Event.Condition = ecTrialDone) and (Action.Kind = eaShelvesSleep) and
          (Action.Target = LevelTwoBalconyBank) then
        begin
          Inc(EndSleeps);
          Assert.IsTrue(Action.SpareHero, 'The calm spares the hero');
        end;
      end;
    Assert.AreEqual(1, Presses, 'One press');
    Assert.AreEqual(LevelTwoPressRows[0], WaveOnto, 'Newcomers onto the top row');
    Assert.AreEqual(1, EndSleeps, 'The balconies go in once the trial is won');

    var Balconies := 0;
    for var i := 0 to High(LevelTwoPressRows) do
    begin
      var Shelves := 0;
      for var Pad in Level.Pads do
      begin
        if not Pad.Shelf.InBank(LevelTwoPressRows[i]) then
          Continue;
        Inc(Shelves);
        Assert.AreEqual(LevelTwoPressDecks[i], Pad.Y, Format('%s stands at ' +
          'its row', [Pad.Tag]));
        Assert.IsTrue(Pad.Shelf.InBank(LevelTwoBalconyBank),
          Pad.Tag + ' is a balcony');
      end;
      Assert.AreEqual(ShelvesARow, Shelves, LevelTwoPressRows[i]);
      Inc(Balconies, Shelves);
    end;
    var InBalconyBank := 0;
    for var Pad in Level.Pads do
      if Pad.Shelf.InBank(LevelTwoBalconyBank) then
        Inc(InBalconyBank);
    Assert.AreEqual(Balconies, InBalconyBank, 'The balcony bank is the press');

    for var Pad in Level.Pads do
    begin
      if not (Pad.Stray.Strays and (Pad.Stray.Flock = LevelTwoFlock)) then
        Continue;
      Assert.AreEqual(FirstStrayCol, Pad.Stray.Zone.Left, Pad.Tag + ' left');
      Assert.AreEqual(LastStrayCol, Pad.Stray.Zone.Right, Pad.Tag + ' right');
    end;
  finally
    Level.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TPressTests);
  TDUnitX.RegisterTestFixture(TPressLevelTests);

end.
