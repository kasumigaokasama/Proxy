# Chrome Proxy Manager - Anleitung

## Übersicht

Dieses Tool erstellt automatisch mehrere Chrome-Profile, wobei jedes Profil mit einem eigenen Proxy-Server läuft. So kannst du mehrere Chrome-Instanzen gleichzeitig mit unterschiedlichen IP-Adressen nutzen.

## Voraussetzungen

- **Windows-Betriebssystem** (PowerShell erforderlich)
- **Google Chrome** installiert unter `C:\Program Files\Google\Chrome\Application\chrome.exe`
- **Proxies von instantproxies.com** (oder einem anderen Anbieter)

---

## Schritt 1: Proxies von InstantProxies.com kopieren

### 1.1 Bei InstantProxies.com einloggen
1. Gehe zu [instantproxies.com](https://instantproxies.com)
2. Logge dich in deinen Account ein
3. Navigiere zu deinen gekauften Proxies

### 1.2 Proxies kopieren
Die Proxies werden normalerweise im folgenden Format angezeigt:
```
USERNAME:PASSWORD@IP-ADRESSE:PORT
```

**Beispiel:**
```
201018:657c07ea91df283b2d1fdc806ee87dad@152.232.193.232:8800
201018:657c07ea91df283b2d1fdc806ee87dad@196.51.37.103:8800
201018:657c07ea91df283b2d1fdc806ee87dad@209.127.17.220:8800
```

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
1. Teste den Proxy manuell: [https://whoer.net](https://whoer.net)
2. Überprüfe Username/Passwort in `proxies.txt`
3. Kontaktiere InstantProxies.com Support, falls der Proxy abgelaufen ist

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

1. ✅ Proxies von InstantProxies.com kopieren
2. ✅ In `proxies.txt` einfügen (eine Zeile pro Proxy)
3. ✅ Chrome komplett schließen
4. ✅ `proxykraxy.ps1` (neue Profile) oder `proxyuserasign.ps1` (bestehende Profile klonen) ausführen
5. ✅ Shortcuts auf Desktop starten
6. ✅ Proxy-Login beim ersten HTTPS-Aufruf eingeben

**Viel Erfolg!** 🚀
