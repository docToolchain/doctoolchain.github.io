<#
.SYNOPSIS
  Konvertiert ein PowerShell-Skript in  eine Batch-Datei

.DESCRIPTION
  Dieses Skript nimmt eine PowerShell-Datei entgegen und kopiert sie in eine 
  Batch-Datei. Die Kopie wird dabei um einen Header ergänzt, der, als Batch
  aufgerufen, das ursprüngliche Skript wieder in eine temporäre Datei
  extrahiert und per PowerShell ausführt.

.PARAMETER PsFile
  Name des zu konvertierenden PowerShell-Skripts

.PARAMETER Destination
  Name und Pfad der resulierenden Batch-Datei. Wenn nicht angegeben, wird Name 
  und Pfad der PowerShell-Datei übernommen und nur die Endung von .ps1 in .cmd
  geändert.

.INPUTS
  Ein PowerShell-Skript

.OUTPUTS
  Eine Batch-Datei, die das PowerShell-Skript enthält und sich wie jede andere
  Batch-Datei starten lässt.

.NOTES
  Version:        1.0
  Author:         Hajo Schulz, hos@ct.de
  Copyright:      (C) 2021 Heise Medien GmbH & Co. KG, c't
  Creation Date:  2021/03/25
  Purpose/Change: Initial script development

.LINK
  https://ct.de/y22p
#>

[CmdletBinding()]
Param (
  [parameter(Position=0, ValueFromPipeline, Mandatory=$true)]
  [String]$PsFile,
  [parameter(Position=1, Mandatory=$false)]
  [String]$Destination
)

$inFile = Get-Item $PsFile -ErrorAction Stop
$outFile = $Destination
if(-not $outFile) {
    $outFile = ($inFile.FullName) -replace '\.ps1$', '.cmd'
}
$text = Get-Content $inFile -Raw
$header = @'
@echo off
%windir%\System32\more +{0} "%~f0" > "%temp%\%~n0.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "%temp%\%~n0.ps1" %*
del %temp%\%~n0.ps1
REM pause
exit /b

*** Ab hier PowerShell ***

'@
$header = $header -f ($header.Split("`n").Length - 1)
$text = $header + $text
Set-Content -Path $outFile -Value $text 
