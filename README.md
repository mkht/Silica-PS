# Silica-PS

Felicaカードの読み書きをPowerShellから行うためのモジュール

## 前提
- Windows x64 のみ対応
- PowerShell 7.4 以降が必要
- Felicaカードリーダー（PaSoRi）が必要 (PaSoRi RC-S380 のみ動作確認済み)
- [NFCポートソフトウェア](https://www.sony.co.jp/Products/felica/consumer/support/download/nfcportsoftware.html) がインストールされていること

## 注意
- IDm、PMm、システムコード、サービスコードの書き換えは通常のFelicaカードではできません。  
  Felica互換の特殊カード（Silica）が必要です。  
  https://github.com/19AJ137/SiliCa

## 使用例
```powershell
Import-Module Silica-PS

# Felicaカードの標準情報を取得
Get-FelicaCard

IDm         : 11-22-33-44-55-66-77-88
PMm         : 00-01-FF-FF-FF-FF-FF-FF
SystemCodes : {3, 65024, 34471}

# 指定ブロックのデータ読み取り
Read-FelicaBlock -ServiceCode 0x009b -BlockNumber 0x00

# 指定ブロックへデータ書き込み
Write-FelicaBlock -ServiceCode 0x009b -BlockNumber 0x00 -Data ([byte[]](0x00..0x0f))

# IDmの書き換え (Silicaカードのみ)
Set-SilicaIDm '0123456789ABCDEF'      # 16進数16桁(8バイト)の文字列で指定

# システムコードの書き換え (Silicaカードのみ)
Set-SilicaSystemCode 'ABCD', '1234'   # 16進数4桁(2バイト)の文字列(最大4つ)で指定

# サービスコードの書き換え (Silicaカードのみ)
Set-SilicaServiceCode '000B', '002B'  # 16進数4桁(2バイト)の文字列(最大4つ)で指定
```

## 使用ライブラリ
- felicalib by Takuya Murakami - BSD License  
  http://felicalib.tmurakam.org/index.html


