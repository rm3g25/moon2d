object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Moon 2D - TitleCard'
  ClientHeight = 740
  ClientWidth = 1080
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  TextHeight = 15
  object SidePanel: TPanel
    Left = 0
    Top = 0
    Width = 400
    Height = 740
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 0
    object TextLabel: TLabel
      Left = 12
      Top = 10
      Width = 200
      Height = 15
      Caption = 'Card text - line breaks are sacred'
    end
    object AspectLabel: TLabel
      Left = 12
      Top = 240
      Width = 60
      Height = 15
      Caption = 'Card size'
    end
    object ScaleLabel: TLabel
      Left = 12
      Top = 292
      Width = 40
      Height = 15
      Caption = 'Scale'
    end
    object MarginLabel: TLabel
      Left = 12
      Top = 348
      Width = 130
      Height = 15
      Caption = 'Margin, % per side'
    end
    object CenterLabel: TLabel
      Left = 12
      Top = 380
      Width = 180
      Height = 15
      Caption = 'Optical center, % of height'
    end
    object SpacingLabel: TLabel
      Left = 12
      Top = 412
      Width = 180
      Height = 15
      Caption = 'Line step, % of cap height'
    end
    object StatusLabel: TLabel
      Left = 12
      Top = 524
      Width = 376
      Height = 140
      Anchors = [akLeft, akTop, akRight, akBottom]
      AutoSize = False
      Caption = ''
      WordWrap = True
    end
    object TextMemo: TMemo
      Left = 12
      Top = 28
      Width = 376
      Height = 200
      Anchors = [akLeft, akTop, akRight]
      Lines.Strings = (
        'It ran on a timer that'
        'fired every twenty'
        'milliseconds.')
      ScrollBars = ssVertical
      TabOrder = 0
      OnChange = SettingsChanged
    end
    object AspectCombo: TComboBox
      Left = 12
      Top = 258
      Width = 376
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      Style = csDropDownList
      TabOrder = 1
      OnChange = SettingsChanged
    end
    object ScaleCombo: TComboBox
      Left = 12
      Top = 310
      Width = 376
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      Style = csDropDownList
      TabOrder = 2
      OnChange = SettingsChanged
    end
    object MarginEdit: TEdit
      Left = 250
      Top = 344
      Width = 138
      Height = 23
      Anchors = [akTop, akRight]
      TabOrder = 3
      Text = '15'
      OnChange = SettingsChanged
    end
    object CenterEdit: TEdit
      Left = 250
      Top = 376
      Width = 138
      Height = 23
      Anchors = [akTop, akRight]
      TabOrder = 4
      Text = '45'
      OnChange = SettingsChanged
    end
    object SpacingEdit: TEdit
      Left = 250
      Top = 408
      Width = 138
      Height = 23
      Anchors = [akTop, akRight]
      TabOrder = 5
      Text = '160'
      OnChange = SettingsChanged
    end
    object BlackBackgroundCheck: TCheckBox
      Left = 12
      Top = 444
      Width = 376
      Height = 17
      Caption = 'Black background (otherwise transparent alpha)'
      TabOrder = 6
      OnClick = SettingsChanged
    end
    object WrapCheck: TCheckBox
      Left = 12
      Top = 468
      Width = 376
      Height = 17
      Caption = 'Emergency word wrap when a line does not fit'
      TabOrder = 7
      OnClick = SettingsChanged
    end
    object UniformBatchCheck: TCheckBox
      Left = 12
      Top = 492
      Width = 376
      Height = 17
      Caption = 'One scale for the whole batch'
      TabOrder = 8
    end
    object RenderButton: TButton
      Left = 12
      Top = 686
      Width = 120
      Height = 30
      Anchors = [akLeft, akBottom]
      Caption = 'Render'
      TabOrder = 9
      OnClick = RenderButtonClick
    end
    object SaveButton: TButton
      Left = 140
      Top = 686
      Width = 120
      Height = 30
      Anchors = [akLeft, akBottom]
      Caption = 'Save PNG...'
      TabOrder = 10
      OnClick = SaveButtonClick
    end
    object BatchButton: TButton
      Left = 268
      Top = 686
      Width = 120
      Height = 30
      Anchors = [akLeft, akBottom]
      Caption = 'Batch...'
      TabOrder = 11
      OnClick = BatchButtonClick
    end
  end
  object PreviewPanel: TPanel
    Left = 400
    Top = 0
    Width = 680
    Height = 740
    Align = alClient
    BevelOuter = bvNone
    Color = clBlack
    ParentBackground = False
    TabOrder = 1
    object PreviewImage: TImage
      Left = 0
      Top = 0
      Width = 680
      Height = 740
      Align = alClient
      Center = True
    end
  end
  object SavePngDialog: TSaveDialog
    DefaultExt = 'png'
    Filter = 'PNG image|*.png'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing]
    Title = 'Save title card'
    Left = 40
    Top = 640
  end
  object OpenTextDialog: TOpenDialog
    Filter = 'Text file|*.txt'
    Options = [ofHideReadOnly, ofFileMustExist, ofEnableSizing]
    Title = 'Batch: cards separated by blank lines'
    Left = 104
    Top = 640
  end
end
