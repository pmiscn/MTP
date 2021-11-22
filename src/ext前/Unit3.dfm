object Form3: TForm3
  Left = 0
  Top = 0
  Caption = 'Form3'
  ClientHeight = 625
  ClientWidth = 814
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    814
    625)
  PixelsPerInch = 96
  TextHeight = 13
  object BitBtn1: TBitBtn
    Left = 8
    Top = 8
    Width = 75
    Height = 25
    Caption = 'BitBtn1'
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object PageControl1: TPageControl
    Left = 8
    Top = 70
    Width = 798
    Height = 513
    ActivePage = TabSheet2
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 1
    object TabSheet1: TTabSheet
      Caption = 'TabSheet1'
      object Memo1: TMemo
        Left = 0
        Top = 0
        Width = 790
        Height = 485
        Align = alClient
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Courier New'
        Font.Style = []
        Lines.Strings = (
          ''
          '<html xmlns="http://www.w3.org/1999/xhtml">'
          '<head>'
          
            '    <meta http-equiv="Content-Type" content="text/html; charset=' +
            'utf-8" />'
          '    <title><@Page.Title%></title>  '
          '    <style type="text/css">'
          '        h1 {color: red;}         '
          '        .bd{width:100%;border:1px solid red; }'
          '    </style>'
          '</head>'
          '<body>   '
          ''
          '    <%each datapath='#39#39'%> '
          '        <%if(@Data.ID=="1")%> '
          '            <div><ul><%@Score[0]%></ul></div>  '
          '        <%elseif(@Data.ID=="2")%> '
          '            <div><ul><%@Score[0]%></ul></div>'
          '        <%else%>'
          '        <%endif%> '
          '    <%endeach%>'
          ''
          '    </body>')
        ParentFont = False
        ScrollBars = ssBoth
        TabOrder = 0
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'TabSheet2'
      ImageIndex = 1
      ExplicitHeight = 501
      object Memo2: TMemo
        Left = 0
        Top = 0
        Width = 790
        Height = 485
        Align = alClient
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Courier New'
        Font.Style = []
        ParentFont = False
        ScrollBars = ssBoth
        TabOrder = 0
        ExplicitHeight = 501
      end
    end
  end
  object BitBtn2: TBitBtn
    Left = 207
    Top = 8
    Width = 75
    Height = 25
    Caption = 'file'
    TabOrder = 2
    OnClick = BitBtn2Click
  end
  object BitBtn3: TBitBtn
    Left = 288
    Top = 8
    Width = 75
    Height = 25
    Caption = 'QExpression'
    TabOrder = 3
    OnClick = BitBtn3Click
  end
  object BitBtn4: TBitBtn
    Left = 369
    Top = 8
    Width = 75
    Height = 25
    Caption = 'KeyValue'
    TabOrder = 4
    OnClick = BitBtn4Click
  end
  object BitBtn5: TBitBtn
    Left = 450
    Top = 8
    Width = 75
    Height = 25
    Caption = 'BitBtn5'
    TabOrder = 5
    OnClick = BitBtn5Click
  end
  object BitBtn6: TBitBtn
    Left = 89
    Top = 8
    Width = 75
    Height = 25
    Caption = 'GetAllNode'
    TabOrder = 6
    OnClick = BitBtn6Click
  end
  object Button1: TButton
    Left = 584
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 7
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 8
    Top = 39
    Width = 75
    Height = 25
    Caption = 'Button2'
    TabOrder = 8
  end
  object BitBtn7: TBitBtn
    Left = 207
    Top = 39
    Width = 75
    Height = 25
    Caption = 'file'
    TabOrder = 9
    OnClick = BitBtn7Click
  end
  object ADODataSet1: TADODataSet
    Parameters = <>
    Left = 488
    Top = 56
  end
  object NetHTTPClient1: TNetHTTPClient
    Asynchronous = False
    ConnectionTimeout = 60000
    ResponseTimeout = 60000
    HandleRedirects = True
    AllowCookies = True
    UserAgent = 'Embarcadero URI Client/1.0'
    Left = 376
    Top = 40
  end
end
