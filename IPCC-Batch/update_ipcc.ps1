# Mengunduh All_Carrier_IPCC_*.zip dari GitHub Release terbaru
# dan mengisi folder ipcc dengan semua operator, bila ada versi baru.
param(
  [string]$Repo = "sulthannaf/ios-carrier-bundles",
  [string]$Dest = (Join-Path $PSScriptRoot "ipcc")
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

try {
  $rels = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases?per_page=20" `
          -Headers @{ "User-Agent" = "ipcc-batch" } -TimeoutSec 30
} catch {
  Write-Host "[UPDATE] Tidak bisa cek pembaruan (offline?). Memakai file yang ada."
  exit 0
}

$rel = $rels | Where-Object {
  -not $_.draft -and ($_.assets | Where-Object { $_.name -like "All_Carrier_IPCC_*.zip" })
} | Select-Object -First 1
if (-not $rel) { Write-Host "[UPDATE] Belum ada release IPCC di $Repo."; exit 0 }

$asset   = $rel.assets | Where-Object { $_.name -like "All_Carrier_IPCC_*.zip" } | Select-Object -First 1
$verFile = Join-Path $Dest "VERSION.txt"
$cur     = ""
if (Test-Path $verFile) { $cur = (Get-Content $verFile -Raw).Trim() }

if ($cur -eq $rel.tag_name) { Write-Host "[UPDATE] Sudah versi terbaru ($cur)."; exit 0 }

$curText = if ($cur) { $cur } else { "-" }
Write-Host "[UPDATE] Versi baru tersedia: $($rel.tag_name) (sekarang: $curText)"
Write-Host ("[UPDATE] Mengunduh {0} ({1} MB)..." -f $asset.name, [math]::Round($asset.size / 1MB, 1))

$tmpZip = Join-Path $env:TEMP $asset.name
$stage  = Join-Path $env:TEMP ("ipcc_" + [guid]::NewGuid().ToString("N"))
try {
  Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $tmpZip -UseBasicParsing -TimeoutSec 900
  Expand-Archive -Path $tmpZip -DestinationPath $stage -Force
  $files = @(Get-ChildItem $stage -Recurse -Filter *.ipcc)
  if ($files.Count -eq 0) { throw "zip tidak berisi file .ipcc" }

  New-Item -ItemType Directory -Force -Path $Dest | Out-Null
  Get-ChildItem $Dest -Filter *.ipcc | Remove-Item -Force
  $files | Move-Item -Destination $Dest -Force
  Set-Content -Path $verFile -Value $rel.tag_name -Encoding ASCII
  Write-Host "[UPDATE] Selesai: $($files.Count) file .ipcc diperbarui ke $($rel.tag_name)."
} catch {
  Write-Host "[UPDATE] Gagal memperbarui: $($_.Exception.Message). Memakai file yang ada."
} finally {
  Remove-Item $tmpZip, $stage -Recurse -Force -ErrorAction SilentlyContinue
}
exit 0
