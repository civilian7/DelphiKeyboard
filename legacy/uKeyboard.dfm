object frmKeyboard: TfrmKeyboard
  Left = 544
  Top = 241
  BorderStyle = bsNone
  Caption = 'frmKeyboard'
  ClientHeight = 378
  ClientWidth = 800
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnMouseDown = FormMouseDown
  OnPaint = FormPaint
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object edKeyboard: TEdit
    Left = 126
    Top = 45
    Width = 424
    Height = 27
    BorderStyle = bsNone
    Color = 16119285
    Font.Charset = ANSI_CHARSET
    Font.Color = clGray
    Font.Height = -24
    Font.Name = #44404#47548
    Font.Style = [fsBold]
    ImeName = 'Microsoft Office IME 2007'
    ParentFont = False
    TabOrder = 0
    OnKeyPress = edKeyboardKeyPress
  end
  object Button2: TButton
    Left = 712
    Top = 448
    Width = 75
    Height = 25
    Caption = 'Button2'
    TabOrder = 1
  end
  object ApplicationEvents1: TApplicationEvents
    OnMessage = ApplicationEvents1Message
    Left = 176
    Top = 8
  end
end
