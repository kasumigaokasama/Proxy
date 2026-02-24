<#
clone-and-shortcut-standalone-profiles.ps1

Zweck:
- Klont deine 10 vorhandenen Chrome-Profile in EIGENE Standalone-Verzeichnisse,
  damit jede Instanz in einem separaten Chrome-Prozess mit eigenem Proxy läuft.
- Erstellt für jedes Standalone-Profil einen Desktop-Shortcut mit:
    --user-data-dir="<StandalonePath>"  (eigener Prozess)
    --proxy-server="http=IP:PORT;https=IP:PORT"  (ohne Credentials im Flag)
- Credentials gibst du beim ersten Aufruf im Proxy-Dialog ein (oder per SwitchyOmega).

WICHTIG:
- VORHER ALLE CHROME-FENSTER SCHLIESSEN.
#>

# ---- Konfig ----
$chromeExe   = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$proxiesFile = ".\proxies.txt"

# Quelle (deine bestehenden Profile unter dem gemeinsamen User-Data-Root):
$sourceUserData = "$env:LOCALAPPDATA\Google\Chrome\User Data"

# Ziel: Standalone-Roots, je Profil ein eigener Ordner
$standaloneBase = "C:\ChromeStandalone"   # wird erstellt

# Deine 10 Profile (FriendlyName -> vorhandenes ProfileDirectory)
$profiles = @(
  @{ Name="Yuu E";     ProfileDir="Default"     },
  @{ Name="Happy E";   ProfileDir="Profile 10"  },
  @{ Name="Troller E"; ProfileDir="Profile 15"  },
  @{ Name="Zero E";    ProfileDir="Profile 11"  },
  @{ Name="hannah E";  ProfileDir="Profile 17"  },
  @{ Name="Yuu A";     ProfileDir="Profile 13"  },
  @{ Name="Happy A";   ProfileDir="Profile 12"  },
  @{ Name="Troller A"; ProfileDir="Profile 16"  },
  @{ Name="Zero A";    ProfileDir="Profile 14"  },
  @{ Name="hannah A";  ProfileDir="Profile 18"  }
)
# ----------------

# Checks
if (-not (Test-Path $chromeExe)) { throw "Chrome nicht gefunden: $chromeExe" }
$scriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$proxiesFull = Join-Path $scriptDir $proxiesFile
if (-not (Test-Path $proxiesFull)) { throw "proxies.txt nicht gefunden: $proxiesFull" }

# Proxies laden (Credentials werden später entfernt)
$raw = Get-Content $proxiesFull | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" -and -not $_.StartsWith("#") }
if ($raw.Count -lt $profiles.Count) {
  Write-Warning "Nur $($raw.Count) Proxies für $($profiles.Count) Profile. Überschüssige Profile bekommen vorerst keinen Proxy."
}

# Zielbasis anlegen
New-Item -ItemType Directory -Path $standaloneBase -Force | Out-Null

# Helper: robustes Kopieren (nur das Profilverzeichnis)
function Copy-ProfileFolder($src, $dst) {
  if (-not (Test-Path $src)) { throw "Quell-Profilordner fehlt: $src" }
  if (-not (Test-Path $dst)) { New-Item -ItemType Directory -Path $dst -Force | Out-Null }
  # Wir kopieren nur den Ordnerinhalt (Cookies, Local Storage etc.)
  robocopy $src $dst /MIR /NFL /NDL /NJH /NJS | Out-Null
}

# Shortcuts
$desktop = [Environment]::GetFolderPath("Desktop")
$wsh     = New-Object -ComObject WScript.Shell

for ($i=0; $i -lt $profiles.Count; $i++) {
  $p          = $profiles[$i]
  $friendly   = $p.Name
  $profileDir = $p.ProfileDir

  $srcProfilePath = Join-Path $sourceUserData $profileDir

  # Standalone Ziel: je Friendly ein Root, darin legt Chrome selbst eine "Default"-Struktur an
  $dstRoot = Join-Path $standaloneBase ($friendly -replace '[\\/:*?"<>|]','')
  $dstDefault = Join-Path $dstRoot "Default"

  Write-Host "`n==> Klone '$profileDir'  ->  '$dstDefault'"
  Copy-ProfileFolder -src $srcProfilePath -dst $dstDefault

  # Proxy zuweisen
  $proxyFlag = ""
  if ($i -lt $raw.Count) {
    $line = $raw[$i]
    if ($line -match "^[^@]+@(.+)$") { $hostport = $Matches[1] }
    elseif ($line -match "^([a-zA-Z0-9._-]+:\d+):[^:@]+:.+$") { $hostport = $Matches[1] }
    else { $hostport = $line }
    $proxyFlag = "--proxy-server=`"http=$hostport;https=$hostport`""
    Write-Host "Proxy: $hostport"
  } else {
    Write-Warning "Kein Proxy für $friendly (nicht genug Zeilen in proxies.txt)"
  }

  # Args: eigener Prozess dank eigenem --user-data-dir (KEIN --profile-directory mehr!)
  $args = "--user-data-dir=`"$dstRoot`""
  if ($proxyFlag) { $args = "$args $proxyFlag" }

  # Shortcut erstellen
  $lnk = Join-Path $desktop ( ($friendly -replace '[\\/:*?"<>|]','') + ".lnk" )
  $sc = $wsh.CreateShortcut($lnk)
  $sc.TargetPath = $chromeExe
  $sc.Arguments = $args
  $sc.WorkingDirectory = [System.IO.Path]::GetDirectoryName($chromeExe)
  $sc.WindowStyle = 1
  $sc.Description = "Standalone Chrome for $friendly (eigener Prozess, eigener Proxy)"
  $sc.Save()

  Write-Host "Shortcut: $lnk"
  Write-Host "Args: $args"
}

Write-Host "`nFertig. Starte jeden Shortcut EINZELN (Chrome vorher komplett schließen)."
Write-Host "Beim ersten HTTPS-Aufruf erscheint ggf. der Proxy-Login (Username 201018 / dein Passwort) -> 'Remember' anhaken."
