{
  Tests.Hud.GoRight - the beat of the go-right arrow: dark while hidden;
  four slow blinks, each coming up from dark to full and going out to
  dark again; gone after the fourth; hidden, it goes dark, shown again,
  it starts over. And the words of the events that raise it - the
  victoryEnds condition with its lead, the fade of the music action, the
  goRight action - and the false ending of level 2.

  The beat is ticked and read, the picture is not drawn: that needs a
  renderer. Level 2 is read from level2.json beside the executable.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Hud.GoRight;

interface

uses
  DUnitX.TestFramework,
  Hud.GoRight;

type
  [TestFixture]
  TGoRightBeatTests = class
  private
    FBeat: TGoRightBeat;
    procedure TickTimes(ACount: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestHiddenArrowIsDark;
    [Test]
    procedure TestBlinkComesUpFromDark;
    [Test]
    procedure TestBlinkIsFullInItsMiddle;
    [Test]
    procedure TestBlinkGoesOutToDark;
    [Test]
    procedure TestArrowIsGoneAfterFourBlinks;
    [Test]
    procedure TestHiddenArrowGoesDark;
    [Test]
    procedure TestShownAgainStartsOver;
  end;

  [TestFixture]
  TGoRightLevelTests = class
  public
    [Test]
    procedure TestVictoryEndsAndGoRightAreRead;
    [Test]
    procedure TestMusicFadeIsRead;
    [Test]
    procedure TestNegativeLeadOrFadeRaises;
    [Test]
    procedure TestLevelTwoGoesOnOverTheVictoryTrack;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.JSON,
  Levels.Defs,
  Levels.Events;

const
  BlinkTicks = 60;
  Blinks = 4;
  Near = 0.01;

procedure TGoRightBeatTests.Setup;
begin
  FBeat := TGoRightBeat.Create;
end;

procedure TGoRightBeatTests.TearDown;
begin
  FBeat.Free;
end;

procedure TGoRightBeatTests.TickTimes(ACount: Integer);
begin
  for var i := 1 to ACount do
    FBeat.Tick;
end;

procedure TGoRightBeatTests.TestHiddenArrowIsDark;
begin
  TickTimes(BlinkTicks);
  Assert.IsFalse(FBeat.Shown, 'Not shown');
  Assert.AreEqual<Single>(0, FBeat.LevelAt(0.5), 'Not lit');
end;

procedure TGoRightBeatTests.TestBlinkComesUpFromDark;
begin
  FBeat.Show;
  FBeat.Tick;
  var Start := FBeat.LevelAt(0);
  TickTimes(BlinkTicks div 4);
  Assert.IsTrue(Start < Near, 'Dark at the start');
  Assert.IsTrue(FBeat.LevelAt(0) > Start + 0.3, 'Coming up slowly');
end;

procedure TGoRightBeatTests.TestBlinkIsFullInItsMiddle;
begin
  FBeat.Show;
  TickTimes(BlinkTicks div 2 + 1);
  Assert.IsTrue(FBeat.LevelAt(0) > 1 - Near, 'Full in the middle');
end;

procedure TGoRightBeatTests.TestBlinkGoesOutToDark;
begin
  FBeat.Show;
  TickTimes(BlinkTicks * 3 div 4 + 1);
  var Going := FBeat.LevelAt(0);
  TickTimes(BlinkTicks div 4 - 1);
  Assert.IsTrue((Going > 0.3) and (Going < 0.7), 'Going out slowly');
  Assert.IsTrue(FBeat.LevelAt(0.99) < Near, 'Dark at the end');
end;

procedure TGoRightBeatTests.TestArrowIsGoneAfterFourBlinks;
begin
  FBeat.Show;
  TickTimes(Blinks * BlinkTicks);
  Assert.IsTrue(FBeat.Shown, 'Still up through the fourth');
  FBeat.Tick;
  Assert.IsFalse(FBeat.Shown, 'Gone after it');
  Assert.AreEqual<Single>(0, FBeat.LevelAt(0.5), 'And dark');
end;

procedure TGoRightBeatTests.TestHiddenArrowGoesDark;
begin
  FBeat.Show;
  TickTimes(BlinkTicks div 2);
  FBeat.Hide;
  Assert.IsFalse(FBeat.Shown, 'Taken down');
  Assert.AreEqual<Single>(0, FBeat.LevelAt(0), 'Dark at once');
end;

procedure TGoRightBeatTests.TestShownAgainStartsOver;
begin
  FBeat.Show;
  TickTimes(BlinkTicks * 3 + BlinkTicks div 2);
  FBeat.Show;
  FBeat.Tick;
  Assert.IsTrue(FBeat.LevelAt(0) < Near, 'From dark again');
  TickTimes(Blinks * BlinkTicks - 1);
  Assert.IsTrue(FBeat.Shown, 'With four blinks of its own');
end;

function EventsOf(const AJson: string): TArray<TLevelEvent>;
begin
  var Root := TJSONObject.ParseJSONValue(AJson) as TJSONObject;
  try
    Result := ParseLevelEvents(Root, 'test');
  finally
    Root.Free;
  end;
end;

// By value, not const: an anonymous method captures it
procedure ExpectRefused(AJson, AWhy: string);
begin
  Assert.WillRaise(
    procedure
    begin
      EventsOf(AJson);
    end, ELevelEventError, AWhy);
end;

procedure TGoRightLevelTests.TestVictoryEndsAndGoRightAreRead;
begin
  var Events := EventsOf('{"events":[{"id":"on","screen":2,' +
    '"when":"victoryEnds","lead":2.5,"then":[{"action":"goRight"}]},' +
    '{"id":"end","screen":2,"when":"victoryEnds","then":[{"action":"goRight"}]}]}');
  Assert.AreEqual<TEventCondition>(ecVictoryEnds, Events[0].Condition,
    'The condition');
  Assert.AreEqual<Single>(2.5, Events[0].LeadSeconds, 'Its lead');
  Assert.AreEqual<Single>(0, Events[1].LeadSeconds, 'No lead - the very end');
  Assert.AreEqual<TEventActionKind>(eaGoRight, Events[0].Actions[0].Kind,
    'The action');
end;

procedure TGoRightLevelTests.TestMusicFadeIsRead;
begin
  var Events := EventsOf('{"events":[{"id":"m","screen":1,"when":"enterScreen",' +
    '"then":[{"action":"music","file":"a.ogg","fade":3},' +
    '{"action":"music","file":"b.ogg"}]}]}');
  Assert.AreEqual<Single>(3, Events[0].Actions[0].FadeSeconds, 'A fade');
  Assert.AreEqual<Single>(0, Events[0].Actions[1].FadeSeconds, 'None - at once');
end;

procedure TGoRightLevelTests.TestNegativeLeadOrFadeRaises;
begin
  ExpectRefused('{"events":[{"id":"l","screen":1,"when":"victoryEnds",' +
    '"lead":-1,"then":[{"action":"goRight"}]}]}', 'A lead below zero');
  ExpectRefused('{"events":[{"id":"f","screen":1,"when":"enterScreen",' +
    '"then":[{"action":"music","file":"a.ogg","fade":-2}]}]}',
    'A fade below zero');
end;

// The tunnels' ambient fades in under the end of the victory track, the
// arrow comes at its very end - both on the arena's screen
procedure TGoRightLevelTests.TestLevelTwoGoesOnOverTheVictoryTrack;
const
  LevelTwoFile = 'level2.json';
  LevelTwoArenaScreen = 9;
  TunnelMusic = 'lunar.ogg';
begin
  var Level := TLevel.Create;
  try
    Level.LoadFromFile(TPath.Combine(ExtractFilePath(ParamStr(0)),
      LevelTwoFile));

    var MusicLead: Single := -1;
    var MusicFade: Single := -1;
    var ArrowLead: Single := -1;
    for var Event in Level.Events do
    begin
      if Event.Condition <> ecVictoryEnds then
        Continue;
      Assert.AreEqual(LevelTwoArenaScreen, Event.Screen, 'On the arena');
      for var Action in Event.Actions do
      begin
        if (Action.Kind = eaMusic) and (Action.FileName = TunnelMusic) then
        begin
          MusicLead := Event.LeadSeconds;
          MusicFade := Action.FadeSeconds;
        end;
        if Action.Kind = eaGoRight then
          ArrowLead := Event.LeadSeconds;
      end;
    end;
    Assert.IsTrue(MusicLead > 0, 'The ambient comes before the end');
    Assert.IsTrue(MusicFade > 0, 'From silence');
    Assert.AreEqual<Single>(0, ArrowLead, 'The arrow at the very end');
  finally
    Level.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TGoRightBeatTests);
  TDUnitX.RegisterTestFixture(TGoRightLevelTests);

end.
