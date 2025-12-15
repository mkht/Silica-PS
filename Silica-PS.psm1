enum SystemCode {
   Any = 0xffff       # ANY
   Common = 0xfe00    # 共通領域
   Cyberne = 0x0003   # サイバネ領域
   Edy = 0xfe00       # Edy (=共通領域)
   Suica = 0x0003     # Suica (=サイバネ領域)
   QUICPay = 0x04c1   # QUICPay
}

# Function: Get-FelicaCard
# Description: Get basic card information from a Felica card. 
function Get-FelicaCard {
   [CmdletBinding()]
   param(
      [Parameter()]
      [ushort]$SystemCode = [SystemCode]::Any
   )

   try {
      Write-Verbose 'Initializing PaSoRi card reader...'
      $felica = [FelicaLib.Felica]::new()
      Write-Verbose 'Polling Felica card...'
      $felica.Polling($SystemCode)
      Write-Verbose 'Finished polling. Successfully got card information.'

      $IDm = [System.BitConverter]::ToString($felica.IDm)
      $PMm = [System.BitConverter]::ToString($felica.PMm)

      Write-Verbose 'Enumerating system codes...'
      $SystemCodes = $felica.EnumSystemCode()
      Write-Verbose ('Finished enumerating system codes. There are {0} systems found.' -f $SystemCodes.Count)

      [PSCustomObject]@{
         IDm         = $IDm
         PMm         = $PMm
         SystemCodes = $SystemCodes
      }
   }
   catch {
      Write-Error -Exception $_.Exception
   }
   finally {
      $felica.Dispose()
      $felica = $null
   }
}

function Read-FelicaBlock {
   [CmdletBinding()]
   [OutputType([byte[]])]
   param(
      [Parameter(Mandatory = $true)]
      [int]$ServiceCode,

      [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
      [byte[]]$BlockAddress
   )

   begin {
      try {
         Write-Verbose 'Initializing PaSoRi card reader...'
         $felica = [FelicaLib.Felica]::new()
         Write-Verbose 'Polling Felica card...'
         $felica.Polling([SystemCode]::Any)
         Write-Verbose 'Finished polling.'
      }
      catch {
         Write-Error -Exception $_.Exception
      }
   }

   process {
      try {
         foreach ($addr in $BlockAddress) {
            Write-Verbose ('Reading data from service 0x{0:x4}, address 0x{1:x2} ...' -f $ServiceCode, $addr)
            $data = [byte[]]$felica.ReadWithoutEncryption($ServiceCode, $addr)
            if ($null -eq $data) {
               Write-Warning ('There is no data at address 0x{0:x2} in service 0x{1:x4}.' -f $addr, $ServiceCode)
            }
            $data
         }
      }
      catch {
         Write-Error -Exception $_.Exception
      }
   }

   clean {
      if ($null -ne $felica) {
         $felica.Dispose()
         $felica = $null
      }
   }
}

function Write-FelicaBlock {
   [CmdletBinding()]
   param(
      [Parameter(Mandatory = $true)]
      [int]$ServiceCode,

      [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
      [byte[]]$BlockAddress,

      [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
      [ValidateCount(1, 16)]
      [byte[]]$Data
   )

   begin {
      try {
         Write-Verbose 'Initializing PaSoRi card reader...'
         $felica = [FelicaLib.Felica]::new()
         Write-Verbose 'Polling Felica card...'
         $felica.Polling([SystemCode]::Any)
         Write-Verbose 'Finished polling.'
      }
      catch {
         Write-Error -Exception $_.Exception
      }
   }

   process {
      try {
         foreach ($addr in $BlockAddress) {
            Write-Verbose ('Writing data to service 0x{0:x4}, address 0x{1:x2} ...' -f $ServiceCode, $addr)
            $result = $felica.WriteWithoutEncryption($ServiceCode, $addr, $Data)
            if ($result -ne 0) {
               Write-Error -Exception ([InvalidOperationException]::new(('Failed to write data to block address 0x{0:x2} in service 0x{1:x4}.' -f $addr, $ServiceCode)))
            }
            else {
               Write-Verbose ('Successfully wrote data to address 0x{0:x2} in service 0x{1:x4}.' -f $addr, $ServiceCode)
            }
         }
      }
      catch {
         Write-Error -Exception $_.Exception
      }
   }

   clean {
      if ($null -ne $felica) {
         $felica.Dispose()
         $felica = $null
      }
   }
}

function Set-SilicaIDm {
   [CmdletBinding()]
   param(
      [Parameter(Mandatory = $true, Position = 0)]
      [string]$IDm,

      [Parameter(Position = 1)]
      [string]$PMm = '0001ffffffffffff'   # Default PMm
   )

   #Parameter validation
   $IDm = $IDm.ToLower() -replace '[^0-9a-f]', ''
   if ($IDm.Length -ne 16 -or -not $IDm -match '^[0-9a-f]{16}$') {
      throw [System.ArgumentException]::new('IDm must be a 16-character hexadecimal string.')
   }
   $PMm = $PMm.ToLower() -replace '[^0-9a-f]', ''
   if ($PMm.Length -ne 16 -or -not $PMm -match '^[0-9a-f]{16}$') {
      throw [System.ArgumentException]::new('PMm must be a 16-character hexadecimal string.')
   }

   $service = 0xffff
   $block = 0x83
   $data = $IDm + $PMm
   $bytes = for ($i = 0; $i -lt $data.Length; $i += 2) {
      [Convert]::ToByte($data.Substring($i, 2), 16)
   }

   Write-Verbose ('Writing new IDm ({0}) and PMm ({1}) to Silica card...' -f $IDm, $PMm)
   Write-FelicaBlock -ServiceCode $service -BlockAddress $block -Data $bytes
}

function Set-SilicaSystemCode {
   [CmdletBinding()]
   param(
      [Parameter(Mandatory = $true, Position = 0)]
      [string[]]$SystemCode
   )

   $MAX_SYSTEM = 4

   #Parameter validation
   $syscode = (-join $SystemCode).ToLower() -replace '[^0-9a-f]', ''
   if ($syscode.Length % 2 -ne 0) {
      throw [System.ArgumentException]::new('System codes must be in 2-byte pairs as a hexadecimal string.')
   }
   if ($syscode.Length -eq 0) {
      throw [System.ArgumentException]::new('At least one system code must be provided.')
   }
   if ($syscode.Length / 4 -gt $MAX_SYSTEM) {
      throw [System.ArgumentException]::new("A maximum of $MAX_SYSTEM system codes can be set.")
   }

   $service = 0xffff
   $block = 0x85
   $data = $syscode
   $bytes = for ($i = 0; $i -lt $data.Length; $i += 2) {
      [Convert]::ToByte($data.Substring($i, 2), 16)
   }
   $bytes += , 0x00 * ( 16 - $bytes.Length )  # Pad with zeros

   Write-Verbose 'Writing new system codes to Silica card...'
   Write-FelicaBlock -ServiceCode $service -BlockAddress $block -Data $bytes
}

function Set-SilicaServiceCode {
   [CmdletBinding()]
   param(
      [Parameter(Mandatory = $true, Position = 0)]
      [string[]]$ServiceCode
   )

   $MAX_SERVICE = 4

   #Parameter validation
   $sercode = (-join $ServiceCode).ToLower() -replace '[^0-9a-f]', ''
   if ($sercode.Length % 2 -ne 0) {
      throw [System.ArgumentException]::new('Service codes must be in 2-byte pairs as a hexadecimal string.')
   }
   if ($sercode.Length -eq 0) {
      throw [System.ArgumentException]::new('At least one service code must be provided.')
   }
   if ($sercode.Length / 4 -gt $MAX_SERVICE) {
      throw [System.ArgumentException]::new("A maximum of $MAX_SERVICE service codes can be set.")
   }

   $service = 0xffff
   $block = 0x84
   $data = $sercode
   # swap bytes within each 2-byte service code, keep code order
   $bytes = for ($i = 0; $i -lt $data.Length; $i += 4) {
      [Convert]::ToByte($data.Substring(($i + 2), 2), 16)
      [Convert]::ToByte($data.Substring($i, 2), 16)
   }
   $bytes += , 0x00 * ( 16 - $bytes.Length )  # Pad with zeros

   Write-Verbose 'Writing new service codes to Silica card...'
   Write-FelicaBlock -ServiceCode $service -BlockAddress $block -Data $bytes
}