object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'include'
  ClientHeight = 668
  ClientWidth = 770
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = #24494#36719#38597#40657
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    770
    668)
  PixelsPerInch = 120
  TextHeight = 19
  object PageControl1: TPageControl
    Left = 8
    Top = 47
    Width = 754
    Height = 612
    ActivePage = TabSheet1
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 0
    object TabSheet1: TTabSheet
      Caption = #28304#25991#20214
      object E_In: TMemo
        Left = 0
        Top = 0
        Width = 746
        Height = 578
        Align = alClient
        Lines.Strings = (
          'E_In')
        ScrollBars = ssBoth
        TabOrder = 0
      end
      object Button1: TButton
        Left = 384
        Top = -56
        Width = 75
        Height = 25
        Caption = 'Button1'
        TabOrder = 1
      end
      object Button2: TButton
        Left = 400
        Top = -64
        Width = 75
        Height = 25
        Caption = 'Button2'
        TabOrder = 2
      end
    end
    object TabSheet2: TTabSheet
      Caption = #36755#20986#20869#23481
      ImageIndex = 1
      object E_Out: TMemo
        Left = 0
        Top = 0
        Width = 746
        Height = 578
        Align = alClient
        Lines.Strings = (
          'Memo1')
        ScrollBars = ssBoth
        TabOrder = 0
      end
    end
    object TabSheet3: TTabSheet
      Caption = 'TabSheet3'
      ImageIndex = 2
      object Memo3: TMemo
        Left = 0
        Top = 0
        Width = 746
        Height = 578
        Align = alClient
        Lines.Strings = (
          'Memo1')
        TabOrder = 0
      end
    end
  end
  object Open: TButton
    Left = 8
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Open'
    TabOrder = 1
    OnClick = OpenClick
  end
  object Button3: TButton
    Left = 170
    Top = 8
    Width = 97
    Height = 25
    Caption = 'load && parse'
    TabOrder = 2
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 273
    Top = 8
    Width = 96
    Height = 25
    Caption = 'BentchMark'
    TabOrder = 3
    OnClick = Button4Click
  end
  object Parse: TButton
    Left = 89
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Parse'
    TabOrder = 4
    OnClick = ParseClick
  end
  object BitBtn1: TBitBtn
    Left = 392
    Top = 10
    Width = 75
    Height = 25
    Caption = 'BitBtn1'
    TabOrder = 5
    OnClick = BitBtn1Click
  end
  object BitBtn2: TBitBtn
    Left = 512
    Top = 10
    Width = 75
    Height = 25
    Caption = 'BitBtn2'
    TabOrder = 6
    OnClick = BitBtn2Click
  end
  object BitBtn3: TBitBtn
    Left = 608
    Top = 16
    Width = 75
    Height = 25
    Caption = 'BitBtn3'
    TabOrder = 7
    OnClick = BitBtn3Click
  end
  object FileOpenDialog1: TFileOpenDialog
    FavoriteLinks = <>
    FileTypes = <
      item
        DisplayName = '*.htm'
        FileMask = '*.htm'
      end
      item
        DisplayName = '*.html'
        FileMask = '*.html'
      end
      item
        DisplayName = '*.*'
        FileMask = '*.*'
      end>
    Options = []
    Left = 444
    Top = 110
  end
  object NetHTTPClient1: TNetHTTPClient
    Asynchronous = False
    ConnectionTimeout = 60000
    ResponseTimeout = 60000
    HandleRedirects = True
    AllowCookies = True
    UserAgent = 'Embarcadero URI Client/1.0'
    Left = 532
    Top = 205
  end
end
