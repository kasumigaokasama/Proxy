# Chrome Proxy Manager - Anleitung

## Übersicht

Dieses Tool erstellt automatisch mehrere Chrome-Profile, wobei jedes Profil mit einem eigenen Proxy-Server läuft. So kannst du mehrere Chrome-Instanzen gleichzeitig mit unterschiedlichen IP-Adressen nutzen.

## Voraussetzungen

- **Windows-Betriebssystem** (PowerShell erforderlich)
- **Google Chrome** installiert unter `C:\Program Files\Google\Chrome\Application\chrome.exe`
- **Proxies von instantproxies.com** (oder einem anderen Anbieter)

---


## Proxy-Formate konvertieren

Verschiedene Anbieter liefern Proxies in unterschiedlichen Formaten. **Unser System benötigt:**

```
USERNAME:PASSWORD@IP:PORT
```

### Format-Konvertierungen

#### Format 1: `IP:PORT:USERNAME:PASSWORD` 
**Gegeben:**
```
45.142.122.1:5678:user123:pass456
45.142.122.2:5678:user123:pass456
```

**Konvertieren zu:**
```
user123:pass456@45.142.122.1:5678
user123:pass456@45.142.122.2:5678
```

**Automatische Konvertierung (PowerShell):**
```powershell
# Lade die Originaldatei
$proxies = Get-Content "proxies_original.txt"

# Konvertiere Format
$converted = $proxies | ForEach-Object {
    if ($_ -match '^(\S+):(\d+):(\S+):(\S+)$') {
        "$($Matches[3]):$($Matches[4])@$($Matches[1]):$($Matches[2])"
    }
}

# Speichere in proxies.txt
$converted | Set-Content "proxies.txt"
```

#### Format 2: `USERNAME:PASSWORD@HOST:PORT` 
Manche Anbieter verwenden einen zentralen Gateway-Host statt direkter IPs.

**Gegeben:**
```
user-zone-residential:password@gate.smartproxy.com:7000
user-zone-residential:password@gate.smartproxy.com:7000
```

**Lösung:** Dieses Format funktioniert **direkt** in `proxies.txt`! Einfach kopieren und einfügen.

#### Format 3: `http://USERNAME:PASSWORD@IP:PORT` (mit Protokoll-Präfix)
**Gegeben:**
```
http://user123:pass456@45.142.122.1:5678
https://user123:pass456@45.142.122.2:5678
```

**Konvertieren zu:**
```
user123:pass456@45.142.122.1:5678
user123:pass456@45.142.122.2:5678
```

**Automatische Konvertierung (PowerShell):**
```powershell
$proxies = Get-Content "proxies_original.txt"
$converted = $proxies | ForEach-Object {
    $_ -replace '^https?://', ''
}
$converted | Set-Content "proxies.txt"
```

#### Format 4: Nur `IP:PORT` (ohne Authentifizierung)
Manche Datacenter-Proxies haben IP-Whitelisting statt Username/Password.

**Gegeben:**
```
45.142.122.1:5678
45.142.122.2:5678
```

**Lösung:** Diese Proxies funktionieren **ohne Login**. Du musst aber deine eigene IP beim Anbieter whitelisten.

**Für proxies.txt:**
```
@45.142.122.1:5678
@45.142.122.2:5678
```
(Das `@`-Zeichen am Anfang signalisiert: keine Credentials erforderlich)

**ODER** passe die PowerShell-Skripte an (Zeile 77-80 in `proxykraxy.ps1`):
```powershell
if ($line -match "^@(.+)$") {
    $hostport = $Matches[1]
} elseif ($line -match "^[^@]+@(.+)$") {
    $hostport = $Matches[1]
} else {
    $hostport = $line
}
```

---

## Schritt 1: Proxies kopieren (für alle Anbieter)

### 1.1 Bei deinem Proxy-Anbieter einloggen

**Beispiel InstantProxies.com:**
1. Gehe zu [instantproxies.com](https://instantproxies.com)
2. Logge dich in deinen Account ein
3. Navigiere zu deinen gekauften Proxies

**Für andere Anbieter:**
- Logge dich in dein Dashboard ein
- Finde die Seite mit deinen aktiven Proxies
- Suche nach einem "Export" oder "Copy" Button

### 1.2 Proxies kopieren

Die meisten Anbieter zeigen Proxies in einem dieser Formate:

**Format A (ideal, direkt verwendbar):**
```
USERNAME:PASSWORD@IP-ADRESSE:PORT
```

**Beispiel:**
```
201018:657c07ea91df283b2d1fdc806ee87dad@152.232.193.232:8800
201018:657c07ea91df283b2d1fdc806ee87dad@196.51.37.103:8800
201018:657c07ea91df283b2d1fdc806ee87dad@209.127.17.220:8800
```

**Format B (muss konvertiert werden):**
```
IP:PORT:USERNAME:PASSWORD
```

**Siehe Abschnitt "Proxy-Formate konvertieren" weiter oben**, falls dein Anbieter ein anderes Format verwendet!

### 1.3 Proxies in proxies.txt einfügen

1. Öffne die Datei `proxies.txt` in diesem Ordner mit einem Texteditor (z.B. Notepad)
2. **Lösche** alle vorhandenen Einträge (oder behalte sie, falls du sie brauchst)
3. **Kopiere** deine Proxies von InstantProxies.com
4. **Füge** sie in `proxies.txt` ein - **eine Proxy-Zeile pro Zeile**
5. **Speichere** die Datei

**Wichtig:**
- Jeder Proxy muss in einer eigenen Zeile stehen
- Keine Leerzeilen zwischen den Proxies
- Format: `USERNAME:PASSWORD@IP:PORT`

**Beispiel für proxies.txt:**
```
201018:657c07ea91df283b2d1fdc806ee87dad@152.232.193.232:8800
201018:657c07ea91df283b2d1fdc806ee87dad@196.51.37.103:8800
201018:657c07ea91df283b2d1fdc806ee87dad@209.127.17.220:8800
201018:657c07ea91df283b2d1fdc806ee87dad@152.232.192.135:8800
201018:657c07ea91df283b2d1fdc806ee87dad@152.232.193.226:8800
```

---

## Schritt 2: Chrome-Profile mit Proxies einrichten

Du hast **zwei Optionen**:

### Option A: Neue Profile erstellen (proxykraxy.ps1)
**Verwende dieses Skript**, wenn du komplett neue Chrome-Profile erstellen möchtest.

### Option B: Bestehende Profile klonen (proxyuserasign.ps1)
**Verwende dieses Skript**, wenn du bereits Chrome-Profile hast und diese mit Proxies nutzen möchtest.

---

## Option A: Neue Profile erstellen

### Anleitung für `proxykraxy.ps1`

1. **Schließe alle Chrome-Fenster** (sehr wichtig!)

2. **Rechtsklick** auf `proxykraxy.ps1`

3. Wähle **"Mit PowerShell ausführen"**
   - Falls PowerShell-Skripte blockiert sind, öffne PowerShell als Administrator und führe aus:
     ```powershell
     Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
     ```

4. Das Skript erstellt:
   - 10 neue Chrome-Profile unter `C:\ChromeStandalone\`
   - Einen Desktop-Shortcut für jedes Profil (Profil 1, Profil 2, etc.)
   - Jedes Profil wird automatisch mit einem Proxy aus `proxies.txt` verbunden

5. **Fertig!** Auf deinem Desktop findest du jetzt 10 Shortcuts.

### Profile starten

1. **Doppelklick** auf einen Shortcut (z.B. "Profil 1.lnk")
2. Chrome startet mit dem zugewiesenen Proxy
3. Beim ersten Aufruf einer HTTPS-Seite erscheint möglicherweise ein **Proxy-Login-Dialog**:
   - **Benutzername:** (z.B. 201018 - siehe deine proxies.txt)
   - **Passwort:** (dein Proxy-Passwort - siehe proxies.txt)
   - Haken bei **"Anmeldedaten speichern"** setzen
4. Wiederhole dies für alle anderen Profile

---

## Option B: Bestehende Profile klonen

### Anleitung für `proxyuserasign.ps1`

Dieses Skript klont deine **vorhandenen** Chrome-Profile und weist jedem einen Proxy zu.

1. **Öffne** `proxyuserasign.ps1` in einem Texteditor

2. **Passe die Profil-Namen an** (Zeilen 27-38):
   ```powershell
   $profiles = @(
     @{ Name="Profil 1"; ProfileDir="Default"     },
     @{ Name="Profil 2"; ProfileDir="Profile 1"   },
     @{ Name="Profil 3"; ProfileDir="Profile 2"   },
     # ... usw.
   )
   ```
   - **Name:** Wie der Shortcut heißen soll
   - **ProfileDir:** Der Ordnername deines Chrome-Profils unter `%LOCALAPPDATA%\Google\Chrome\User Data\`

3. **Schließe alle Chrome-Fenster**

4. **Rechtsklick** auf `proxyuserasign.ps1` → **"Mit PowerShell ausführen"**

5. Das Skript:
   - Kopiert jedes Profil nach `C:\ChromeStandalone\`
   - Erstellt Desktop-Shortcuts mit Proxy-Zuweisung
   - Jedes geklonte Profil behält alle Einstellungen, Lesezeichen, Cookies, etc.

6. **Starte die Shortcuts** wie in Option A beschrieben

---

## Wie viele Proxies brauche ich?

- **10 Profile → 10 Proxies** in `proxies.txt`
- Wenn du weniger Proxies hast, bekommen die übrigen Profile keinen Proxy zugewiesen
- Wenn du mehr Proxies hast, werden nur die ersten 10 verwendet

---

## Wichtige Hinweise

### ⚠️ Chrome komplett schließen
Vor dem Ausführen der Skripte **ALLE** Chrome-Fenster schließen, sonst können Profile nicht richtig kopiert werden.

### ⚠️ Proxy-Anmeldung
- Beim **ersten Besuch** einer HTTPS-Seite erscheint ein Login-Dialog
- Gib **Username** und **Passwort** aus deiner `proxies.txt` ein
- **"Anmeldedaten speichern"** anhaken, damit du nicht jedes Mal erneut eingeben musst

### ⚠️ Jedes Profil = eigener Chrome-Prozess
- Jeder Shortcut startet Chrome mit `--user-data-dir`, was einen **komplett separaten Chrome-Prozess** bedeutet
- Du kannst alle 10 Profile gleichzeitig offen haben
- Jedes Profil hat seine eigene IP-Adresse (dank Proxy)

### ⚠️ Proxy-Format
Das Format in `proxies.txt` muss **exakt** so aussehen:
```
USERNAME:PASSWORD@IP:PORT
```

**Richtig:**
```
201018:abc123@152.232.193.232:8800
```

**Falsch:**
```
152.232.193.232:8800:201018:abc123   ❌
http://201018:abc123@152.232.193.232:8800   ❌
```

---

## Problembehandlung

### Problem: "Skript kann nicht ausgeführt werden"
**Lösung:** PowerShell Execution Policy ändern:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Problem: "Chrome nicht gefunden"
**Lösung:** Chrome-Pfad in den Skripten anpassen (Zeile 14):
```powershell
$chromeExe = "C:\Program Files\Google\Chrome\Application\chrome.exe"
```

### Problem: "proxies.txt nicht gefunden"
**Lösung:** Stelle sicher, dass `proxies.txt` im **gleichen Ordner** wie die .ps1-Skripte liegt.

### Problem: Proxy funktioniert nicht
1. Teste den Proxy manuell: [https://whoer.net](https://whoer.net) oder [https://whatismyipaddress.com](https://whatismyipaddress.com)
2. Überprüfe Username/Passwort in `proxies.txt`
3. Stelle sicher, dass das Format korrekt ist: `USERNAME:PASSWORD@IP:PORT`
4. Bei IP-Whitelisting-Proxies: Überprüfe, ob deine aktuelle IP beim Anbieter hinterlegt ist
5. Kontaktiere den Support deines Proxy-Anbieters, falls der Proxy abgelaufen oder gesperrt ist

### Problem: Format-Fehler beim Konvertieren
**Lösung:** Stelle sicher, dass deine `proxies_original.txt` keine Leerzeilen oder Kommentare enthält:
```powershell
# Bereinige die Datei vor Konvertierung
$proxies = Get-Content "proxies_original.txt" | Where-Object { $_ -ne "" -and -not $_.StartsWith("#") }
```

### Problem: Zu viele Chrome-Prozesse
**Lösung:** Schließe alle Chrome-Fenster über den Task-Manager:
1. `Strg + Shift + Esc`
2. Alle "Google Chrome"-Prozesse beenden

---

## Weitere Informationen

### Proxy-Credentials im Browser speichern
Die Skripte setzen nur die **Proxy-Server-Adresse** im Chrome-Flag. Die **Anmeldedaten** (Username/Passwort) musst du beim ersten HTTPS-Aufruf eingeben. Chrome speichert diese dann.

### Alternativen: SwitchyOmega
Falls du die Proxies manuell verwalten möchtest, kannst du die Chrome-Erweiterung **Proxy SwitchyOmega** nutzen.

---

## Zusammenfassung

1. ✅ **Proxy-Anbieter wählen** (InstantProxies, Webshare, IPRoyal, Smartproxy, etc.)
2. ✅ **Proxies kopieren** von deinem Anbieter-Dashboard
3. ✅ **Format überprüfen** - bei Bedarf mit PowerShell-Scripts konvertieren
4. ✅ **In `proxies.txt` einfügen** (eine Zeile pro Proxy, Format: `USERNAME:PASSWORD@IP:PORT`)
5. ✅ **Chrome komplett schließen**
6. ✅ **PowerShell-Skript ausführen:**
   - `proxykraxy.ps1` für neue Profile
   - `proxyuserasign.ps1` für bestehende Profile klonen
7. ✅ **Shortcuts auf Desktop starten**
8. ✅ **Proxy-Login eingeben** beim ersten HTTPS-Aufruf (falls erforderlich)

---

## Quick-Start für verschiedene Anbieter

### InstantProxies / IPRoyal / ProxyEmpire
- Format ist bereits korrekt ✅
- Direkt in `proxies.txt` einfügen

### Webshare.io
- Format konvertieren erforderlich! ⚠️
- PowerShell-Script verwenden (siehe "Format 1" weiter oben)

### Smartproxy / Bright Data
- Gateway-Format funktioniert direkt ✅
- Einfach kopieren und einfügen

### IP-Whitelisting Proxies
- `@IP:PORT` Format verwenden
- Deine IP beim Anbieter eintragen

**Viel Erfolg!** 🚀
