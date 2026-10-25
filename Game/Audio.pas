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
{$I ..\Moon2D.inc}

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

  // Mix_Chunk of SDL_mixer.h: the samples decoded whole, in the mixer's
  // own format
  TMixChunk = record
    Allocated: Integer;
    Samples: PByte;
    ByteLength: UInt32;
    Volume: Byte;
  end;
  PMixChunk = ^TMixChunk;
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
// The format the mixer was opened with; 0 when it is not open
function Mix_QuerySpec(out AFrequency: Integer; out AFormat: UInt16;
  out AChannels: Integer): Integer; cdecl;
  external MixerLib name 'Mix_QuerySpec' delayed;

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
function Mix_HaltChannel(AChannel: Integer): Integer; cdecl;
  external MixerLib name 'Mix_HaltChannel' delayed;
procedure Mix_Pause(AChannel: Integer); cdecl;
  external MixerLib name 'Mix_Pause' delayed;
procedure Mix_Resume(AChannel: Integer); cdecl;
  external MixerLib name 'Mix_Resume' delayed;
// Non-zero while the channel plays, paused or not
function Mix_Playing(AChannel: Integer): Integer; cdecl;
  external MixerLib name 'Mix_Playing' delayed;
// The chunk the channel plays or has played last
function Mix_GetChunk(AChannel: Integer): PMixChunk; cdecl;
  external MixerLib name 'Mix_GetChunk' delayed;

function Mix_LoadMUS(const AFileName: PAnsiChar): PMixMusic; cdecl;
  external MixerLib name 'Mix_LoadMUS' delayed;
procedure Mix_FreeMusic(AMusic: PMixMusic); cdecl;
  external MixerLib name 'Mix_FreeMusic' delayed;
function Mix_PlayMusic(AMusic: PMixMusic; ALoops: Integer): Integer; cdecl;
  external MixerLib name 'Mix_PlayMusic' delayed;
function Mix_FadeInMusic(AMusic: PMixMusic; ALoops, AMilliseconds: Integer):
  Integer; cdecl; external MixerLib name 'Mix_FadeInMusic' delayed;
function Mix_HaltMusic: Integer; cdecl;
  external MixerLib name 'Mix_HaltMusic' delayed;
function Mix_VolumeMusic(AVolume: Integer): Integer; cdecl;
  external MixerLib name 'Mix_VolumeMusic' delayed;
// Halts the music once it has faded out
function Mix_FadeOutMusic(AMilliseconds: Integer): Integer; cdecl;
  external MixerLib name 'Mix_FadeOutMusic' delayed;
// Non-zero while the music plays, a fade-out included
function Mix_PlayingMusic: Integer; cdecl;
  external MixerLib name 'Mix_PlayingMusic' delayed;
{$WARN SYMBOL_PLATFORM DEFAULT}

type
  TMusicMode = (mmLoop, mmOnce);

  // A sound the game keeps hold of: the channel it plays on and what it
  // plays. Channel -1 - it never started.
  THeldSound = record
    Channel: Integer;
    Chunk: PMixChunk;
  end;

  // A track waiting for the one before it to fade out; FileName '' - none
  TQueuedTrack = record
    FileName: string;
    Mode: TMusicMode;
    FadeSeconds: Single;
  end;

  // One instance owns the mixer for the whole game. Two loading creeds:
  // WAV one-shots load strictly (a bad name must blow up at startup, not
  // mid-boss), music streams load leniently (a missing track skips
  // silently - the show goes on without an orchestra).
  TSoundBank = class
  private
    FEnabled: Boolean;
    FMusicMuted: Boolean;
    FMusicLevel: Single; // 0..1 of the full volume
    FSounds: TDictionary<string, PMixChunk>;
    // Tracks of the music folder played as sounds; nil for a missing one
    FTracks: TDictionary<string, PMixChunk>;
    FBytesPerSecond: Integer; // of the decoded samples
    FMusic: PMixMusic;
    FMusicName: string; // the track FMusic holds; '' with none
    FNextTrack: TQueuedTrack;
    FSoundsDir: string;
    FMusicDir: string;
    function ChunkOf(const AFileName: string): PMixChunk;
    function PlayChunkHeld(AChunk: PMixChunk): THeldSound;
    function StillHeld(const ASound: THeldSound): Boolean;
    procedure ApplyMusicVolume;
  public
    constructor Create(const ASoundsDir, AMusicDir: string);
    destructor Destroy; override;
    procedure Load(const AFileName: string);
    procedure Play(const AFileName: string);
    // Plays as Play does and keeps hold of the channel, so the sound can
    // be paused and stopped before its end
    function PlayHeld(const AFileName: string): THeldSound;
    // A held sound that has ended, and whose channel another sound has
    // taken since, is left alone by all three
    procedure StopHeld(const ASound: THeldSound);
    procedure PauseHeld(const ASound: THeldSound);
    procedure ResumeHeld(const ASound: THeldSound);
    // How long a held sound plays from its start; 0 for one that never
    // started
    function SecondsOf(const ASound: THeldSound): Single;
    // A track of the music folder decoded whole, to be played as a sound.
    // It loads as music does, leniently: a missing track is no track.
    procedure LoadTrack(const AFileName: string);
    // The track once, on a sound channel and held: the music channel
    // stays free for the next track to fade in over its end
    function PlayTrackHeld(const AFileName: string): THeldSound;
    // The music at a share of its volume, 0..1; it stays at it through
    // track changes. Muting outranks it.
    procedure SetMusicLevel(ALevel: Single);
    // AFadeSeconds above 0 brings the track in from silence
    procedure PlayMusic(const AFileName: string; AMode: TMusicMode;
      AFadeSeconds: Single = 0);
    // The track that plays fades out over AFadeOutSeconds, then AFileName
    // starts as PlayMusic starts it. With nothing playing it starts at
    // once; a track already playing is left alone - there is nothing to
    // hand over.
    procedure HandOverMusic(const AFileName: string; AMode: TMusicMode;
      AFadeOutSeconds, AFadeInSeconds: Single);
    // Starts the handed-over track once the one before it is silent; the
    // game calls it every tick
    procedure Tick;
    // Drops a track waiting for a fade-out as well
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

const
  MillisecondsPerSecond = 1000;

function MixerBytesPerSecond: Integer;
const
  FormatBitsMask = $FF; // SDL_AUDIO_BITSIZE
var
  Frequency: Integer;
  Format: UInt16;
  Channels: Integer;
begin
  if Mix_QuerySpec(Frequency, Format, Channels) = 0 then
    Exit(0);
  Result := Frequency * Channels * ((Format and FormatBitsMask) div 8);
end;

constructor TSoundBank.Create(const ASoundsDir, AMusicDir: string);
const
  Frequency = 44100;
  StereoChannels = 2;
  // Mixer buffer in sample frames: 1024 @ 44100 Hz = ~23 ms of latency.
  // A gunshot must not lag behind the muzzle flash.
  ChunkFrames = 1024;
  // The chain gun alone holds sixteen, at moments seventeen - a 2.4 s
  // shot every 5 ticks - and a sound with no free channel is dropped in
  // silence. The rest are the world's: blasts, deaths, the henshin sting
  MixChannels = 32;
begin
  inherited Create;
  FSoundsDir := IncludeTrailingPathDelimiter(ASoundsDir);
  FMusicDir := IncludeTrailingPathDelimiter(AMusicDir);
  FSounds := TDictionary<string, PMixChunk>.Create;
  FTracks := TDictionary<string, PMixChunk>.Create;
  FMusicLevel := 1;
  try
    // Delay-loaded import: a missing SDL2_mixer.dll surfaces exactly
    // here, as a catchable exception instead of a startup error box
    FEnabled := Mix_OpenAudio(Frequency, MixDefaultFormat, StereoChannels,
      ChunkFrames) = 0;
  except
    FEnabled := False; // no DLL - the game plays on, silently
  end;
  if not FEnabled then
    Exit;
  Mix_AllocateChannels(MixChannels);
  FBytesPerSecond := MixerBytesPerSecond;
end;

destructor TSoundBank.Destroy;
begin
  if FEnabled then
  begin
    StopMusic;
    for var Chunk in FSounds.Values do
      Mix_FreeChunk(Chunk);
    for var Chunk in FTracks.Values do
      if Chunk <> nil then
        Mix_FreeChunk(Chunk);
    Mix_CloseAudio;
  end;
  FTracks.Free;
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
begin
  PlayHeld(AFileName);
end;

// Startup preloading is a warm-up, not a contract: an unknown name loads
// on first use, and a genuinely missing file still fails loudly
function TSoundBank.ChunkOf(const AFileName: string): PMixChunk;
begin
  if not FSounds.TryGetValue(AFileName, Result) then
  begin
    Load(AFileName);
    Result := FSounds[AFileName];
  end;
end;

function TSoundBank.PlayChunkHeld(AChunk: PMixChunk): THeldSound;
const
  AnyFreeChannel = -1;
  PlayOnce = 0;
  NoTimeLimit = -1;
begin
  Result.Channel := -1;
  Result.Chunk := AChunk;
  if not FEnabled or (AChunk = nil) then
    Exit;
  Result.Channel := Mix_PlayChannelTimed(AnyFreeChannel, AChunk, PlayOnce,
    NoTimeLimit);
end;

function TSoundBank.PlayHeld(const AFileName: string): THeldSound;
begin
  if FEnabled then
    Result := PlayChunkHeld(ChunkOf(AFileName))
  else
    Result := PlayChunkHeld(nil);
end;

procedure TSoundBank.LoadTrack(const AFileName: string);
begin
  if not FEnabled then
    Exit;
  if FTracks.ContainsKey(AFileName) then
    Exit;
  FTracks.Add(AFileName, Mix_LoadWAV_RW(
    SDL_RWFromFile(PAnsiChar(SdlText(FMusicDir + AFileName)), 'rb'), 1));
end;

function TSoundBank.PlayTrackHeld(const AFileName: string): THeldSound;
begin
  LoadTrack(AFileName);
  var Chunk: PMixChunk := nil;
  FTracks.TryGetValue(AFileName, Chunk);
  Result := PlayChunkHeld(Chunk);
end;

function TSoundBank.SecondsOf(const ASound: THeldSound): Single;
begin
  if (ASound.Channel < 0) or (FBytesPerSecond = 0) then
    Exit(0);
  Result := ASound.Chunk.ByteLength / FBytesPerSecond;
end;

function TSoundBank.StillHeld(const ASound: THeldSound): Boolean;
begin
  Result := FEnabled and (ASound.Channel >= 0) and
    (Mix_Playing(ASound.Channel) <> 0) and
    (Mix_GetChunk(ASound.Channel) = ASound.Chunk);
end;

procedure TSoundBank.StopHeld(const ASound: THeldSound);
begin
  if StillHeld(ASound) then
    Mix_HaltChannel(ASound.Channel);
end;

procedure TSoundBank.PauseHeld(const ASound: THeldSound);
begin
  if StillHeld(ASound) then
    Mix_Pause(ASound.Channel);
end;

procedure TSoundBank.ResumeHeld(const ASound: THeldSound);
begin
  if StillHeld(ASound) then
    Mix_Resume(ASound.Channel);
end;

procedure TSoundBank.SetMusicLevel(ALevel: Single);
begin
  if ALevel = FMusicLevel then
    Exit;
  FMusicLevel := ALevel;
  ApplyMusicVolume;
end;

// Music volume is global mixer state: it survives Halt/Load/Play, so a
// track change while muted stays silent until the toggle flips back
procedure TSoundBank.ApplyMusicVolume;
const
  MixMaxVolume = 128; // MIX_MAX_VOLUME of SDL_mixer.h
begin
  if not FEnabled then
    Exit;
  if FMusicMuted then
    Mix_VolumeMusic(0)
  else
    Mix_VolumeMusic(Round(MixMaxVolume * FMusicLevel));
end;

procedure TSoundBank.PlayMusic(const AFileName: string; AMode: TMusicMode;
  AFadeSeconds: Single);
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

  FMusicName := AFileName;
  var Loops := PlayThroughOnce;
  if AMode = mmLoop then
    Loops := LoopForever;
  if AFadeSeconds > 0 then
    Mix_FadeInMusic(FMusic, Loops, Round(AFadeSeconds * MillisecondsPerSecond))
  else
    Mix_PlayMusic(FMusic, Loops);
end;

procedure TSoundBank.HandOverMusic(const AFileName: string;
  AMode: TMusicMode; AFadeOutSeconds, AFadeInSeconds: Single);
begin
  if not FEnabled then
    Exit;
  if AFileName = '' then
    Exit;

  var Playing := (FMusic <> nil) and (Mix_PlayingMusic <> 0);
  if not Playing then
  begin
    PlayMusic(AFileName, AMode, AFadeInSeconds);
    Exit;
  end;
  if (FNextTrack.FileName = '') and SameText(AFileName, FMusicName) then
    Exit;

  FNextTrack.FileName := AFileName;
  FNextTrack.Mode := AMode;
  FNextTrack.FadeSeconds := AFadeInSeconds;
  Mix_FadeOutMusic(Round(AFadeOutSeconds * MillisecondsPerSecond));
end;

procedure TSoundBank.Tick;
begin
  if FNextTrack.FileName = '' then
    Exit;
  if Mix_PlayingMusic <> 0 then
    Exit;
  var Next := FNextTrack;
  PlayMusic(Next.FileName, Next.Mode, Next.FadeSeconds);
end;

procedure TSoundBank.StopMusic;
begin
  if not FEnabled then
    Exit;
  FNextTrack := Default(TQueuedTrack);
  if FMusic = nil then
    Exit;
  Mix_HaltMusic;
  Mix_FreeMusic(FMusic);
  FMusic := nil;
  FMusicName := '';
end;

procedure TSoundBank.ToggleMusicMuted;
begin
  if not FEnabled then
    Exit;
  FMusicMuted := not FMusicMuted;
  ApplyMusicVolume;
end;

end.
