{
  Hud.Score - the score display, one class per era, the twin of
  Hud.Health. The game holds a TScoreHud and never asks which one; the
  composition root picks the class when a level loads.

  TScoreText is the 2008 display: 'Score: N' in the small font at the
  top-right corner. The remake's display lives in Hud.Charge.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Hud.Score;
{$I Moon2D.inc}

interface

uses
  Render.Font, Game.Bonus;

type
  TScoreHud = class abstract
  public
    // Once per logic tick: the score, the kill streak and the reward
    // held (bkNone when the slot is empty), all as of now
    procedure Tick(AScore, AStreak: Integer; ABonus: TBonusKind);
      virtual; abstract;
    procedure Draw; virtual; abstract;
  end;

  TScoreText = class(TScoreHud)
  private
    FFont: TMoonFont;
    FScreenWidth: Integer;
    FScore: Integer;
  public
    constructor Create(const AFont: TMoonFont; AScreenWidth: Integer);
    procedure Tick(AScore, AStreak: Integer; ABonus: TBonusKind); override;
    procedure Draw; override;
  end;

implementation

uses
  System.SysUtils, Localization;

const
  ScoreMargin = 6; // top-right corner, clear of the ticker lane

constructor TScoreText.Create(const AFont: TMoonFont; AScreenWidth: Integer);
begin
  inherited Create;
  FFont := AFont;
  FScreenWidth := AScreenWidth;
end;

procedure TScoreText.Tick(AScore, AStreak: Integer; ABonus: TBonusKind);
begin
  FScore := AScore;
end;

procedure TScoreText.Draw;
begin
  var Text := Format(Tr(SScoreFmt), [FScore]);
  FFont.DrawSmall(Text, FScreenWidth - FFont.SmallTextWidth(Text) - ScoreMargin,
    ScoreMargin);
end;

end.
