object MainForm: TMainForm
  Left = 249
  Top = 134
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Water Effect'
  ClientHeight = 674
  ClientWidth = 417
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -14
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Icon.Data = {
    0000010001002020100000000000E80200001600000028000000200000004000
    0000010004000000000080020000000000000000000000000000000000000000
    000000008000008000000080800080000000800080008080000080808000C0C0
    C0000000FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF000000
    00000000000000000000000000000000000000000000000000000000000000FF
    FFFFFFFFFFFFFF0FF0000000000000FFFFFFFFFFFFFFFF0FF0000000000000FF
    FFFFFFFFFFFFFF00F0000000000000FFFFFFFFFFFFFFFF00F0000000000000FF
    FFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFFF000000000000000FF
    FFFFFFFFFFFFFFF000000000000000FFFFFFFFFFFFFFFFF000000000000000FF
    FFFFFFFFFFFFFFF000000000000000FFFFFFFFFFFFFFFF0000000000000000F0
    00FFFFFFFFFFFF000000000000000000FFFFFFFFFFFFFF0000000000000000FF
    FF00FFFFFFFFF00000000000000000F00000000FFFF000000FFF000000000000
    0000000000000FFF000000FFFF0000000000000000000FFFFF00FFFFFF000000
    00000000000F0FFFFFFFFFFFFF00000000000000000FFFFFFFFFFFFFFF000000
    000000000000FFFFFFFFFFFFFF000000000000000000FFFFFFFFFFFFFF000000
    000000000000FFFFFFFFFFFFFF00000000000000000FFFFFFFFFFFFFFF000000
    00000000000FF0FFFFFFFFFFFF00000000000000000FF0FFFFFFFFFFFF000000
    00000000000FF00FFFFFFFFFFF00000000000000000FFF0FFFFFFFFFFF000000
    0000000000F0FF0FFFFFFFFFFF0000000000000000F0FF0FFFFFFFFFFF000000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    000000000000000000000000000000000000000000000000000000000000}
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 120
  TextHeight = 16
  object Panel1: TPanel
    Left = 8
    Top = 8
    Width = 401
    Height = 401
    BevelOuter = bvLowered
    TabOrder = 0
    object Image: TImage
      Left = 1
      Top = 1
      Width = 399
      Height = 399
      Cursor = crHandPoint
      Align = alClient
      Stretch = True
      OnMouseDown = ImageMouseDown
      OnMouseMove = ImageMouseMove
      OnMouseUp = ImageMouseUp
    end
  end
  object GroupBox1: TGroupBox
    Left = 8
    Top = 416
    Width = 401
    Height = 123
    Caption = ' Animation '
    TabOrder = 1
    object Label3: TLabel
      Left = 10
      Top = 59
      Width = 55
      Height = 16
      Caption = 'Viscosite'
    end
    object Label5: TLabel
      Left = 10
      Top = 89
      Width = 86
      Height = 16
      Caption = 'Vitesse ondes'
    end
    object CheckBox1: TCheckBox
      Left = 10
      Top = 30
      Width = 71
      Height = 20
      Caption = 'Activ'#1077
      Checked = True
      State = cbChecked
      TabOrder = 0
    end
    object ScrollBar3: TScrollBar
      Left = 80
      Top = 58
      Width = 313
      Height = 22
      Max = 25
      PageSize = 0
      TabOrder = 1
      OnChange = ScrollBar3Change
    end
    object ScrollBar4: TScrollBar
      Left = 109
      Top = 87
      Width = 284
      Height = 23
      Max = 20
      Min = 2
      PageSize = 0
      Position = 2
      TabOrder = 2
      OnChange = ScrollBar4Change
    end
  end
  object GroupBox2: TGroupBox
    Left = 8
    Top = 544
    Width = 401
    Height = 121
    Caption = 'Rendu'
    TabOrder = 2
    object Label1: TLabel
      Left = 10
      Top = 59
      Width = 64
      Height = 16
      Caption = 'Luminosite'
    end
    object Label2: TLabel
      Left = 10
      Top = 89
      Width = 66
      Height = 16
      Caption = 'Profondeur'
    end
    object Label6: TLabel
      Left = 10
      Top = 30
      Width = 76
      Height = 16
      Caption = 'Background:'
    end
    object ScrollBar1: TScrollBar
      Left = 101
      Top = 58
      Width = 292
      Height = 21
      Max = 300
      PageSize = 0
      Position = 150
      TabOrder = 0
      OnChange = ScrollBar1Change
    end
    object ScrollBar2: TScrollBar
      Left = 101
      Top = 87
      Width = 292
      Height = 21
      Max = 800
      Min = 20
      PageSize = 0
      Position = 400
      TabOrder = 1
      OnChange = ScrollBar2Change
    end
    object ComboBox1: TComboBox
      Left = 100
      Top = 25
      Width = 293
      Height = 24
      ItemHeight = 16
      TabOrder = 2
      OnSelect = ComboBox1Select
    end
  end
  object XPManifest1: TXPManifest
    Left = 568
    Top = 328
  end
end
