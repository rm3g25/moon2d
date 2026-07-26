{
  Audio - SDL2_mixer bindings + the game's sound bank.

  Retires the whole 2008 audio stack at once: snd_main.pas (hand-rolled
  DirectSound 5 for WAV one-shots), RoarMusic*/RoarOgg (WaveOut streaming)
  and their three DLLs (ogg.dll, vorbis.dll, vorbisfile.dll). SDL2_mixer
  decodes both WAV and OGG itself, so one SDL2_mixer.dll next to SDL2.dll
  replaces four legacy modules and three libraries. Assets stay untouched.

  Imports are delay-loaded: without the DLL the constructor catches the
  load failure and the bank goes permanently silent - a game with no
  sound card beats a game with no game.

  Moon 2D remake. Requires SDL2_mixer 2.6+ (Vorbis decoder built in).
}
unit Audio;

interface

uses
  System.SysUtils, System.Generics.Collections, Sdl2.Core;

const
  MixerLib = 'SDL2_mixer.dll';

  // AUDIO_S16LSB of SDL: signed 16-bit little-endian - the format every
  // 2008 asset already lives in
  MixDefaultFormat = $8010;

type
  EAudioError = class(Exception);

  PMixChunk = Pointer;
  PMixMusic = Pointer;

// 'delayed' loads SDL2_mixer.dll on first call, not at startup - a
// deliberate Windows-only choice (the game ships the DLL beside the exe).
// W1002 flags it as non-portable; we know, and this whole subsystem is
// Windows-bound anyway. Scoped tight: restored right after the imports.
{$WARN SYMBOL_PLATFORM OFF}
function Mix_OpenAudio(AFrequency: Integer; AFormat: UInt16;
  AChannels, AChunkFrames: Integer): Integer; cdecl;
  external MixerLib name 'Mix_OpenAudio' delayed;
procedure Mix_CloseAudio; cdecl;
  external MixerLib name 'Mix_CloseAudio' delayed;
function Mix_AllocateChannels(ACount: Integer): Integer; cdecl;
  external MixerLib name 'Mix_AllocateChannels' delayed;

// The C header wraps this into the Mix_LoadWAV macro; the macro does not
// exist in the DLL, the _RW form does - in every SDL2_mixer version ever
function Mix_LoadWAV_RW(ASrc: PSdlRWops; AFreeSrc: Integer): PMixChunk;
  cdecl; external MixerLib name 'Mix_LoadWAV_RW' delayed;
procedure Mix_FreeChunk(AChunk: PMixChunk); cdecl;
  external MixerLib name 'Mix_FreeChunk' delayed;
// Same story: Mix_PlayChannel is a macro over this
function Mix_PlayChannelTimed(AChannel: Integer; AChunk: PMixChunk;
  ALoops, ATicks: Integer): Integer; cdecl;
  external MixerLib name 'Mix_PlayChannelTimed' delayed;

function Mix_LoadMUS(const AFileName: PAnsiChar): PMixMusic; cdecl;
  external MixerLib name 'Mix_LoadMUS' delayed;
procedure Mix_FreeMusic(AMusic: PMixMusic); cdecl;
  external MixerLib name 'Mix_FreeMusic' delayed;
function Mix_PlayMusic(AMusic: PMixMusic; ALoops: Integer): Integer; cdecl;
  external MixerLib name 'Mix_PlayMusic' delayed;
function Mix_HaltMusic: Integer; cdecl;
  external MixerLib name 'Mix_HaltMusic' delayed;
function Mix_VolumeMusic(AVolume: Integer): Integer; cdecl;
  external MixerLib name 'Mix_VolumeMusic' delayed;
{$WARN SYMBOL_PLATFORM DEFAULT}

type
  TMusicMode = (mmLoop, mmOnce);

  // One instance owns the mixer for the whole game. Two loading creeds:
  // WAV one-shots load strictly (a bad name must blow up at startup, not
  // mid-boss), music streams load leniently (a missing track skips
  // silently - the show goes on without an orchestra).
  TSoundBank = class
  private
    FEnabled: Boolean;
    FMusicMuted: Boolean;
    FSounds: TDictionary<string, PMixChunk>;
    FMusic: PMixMusic;
    FSoundsDir: string;
    FMusicDir: string;
  public
    constructor Create(const ASoundsDir, AMusicDir: string);
    destructor Destroy; override;
    procedure Load(const AFileName: string);
    procedure Play(const AFileName: string);
    procedure PlayMusic(const AFileName: string; AMode: TMusicMode);
    procedure StopMusic;
    // Mutes the music channel at the mixer, effects untouched. The game
    // keeps switching tracks normally underneath - unmuting resumes
    // whatever the current screen ordered, no bookkeeping needed.
    procedure ToggleMusicMuted;
    property Enabled: Boolean read FEnabled;
    property MusicMuted: Boolean read FMusicMuted;
  end;

implementation

resourcestring
  SSoundLoadFailed = 'Sound failed to load: %s (%s)';

constructor TSoundBank.Create(const ASoundsDir, AMusicDir: string);
const
  Frequency = 44100;
  StereoChannels = 2;
  // Mixer buffer in sample frames: 1024 @ 44100 Hz = ~23 ms of latency.
  // A gunshot must not lag behind the muzzle flash.
  ChunkFrames = 1024;
  // Henshin double-sting plus a chorus of dying gravels, with headroom
  MixChannels = 16;
begin
  inherited Create;
  FSoundsDir := IncludeTrailingPathDelimiter(ASoundsDir);
  FMusicDir := IncludeTrailingPathDelimiter(AMusicDir);
  FSounds := TDictionary<string, PMixChunk>.Create;
  try
    // Delay-loaded import: a missing SDL2_mixer.dll surfaces exactly
    // here, as a catchable exception instead of a startup error box
    FEnabled := Mix_OpenAudio(Frequency, MixDefaultFormat, StereoChannels,
      ChunkFrames) = 0;
  except
    FEnabled := False; // no DLL - the game plays on, silently
  end;
  if FEnabled then
    Mix_AllocateChannels(MixChannels);
end;

destructor TSoundBank.Destroy;
begin
  if FEnabled then
  begin
    StopMusic;
    for var Chunk in FSounds.Values do
      Mix_FreeChunk(Chunk);
    Mix_CloseAudio;
  end;
  FSounds.Free;
  inherited;
end;

procedure TSoundBank.Load(const AFileName: string);
begin
  if not FEnabled then
    Exit;
  if FSounds.ContainsKey(AFileName) then
    Exit;

  var Chunk := Mix_LoadWAV_RW(
    SDL_RWFromFile(PAnsiChar(SdlText(FSoundsDir + AFileName)), 'rb'), 1);
  if Chunk = nil then
    raise EAudioError.CreateFmt(SSoundLoadFailed,
      [FSoundsDir + AFileName, SdlErrorText]);
  FSounds.Add(AFileName, Chunk);
end;

procedure TSoundBank.Play(const AFileName: string);
const
  AnyFreeChannel = -1;
  PlayOnce = 0;
  NoTimeLimit = -1;
var
  Chunk: PMixChunk;
begin
  if not FEnabled then
    Exit;
  // Startup preloading is a warm-up, not a contract: an unknown name
  // loads on first use, and a genuinely missing file still fails loudly
  if not FSounds.TryGetValue(AFileName, Chunk) then
  begin
    Load(AFileName);
    Chunk := FSounds[AFileName];
  end;
  Mix_PlayChannelTimed(AnyFreeChannel, Chunk, PlayOnce, NoTimeLimit);
end;

procedure TSoundBank.PlayMusic(const AFileName: string; AMode: TMusicMode);
const
  LoopForever = -1;
  PlayThroughOnce = 1;
begin
  if not FEnabled then
    Exit;
  if AFileName = '' then
    Exit; // a level without a track plays in silence, deliberately

  StopMusic;
  FMusic := Mix_LoadMUS(PAnsiChar(SdlText(FMusicDir + AFileName)));
  if FMusic = nil then
    Exit; // a missing track must not kill the run - the game goes quiet

  if AMode = mmLoop then
    Mix_PlayMusic(FMusic, LoopForever)
  else
    Mix_PlayMusic(FMusic, PlayThroughOnce);
end;

procedure TSoundBank.StopMusic;
begin
  if not FEnabled then
    Exit;
  if FMusic = nil then
    Exit;
  Mix_HaltMusic;
  Mix_FreeMusic(FMusic);
  FMusic := nil;
end;

procedure TSoundBank.ToggleMusicMuted;
const
  MixMaxVolume = 128; // MIX_MAX_VOLUME of SDL_mixer.h
begin
  if not FEnabled then
    Exit;
  FMusicMuted := not FMusicMuted;
  // Music volume is global mixer state: it survives Halt/Load/Play, so
  // a track change while muted stays silent until the toggle flips back
  if FMusicMuted then
    Mix_VolumeMusic(0)
  else
    Mix_VolumeMusic(MixMaxVolume);
end;

end.
