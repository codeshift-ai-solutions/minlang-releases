# Install ml1 from GitHub Releases (Windows).
#   $env:GH_TOKEN = "..."; iwr -useb <raw-url>/install/install.ps1 | iex
# Or: .\install.ps1 -Version 0.1.0
param(
	[string]$Version = "latest",
	[string]$Repo = "codeshift-ai-solutions/minlang-releases",
	[string]$Dest = "$env:LOCALAPPDATA\ml1\bin"
)
$ErrorActionPreference = "Stop"

$headers = @{}
if ($env:GH_TOKEN) { $headers["Authorization"] = "Bearer $($env:GH_TOKEN)" }

if ($Version -eq "latest") {
	$release = Invoke-RestMethod -Headers $headers "https://api.github.com/repos/$Repo/releases/latest"
} else {
	$release = Invoke-RestMethod -Headers $headers "https://api.github.com/repos/$Repo/releases/tags/v$($Version.TrimStart('v'))"
}
$ver = $release.tag_name.TrimStart("v")
$name = "ml1-v$ver-x86_64-pc-windows-msvc"
$asset = $release.assets | Where-Object { $_.name -eq "$name.zip" }
if (-not $asset) { throw "asset $name.zip not found on release v$ver" }

Write-Host "==> installing ml1 v$ver to $Dest"
$tmp = Join-Path $env:TEMP "ml1-install-$ver"
New-Item -ItemType Directory -Force -Path $tmp, $Dest | Out-Null
$dlHeaders = $headers.Clone(); $dlHeaders["Accept"] = "application/octet-stream"
Invoke-WebRequest -Headers $dlHeaders -Uri $asset.url -OutFile "$tmp\$name.zip"
Expand-Archive -Force "$tmp\$name.zip" -DestinationPath $tmp
Copy-Item -Force "$tmp\$name\ml1.exe" "$Dest\ml1.exe"
Remove-Item -Recurse -Force $tmp

if (($env:PATH -split ";") -notcontains $Dest) {
	Write-Host "note: add $Dest to PATH"
}
& "$Dest\ml1.exe" | Select-Object -First 1
