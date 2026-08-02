{
  Game.Loop - SDL2 window ownership and the fixed-timestep game loop.

  Replaces the 2008 architecture where game logic lived inside a WM_Timer
  handler and game speed floated with the Windows timer granularity. Here
  logic runs at exactly TickRate updates per second regardless of rendering
  speed; Render receives an interpolation alpha for smooth motion between
  logic ticks (classic "Fix Your Timestep" scheme).

  Usage: subclass TGameApp, override Update/Render/HandleKey, pass the
  instance to TGameHost.Run.

  Moon 2D remake. Requires Delphi 12+.
}
unit Game.Loop;
{$I Moon2D.inc}

interface

uses
  System.SysUtils, Sdl2.Core, Game.Config;

type
  EGameHostError = class(Exception);

  TKeyAction = (kaDown, kaUp);

  TGameApp = class
  private
    FQuitRequested: Boolean;
  public
    // One fixed logic step. ADeltaSeconds is constant between calls.
    procedure Update(ADeltaSeconds: Double); virtual; abstract;
    // AAlpha in [0..1): progress toward the next logic tick, for
    // interpolating rendered positions between two known logic states.
    procedure Render(ARenderer: PSdlRenderer; AAlpha: Double);
      virtual; abstract;
    procedure HandleKey(AScancode: Integer; AAction: TKeyAction;
      AIsRepeat: Boolean); virtual;
    // X/Y arrive in logical coordinates (SDL translates when logical
    // size is active) - for Moon 2D that is the native 512x384.
    procedure HandleMouseMove(AX, AY: Integer); virtual;
    procedure HandleMouseButton(AButton: Integer; ADown: Boolean); virtual;

    procedure RequestQuit;
    property QuitRequested: Boolean read FQuitRequested;
  end;

  TGameHost = class
  private
    FConfig: TGameConfig;
    FWindow: PSdlWindow;
    FRenderer: PSdlRenderer;
    FBaseTitle: string;
    FRendererBackend: string; // actual SDL backend name, shown in the title
    procedure CreateWindowAndRenderer;
    procedure PumpEvents(const AApp: TGameApp);
    procedure UpdateFpsTitle(AFps, AWorstFrameMs, AWorstPresentMs: Integer);
    procedure WaitOutFrameBudget(AFrameStartCounter: UInt64;
      AFrequency, AFrameBudget: Double);
  public
    constructor Create(const AConfig: TGameConfig; const ATitle: string);
    destructor Destroy; override;

    procedure Run(const AApp: TGameApp);

    property Renderer: PSdlRenderer read FRenderer;
    property Window: PSdlWindow read FWindow;
  end;

implementation

uses
  Winapi.Windows, Winapi.MMSystem;

resourcestring
  SSdlInitFailed = 'SDL_Init failed: %s';
  SSdlWindowFailed = 'SDL_CreateWindow failed: %s';
  SSdlRendererFailed = 'SDL_CreateRenderer failed: %s';

const
  // A stall (debugger pause, window drag) must not make the loop try to
  // catch up with a mountain of pending ticks - the "spiral of death".
  MaxFrameSeconds = 0.25;

// ---------------------------------------------------------------------------
// TGameApp
// ---------------------------------------------------------------------------

procedure TGameApp.HandleKey(AScancode: Integer; AAction: TKeyAction;
  AIsRepeat: Boolean);
begin
  // Default: nothing. Subclasses override what they care about.
end;

procedure TGameApp.HandleMouseMove(AX, AY: Integer);
begin
end;

procedure TGameApp.HandleMouseButton(AButton: Integer; ADown: Boolean);
begin
end;

procedure TGameApp.RequestQuit;
begin
  FQuitRequested := True;
end;

// ---------------------------------------------------------------------------
// TGameHost
// ---------------------------------------------------------------------------

// Declares this process per-monitor-DPI-aware (V2) before any window
// exists. Without it, on a mixed-scale multi-monitor desktop DWM
// bitmap-stretches the window EVERY frame - the exact signature seen
// in the field: windowed lag on the three-monitor machine, flawless
// on the single-screen laptop, SS4 smooth everywhere (grown-up games
// declare awareness). user32 API, Windows 10 1703+; bound dynamically
// so older Windows simply skips it - a uniform-DPI desktop never hits
// the stretch anyway.
procedure EnablePerMonitorDpiAwareness;
type
  TContextSetter = function(AContext: NativeInt): LongBool; stdcall;
const
  DpiAwarenessContextPerMonitorV2 = -4; // winuser.h pseudo-handle
var
  Setter: TContextSetter;
begin
  // Explicit var, not inline inference: with procedural types the
  // inference engine tries to CALL the right-hand side to learn its
  // type - the classic Pascal ambiguity.
  Setter := GetProcAddress(LoadLibrary('user32.dll'),
    'SetProcessDpiAwarenessContext');
  if Assigned(Setter) then
    Setter(DpiAwarenessContextPerMonitorV2);
end;

constructor TGameHost.Create(const AConfig: TGameConfig; const ATitle: string);
begin
  inherited Create;
  FConfig := AConfig;
  FBaseTitle := ATitle;

  // Must precede SDL_Init: DPI awareness is per-process and latches
  // at the first window or display query.
  EnablePerMonitorDpiAwareness;

  if SDL_Init(SdlInitVideo) <> 0 then
    raise EGameHostError.CreateFmt(SSdlInitFailed,
      [SdlErrorText]);

  CreateWindowAndRenderer;
end;

destructor TGameHost.Destroy;
begin
  if Assigned(FRenderer) then
    SDL_DestroyRenderer(FRenderer);
  if Assigned(FWindow) then
    SDL_DestroyWindow(FWindow);
  SDL_Quit;
  inherited;
end;

procedure TGameHost.CreateWindowAndRenderer;
var
  WindowFlags: UInt32;
  RendererFlags: UInt32;
begin
  WindowFlags := SdlWindowShown;
  if FConfig.Fullscreen then
    WindowFlags := WindowFlags or SdlWindowFullscreenDesktop;

  FWindow := SDL_CreateWindow(PAnsiChar(SdlText(FBaseTitle)),
    SdlWindowPosCentered, SdlWindowPosCentered,
    FConfig.WindowWidth, FConfig.WindowHeight, WindowFlags);
  if FWindow = nil then
    raise EGameHostError.CreateFmt(SSdlWindowFailed,
      [SdlErrorText]);

  RendererFlags := SdlRendererAccelerated;
  if FConfig.Vsync then
    RendererFlags := RendererFlags or SdlRendererPresentVsync;

  // SDL's default renderer backend on Windows is Direct3D 9 - a 2004-era
  // blt-model present path that modern drivers barely exercise. On this
  // project's reference machine it delivered frames with heavy stutter
  // once the iGPU was disabled, while D3D11 (flip-model present, the same
  // path modern games use) is smooth. Ask for D3D11 explicitly; if the
  // hint can't be honored SDL silently falls back to its default.
  SDL_SetHint(SdlHintRenderDriver, 'direct3d11');

  FRenderer := SDL_CreateRenderer(FWindow, -1, RendererFlags);
  if FRenderer = nil then
    raise EGameHostError.CreateFmt(SSdlRendererFailed,
      [SdlErrorText]);

  // Surface the backend that actually got created - stutter diagnostics
  // are meaningless without knowing which present path is on stage.
  // The DLL version rides along: SDL_Delay is ~1 ms accurate only from
  // 2.0.16 (see the Timing section of Sdl2.Core) - one glance at the
  // title settles that question on any machine.
  var Info: TSdlRendererInfo;
  if SDL_GetRendererInfo(FRenderer, @Info) = 0 then
    FRendererBackend := string(AnsiString(Info.Name))
  else
    FRendererBackend := 'unknown';
  var Version: TSdlVersion;
  SDL_GetVersion(@Version);
  FRendererBackend := Format('%s, SDL %d.%d.%d',
    [FRendererBackend, Version.Major, Version.Minor, Version.Patch]);

  // One-shot: stamp the backend into the static title at creation.
  // The periodic stats title is muted (TITLESTATS is off by default),
  // but THIS question - did the d3d11 hint get honored, or did SDL
  // silently fall back to the 2004 D3D9 blt path - must stay readable.
  // A single write at startup carries no per-second DWM rent.
  SDL_SetWindowTitle(FWindow, PAnsiChar(SdlText(
    Format('%s [%s]', [FBaseTitle, FRendererBackend]))));
end;

procedure TGameHost.PumpEvents(const AApp: TGameApp);
var
  Event: TSdlEvent;
begin
  while SDL_PollEvent(@Event) <> 0 do
    case Event.EventType of
      SdlEventQuit:
        AApp.RequestQuit;
      SdlEventKeyDown:
        AApp.HandleKey(Event.Key.Keysym.Scancode, kaDown,
          Event.Key.IsRepeat <> 0);
      SdlEventKeyUp:
        AApp.HandleKey(Event.Key.Keysym.Scancode, kaUp, False);
      SdlEventMouseMotion:
        AApp.HandleMouseMove(Event.Motion.X, Event.Motion.Y);
      SdlEventMouseButtonDown:
        AApp.HandleMouseButton(Event.Button.Button, True);
      SdlEventMouseButtonUp:
        AApp.HandleMouseButton(Event.Button.Button, False);
    end;
end;

procedure TGameHost.UpdateFpsTitle(AFps, AWorstFrameMs,
  AWorstPresentMs: Integer);
begin
{$IFDEF TITLESTATS}
  // Instrument v3 (the title write itself measured ~0 and is cleared):
  // 'present' is the worst SDL_RenderPresent of the second. If present
  // tracks worst, the stall lives in the present path - DWM compositor
  // arbitration or the GPU dropping power states under a tiny windowed
  // load. If present stays ~0 while worst spikes, the stall is on our
  // side of the fence - split Update/Render next.
  SDL_SetWindowTitle(FWindow,
    PAnsiChar(SdlText(
      Format('%s - %d fps, worst %d ms (present %d ms) [%s]',
      [FBaseTitle, AFps, AWorstFrameMs, AWorstPresentMs,
       FRendererBackend]))));
{$ENDIF} // TITLESTATS
end;

// Waits until AFrameBudget seconds have passed since AFrameStartCounter.
// Plain SDL_Delay proved untrustworthy for pacing: Windows sleep jitter
// made frames arrive in a drunken rhythm (measured ~137 fps against a
// 120 cap) which the eye reads as stutter. So: sleep the coarse part,
// then spin-wait the exact tail on the performance counter.
procedure TGameHost.WaitOutFrameBudget(AFrameStartCounter: UInt64;
  AFrequency, AFrameBudget: Double);
const
  // Even at 1 ms timer resolution, Sleep can overshoot by a couple of
  // milliseconds; this reserve is spun exactly instead of slept.
  SpinReserveSeconds = 0.002;
var
  TargetCounter: UInt64;
begin
  TargetCounter := AFrameStartCounter +
    UInt64(Round(AFrameBudget * AFrequency));

  var RemainingSeconds :=
    (Int64(TargetCounter) - Int64(SDL_GetPerformanceCounter)) / AFrequency;
  if RemainingSeconds > SpinReserveSeconds then
    SDL_Delay(UInt32(Trunc((RemainingSeconds - SpinReserveSeconds) * 1000.0)));

  // The exact tail: burn the last ~2 ms watching the counter. Costs a
  // sliver of CPU, buys metronome-steady frame delivery. YieldProcessor
  // emits PAUSE: identical timing, but the core does not cook and a
  // hyperthread sibling is not starved (2 ms x 120 fps = a quarter of a
  // core - worth spinning politely, especially on throttling laptops).
  while SDL_GetPerformanceCounter < TargetCounter do
    YieldProcessor;
end;

procedure TGameHost.Run(const AApp: TGameApp);
var
  Frequency: Double;
  PreviousCounter: UInt64;
  Accumulator: Double;
  FixedDelta: Double;
  FpsFrames: Integer;
  FpsElapsed: Double;
  WorstFrameSeconds: Double;   // spike detector: stalls become numbers
  WorstPresentSeconds: Double; // the present path measured separately
  FrameBudget: Double; // target seconds per frame on the no-vsync path; 0 = uncapped
begin
  Frequency := SDL_GetPerformanceFrequency;
  FixedDelta := 1.0 / FConfig.TickRate;
  if FConfig.FpsCap > 0 then
    FrameBudget := 1.0 / FConfig.FpsCap
  else
    FrameBudget := 0.0;
  Accumulator := 0.0;
  PreviousCounter := SDL_GetPerformanceCounter;
  FpsFrames := 0;
  FpsElapsed := 0.0;
  WorstFrameSeconds := 0.0;
  WorstPresentSeconds := 0.0;

  // Default Windows timer granularity (up to ~15.6 ms) murders frame
  // pacing; ask for 1 ms while the game runs, hand it back on exit.
  timeBeginPeriod(1);
  try
    while not AApp.QuitRequested do
    begin
      var CurrentCounter := SDL_GetPerformanceCounter;
      var FrameSeconds := (CurrentCounter - PreviousCounter) / Frequency;
      PreviousCounter := CurrentCounter;
      if FrameSeconds > MaxFrameSeconds then
        FrameSeconds := MaxFrameSeconds;

      PumpEvents(AApp);

      Accumulator := Accumulator + FrameSeconds;
      while Accumulator >= FixedDelta do
      begin
        AApp.Update(FixedDelta);
        Accumulator := Accumulator - FixedDelta;
      end;

      AApp.Render(FRenderer, Accumulator / FixedDelta);
      var PresentStart := SDL_GetPerformanceCounter;
      SDL_RenderPresent(FRenderer);
      var PresentSeconds :=
        (SDL_GetPerformanceCounter - PresentStart) / Frequency;
      if PresentSeconds > WorstPresentSeconds then
        WorstPresentSeconds := PresentSeconds;

      Inc(FpsFrames);
      FpsElapsed := FpsElapsed + FrameSeconds;
      if FrameSeconds > WorstFrameSeconds then
        WorstFrameSeconds := FrameSeconds;
      if FpsElapsed >= 1.0 then
      begin
        // 'worst N ms' in the title turns invisible stalls into data:
        // a clean second reads ~budget, a hitch prints its own size.
        UpdateFpsTitle(FpsFrames, Round(WorstFrameSeconds * 1000.0),
          Round(WorstPresentSeconds * 1000.0));
        FpsFrames := 0;
        FpsElapsed := FpsElapsed - 1.0;
        WorstFrameSeconds := 0.0;
        WorstPresentSeconds := 0.0;
      end;

      // Frame pacing for the no-vsync path. Real vsync stutters badly on
      // multi-monitor setups with mixed refresh rates (windowed present
      // goes through the DWM compositor, which arbitrates between the
      // displays), so the loop paces itself against the frame budget.
      if not FConfig.Vsync then
      begin
        if FrameBudget > 0.0 then
          WaitOutFrameBudget(CurrentCounter, Frequency, FrameBudget)
        else
          SDL_Delay(1); // uncapped (fpsCap 0): diagnostics mode, stay polite to the CPU
      end;
    end;
  finally
    timeEndPeriod(1);
  end;
end;

end.
