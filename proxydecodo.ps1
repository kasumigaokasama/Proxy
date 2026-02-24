<#
proxydecodo.ps1

Zweck:
- Erstellt 10 KOMPLETT NEUE Standalone Chrome-Profile (leere Verzeichnisse),
  damit jede Instanz in einem separaten Chrome-Prozess mit eigenem Proxy laufen kann.
- Liest Proxies im Decodo-Format: HOST:PORT:USERNAME:PASSWORD
  Beispiel: isp.decodo.com:10004:spua7l2r0e:9kj2uEpiL~Fo3p9jsN
- Erstellt für jedes Standalone-Profil einen Desktop-Shortcut mit:
    --user-data-dir="<StandalonePath>"
    --proxy-server="http=HOST:PORT;https=HOST:PORT"  (ohne Credentials im Flag)
WICHTIG: VORHER ALLE CHROME-FENSTER SCHLIESSEN.
#>

# ---- Konfig ----
$chromeExe   = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$proxiesFile = ".\proxies.txt"

# Basis für die neuen Standalone-Profile
$standaloneBase = "C:\ChromeStandalone"   # wird erstellt, falls nötig

# 10 neue Profile: Profil 1 bis Profil 10
$profiles = for ($i=1; $i -le 10; $i++) {
    @{ Name = "Profil $i" }
}
# ----------------

# Checks
if (-not (Test-Path $chromeExe)) { throw "Chrome nicht gefunden: $chromeExe" }
$scriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$proxiesFull = Join-Path $scriptDir $proxiesFile
if (-not (Test-Path $proxiesFull)) {
    Write-Warning "proxies.txt nicht gefunden: $proxiesFull. Es werden keine Proxies gesetzt."
    $raw = @()
}
else {
    $raw = Get-Content $proxiesFull | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" -and -not $_.StartsWith("#") }
}

if ($raw.Count -lt $profiles.Count) {
    Write-Warning "Nur $($raw.Count) Proxies für $($profiles.Count) Profile. Überschüssige Profile bekommen vorerst keinen Proxy."
}

# Zielbasis anlegen
New-Item -ItemType Directory -Path $standaloneBase -Force | Out-Null

# Helper: safer name cleanup
function Clean-Name([string]$n) {
    return ($n -replace '[\\/:*?"<>|]','').Trim()
}

# Erstelle leere Standalone-Profile
$desktop = [Environment]::GetFolderPath("Desktop")
$wsh     = New-Object -ComObject WScript.Shell

for ($i=0; $i -lt $profiles.Count; $i++) {
    $p        = $profiles[$i]
    $friendly = Clean-Name $p.Name

    # Standalone Root: pro Friendly-Name ein Ordner
    $dstRoot    = Join-Path $standaloneBase $friendly
    $dstDefault = Join-Path $dstRoot "Default"

    if (-not (Test-Path $dstRoot)) {
        New-Item -ItemType Directory -Path $dstRoot -Force | Out-Null
        Write-Host "Erstellt: $dstRoot"
    } else {
        Write-Host "Existiert bereits: $dstRoot (wird nicht überschrieben)"
    }

    # (Optional) lege leere Default-Struktur an
    if (-not (Test-Path $dstDefault)) {
        New-Item -ItemType Directory -Path $dstDefault -Force | Out-Null
        New-Item -Path (Join-Path $dstDefault "README.txt") -ItemType File -Value "Dieses Profil wurde automatisch erstellt. Chrome initialisiert beim ersten Start die echten Dateien." | Out-Null
    }

    # Proxy zuweisen (Decodo-Format: HOST:PORT:USERNAME:PASSWORD)
    $proxyFlag = ""
    if ($i -lt $raw.Count) {
        $line = $raw[$i]
        # Decodo-Format: HOST:PORT:USER:PASS  ->  HOST:PORT extrahieren
        if ($line -match "^([a-zA-Z0-9._-]+:\d+):[^:@]+:.+$") {
            $hostport = $Matches[1]
        } else {
            $hostport = $line
        }
        $proxyFlag = "--proxy-server=`"http=$hostport;https=$hostport`""
        Write-Host "Proxy für '$friendly': $hostport"
    } else {
        Write-Warning "Kein Proxy für '$friendly' (nicht genug Zeilen in proxies.txt oder proxies.txt fehlt)"
    }

    # Args: eigener Prozess dank eigenem --user-data-dir
    $args = "--user-data-dir=`"$dstRoot`" --new-window"
    if ($proxyFlag) { $args = "$args $proxyFlag" }

    # Shortcut erstellen
    $lnk = Join-Path $desktop ( $friendly + ".lnk" )
    $sc = $wsh.CreateShortcut($lnk)
    $sc.TargetPath = $chromeExe
    $sc.Arguments = $args
    $sc.WorkingDirectory = [System.IO.Path]::GetDirectoryName($chromeExe)
    $sc.WindowStyle = 1
    $sc.Description = "Standalone Chrome für $friendly (eigener Prozess, Decodo Proxy)"
    $sc.Save()

    Write-Host "Shortcut erstellt: $lnk"
    Write-Host "Args: $args`n"
}

Write-Host "Fertig. Starte jeden Shortcut EINZELN (Chrome vorher komplett schließen)."
Write-Host "Beim ersten HTTPS-Aufruf erscheint das Proxy-Login-Fenster -> Username und Passwort aus der proxies.txt eingeben und 'Remember' anhaken."
