@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM ====================================================================
REM Name: Farbkonstanten - Farbmodus Standard AN
REM Erklaerung: ANSI-Farben zentral definiert.
REM ====================================================================
for /F %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set "CYAN_H=%ESC%[1;96m"
set "YELLOW_H=%ESC%[1;93m"
set "RED_H=%ESC%[1;91m"
set "MAGENTA_L=%ESC%[1;35m"
set "GREEN_O=%ESC%[1;92m"
set "RESET=%ESC%[0m"

REM ====================================================================
REM Name: NO_COLOR - No-Color-Modus FEST einschalten (Konfiguration)
REM Erklaerung: NO_COLOR=1 schaltet die Farbausgabe DAUERHAFT ab (fuer
REM             alle Aufrufe, ohne -nc uebergeben zu muessen). In diesem
REM             Fall wird auch die VT-Pruefung unten uebersprungen.
REM             Standard ist 0 (Farben an, mit Fallback).
REM ====================================================================
set "NO_COLOR=0"

REM ====================================================================
REM Name: VT-Pruefung mit Farb-Fallback
REM Erklaerung: Prueft, ob die Konsole ANSI/VT unterstuetzt
REM             (SetConsoleMode, Bit wird zur Kontrolle zurueckgelesen).
REM             Schlaegt die Pruefung fehl - z.B. bei Umleitung der
REM             Ausgabe in eine Datei (> sha.txt), einer nicht-VT-
REM             faehigen Konsole oder bei gesetztem NO_COLOR=1 - werden
REM             ALLE Farbvariablen automatisch geleert: Die Ausgabe ist
REM             dann schlicht, es landen nie ANSI-Codes in Hashdateien.
REM             -nc schaltet die Farben zusaetzlich jederzeit manuell
REM             fuer den einzelnen Aufruf ab.
REM ====================================================================
set "COLORMODE=1"
if "%NO_COLOR%"=="1" set "COLORMODE=0"
if "%COLORMODE%"=="1" powershell -NoProfile -Command "try { $k = Add-Type -MemberDefinition '[DllImport(\"kernel32.dll\")] public static extern IntPtr GetStdHandle(int h); [DllImport(\"kernel32.dll\")] public static extern bool GetConsoleMode(IntPtr h, out uint m); [DllImport(\"kernel32.dll\")] public static extern bool SetConsoleMode(IntPtr h, uint m);' -Name K32Csum -PassThru; $h = $k::GetStdHandle(-11); $m = 0; if(-not $k::GetConsoleMode($h, [ref]$m)) { exit 1 }; if(-not $k::SetConsoleMode($h, $m -bor 4)) { exit 1 }; $m2 = 0; if(-not $k::GetConsoleMode($h, [ref]$m2)) { exit 1 }; if(($m2 -band 4) -ne 4) { exit 1 }; exit 0 } catch { exit 1 }"
if errorlevel 1 set "COLORMODE=0"
if "%COLORMODE%"=="0" (
  set "CYAN_H="
  set "YELLOW_H="
  set "RED_H="
  set "MAGENTA_L="
  set "GREEN_O="
  set "RESET="
  set "ESC="
)

REM ====================================================================
REM MIT License
REM 
REM Copyright (c) 2025 cvinz78
REM 
REM Permission is hereby granted, free of charge, to any person obtaining a copy
REM of this software and associated documentation files (the "Software"), to deal
REM in the Software without restriction, including without limitation the rights
REM to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
REM copies of the Software, and to permit persons to whom the Software is
REM furnished to do so, subject to the following conditions:
REM 
REM The above copyright notice and this permission notice shall be included in all
REM copies or substantial portions of the Software.
REM 
REM THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
REM IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
REM FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
REM AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
REM LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
REM OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
REM SOFTWARE.
REM ====================================================================

REM ====================================================================
REM Name: Standard-Sprache
REM Erklaerung: Definiert die Sprache, die verwendet wird, wenn weder 
REM            -de noch -en uebergeben werden.
REM ====================================================================
set "LANG=DE"

REM ====================================================================
REM Name: Standard-Algorithmus
REM Erklaerung: Definiert den Hash-Algorithmus, der verwendet wird, wenn 
REM            beim Aufruf kein Algorithmus angegeben wird.
REM ====================================================================
set "ALGO=SHA256"

REM ====================================================================
REM Name: Merker fuer expliziten Algorithmus
REM Erklaerung: 1 = Algorithmus wurde auf der Kommandozeile angegeben
REM            (hat Vorrang), 0 = Standard; in diesem Fall wird beim
REM            Abgleich mit einer Hashdatei der Algorithmus automatisch
REM            aus der Hashdatei erkannt.
REM ====================================================================
set "ALGO_EXPLICIT=0"

REM ====================================================================
REM Name: Skriptname merken
REM Erklaerung: shift verschiebt auch %0 - nach einem shift wuerde %~nx0
REM            falsch sein (z.B. "-nc" statt "csum.bat"). Daher den
REM            Namen VOR dem Parsen sichern und in Hilfe/Fehlertexten
REM            nur %SCRIPT_NAME% verwenden.
REM ====================================================================
set "SCRIPT_NAME=%~nx0"


REM ====================================================================
REM FUNKTION: ParseArgs
REM Name: Parameter-Parser (Hauptschleife)
REM Erklaerung: Dies ist die Hauptschleife zum Einlesen der Kommandozeilenparameter. 
REM            Sie laeuft so lange, bis keine Parameter mehr uebrig sind. 
REM            Dabei werden Optionen (-h, -de, -en) herausgefiltert und die 
REM            eigentlichen Pfad-/Datei-Parameter zugewiesen.
REM ====================================================================
:ParseArgs
if "%~1"=="" goto :CheckTarget

REM Name: Hilfe-Flag erkennen
REM Erklaerung: Prueft, ob der aktuelle Parameter -h oder --help ist. 
REM            Wenn ja, wird sofort zur Hilfeseite gesprungen.
if /i "%~1"=="/?" goto :Help
if /i "%~1"=="-?" goto :Help
if /i "%~1"=="-h" goto :Help
if /i "%~1"=="--help" goto :Help

REM Name: Sprach-Flags erkennen
REM Erklaerung: Prueft auf -de und -en. Wenn erkannt, wird die Variable LANG 
REM            ueberschrieben. "shift" entfernt den verarbeiteten Parameter, 
REM            und die Schleife beginnt von vorn mit dem naechsten Parameter.
if /i "%~1"=="-de" (
  set "LANG=DE"
  shift
  goto :ParseArgs
)
if /i "%~1"=="-en" (
  set "LANG=EN"
  shift
  goto :ParseArgs
)

REM Name: Farb-Abschaltung erkennen
REM Erklaerung: -nc deaktiviert die Farbausgabe fuer diesen Aufruf
REM             (z.B. fuer Umleitung in eine Datei). Der Fallback am
REM             Skriptanfang schaltet bei Umleitung ohnehin automatisch
REM             ab; -nc erzwingt es auch bei VT-faehiger Konsole.
if /i "%~1"=="-nc" (
  set "CYAN_H="
  set "YELLOW_H="
  set "RED_H="
  set "MAGENTA_L="
  set "GREEN_O="
  set "RESET="
  set "ESC="
  shift
  goto :ParseArgs
)

REM Name: Pfad zuweisen
REM Erklaerung: Wenn der Parameter kein Flag ist, muss es sich um den 
REM            Dateipfad handeln. Dieser wird gespeichert.
set "TARGET=%~1"
shift

REM ====================================================================
REM Name: Intelligente Algorithmus-Erkennung
REM Erklaerung: Prueft, ob der naechste Parameter ein bekannter Hash-Algorithmus ist.
REM            Wenn nicht (z.B. weil es direkt die Hash-Datei ist), wird er uebersprungen.
REM ====================================================================
set "NEXT_PARAM=%~1"
set "IS_ALGO=0"
if /i "%NEXT_PARAM%"=="MD2" set "IS_ALGO=1"
if /i "%NEXT_PARAM%"=="MD4" set "IS_ALGO=1"
if /i "%NEXT_PARAM%"=="MD5" set "IS_ALGO=1"
if /i "%NEXT_PARAM%"=="SHA1" set "IS_ALGO=1"
if /i "%NEXT_PARAM%"=="SHA256" set "IS_ALGO=1"
if /i "%NEXT_PARAM%"=="SHA384" set "IS_ALGO=1"
if /i "%NEXT_PARAM%"=="SHA512" set "IS_ALGO=1"

if "%IS_ALGO%"=="1" (
  set "ALGO=%NEXT_PARAM%"
  set "ALGO_EXPLICIT=1"
  shift
)

REM Name: Optionale Hashdatei zuweisen
REM Erklaerung: Wenn jetzt noch ein Parameter folgt, MUSS es die Hashdatei sein.
if not "%~1"=="" set "HASHFILE=%~1"

REM Name: Parser beenden
REM Erklaerung: Alle Parameter wurden gelesen. Das Script springt in die Auswertungsphase.
goto :Run


REM ====================================================================
REM FUNKTION: CheckTarget
REM Name: Pfad-Pruefung
REM Erklaerung: Wird aufgerufen, wenn die Schleife ohne weiteren Parameter endet 
REM            (z.B. wenn nur "csum.bat -de" ohne Datei aufgerufen wird).
REM            Stellt sicher, dass ein Pfad vorhanden ist.
REM ====================================================================
:CheckTarget
if not defined TARGET (
  REM Name: Notfall-Textzuweisung
  REM Erklaerung: Wenn kein Pfad angegeben wurde, wurden auch die normalen 
  REM            Texte weiter unten noch nicht geladen. Daher weisen wir 
  REM            die Fehlermeldung hier direkt und sprachabhaengig zu.
  if not defined L_ERR_NO_PATH (
    if /i "%LANG%"=="EN" (
      set "L_ERR_NO_PATH=Error: No path provided."
      set "L_ERR_HINT=Type "%SCRIPT_NAME% -h" to display help."
    ) else (
      set "L_ERR_NO_PATH=Fehler: Kein Pfad angegeben."
      set "L_ERR_HINT=Geben Sie "%SCRIPT_NAME% -h" ein, um die Hilfe anzuzeigen."
    )
  )
  echo !RED_H!!L_ERR_NO_PATH!!RESET!
  echo !YELLOW_H!!L_ERR_HINT!!RESET!
  exit /b 1
)


REM ====================================================================
REM FUNKTION: Run
REM Name: Text-Zuweisung (Lokalisierung)
REM Erklaerung: Ab hier werden alle Texte fuer die Bildschirmausgabe in Variablen 
REM            gespeichert, basierend auf der vorher ermittelten Sprache.
REM ====================================================================
:Run
if /i "%LANG%"=="EN" (
  set "L_USAGE=Usage:"
  set "L_OPT=Options:"
  set "L_HELP_OPT=Shows this help page."
  set "L_HELP_DE=Forces English output."
  set "L_HELP_EN=Forces English output."
  set "L_HELP_NC=Disables colored output for this call (e.g. when redirecting to a file). Colors are switched off automatically for non-VT consoles and redirection; the switch NO_COLOR=1 at the top of the script disables them permanently."
  set "L_PARAM=Parameters:"
  set "L_HELP_PATH=(Required) The path to a file, directory, or a wildcard (e.g. *.txt)."
  set "L_HELP_PATH2=If a directory is specified, all files within it are processed recursively. Wildcards are supported."
  set "L_HELP_ALGO=(Optional) Sets the hash algorithm."
  set "L_HELP_ALGO2=If omitted, the algorithm is AUTO-DETECTED from the hashfile during comparison (32=MD5, 40=SHA1, 64=SHA256, 96=SHA384, 128=SHA512). Without a hashfile, the script default is used (Preset: %ALGO%). An explicit algorithm has priority. MD2/MD4 have length 32 and are detected as MD5 - specify them explicitly."
  set "L_HELP_HASH=(Optional) Path to a text file with reference hashes."
  set "L_HELP_HASH2=The script searches for the hash inside each line. It does not matter if the line contains only the hash or also a filename."
  set "L_AUTO_DETECT=Detecting algorithm from hashfile ..."
  set "L_AUTO_OK=Algorithm detected in hashfile:"
  set "L_AUTO_FAIL=No known hash found in hashfile - using default:"
  set "L_REDIR_TITLE=Shell Redirection (Save output to file):"
  set "L_REDIR_TEXT=You can redirect the console output directly to a text file to save the calculated hashes."
  set "L_REDIR_TEXT2=A single "^>" overwrites an existing file. A double "^>^>" appends the output to an existing file."
  set "L_EXAMPLES=Examples:"
  set "L_ERR_NO_PATH=Error: No path provided."
  set "L_ERR_HINT=Type "%SCRIPT_NAME% -h" to display help."
  set "L_ERR_HASHFILE=Hashfile not found"
  set "L_ERR_PATH_NOT_FOUND=Path, wildcard, or directory not found:"
  set "L_ERROR=ERROR"
) else (
  set "L_USAGE=Verwendung:"
  set "L_OPT=Optionen:"
  set "L_HELP_OPT=Zeigt diese Hilfeseite an."
  set "L_HELP_DE=Erzwingt die deutsche Ausgabe."
  set "L_HELP_EN=Erzwingt die englische Ausgabe."
  set "L_HELP_NC=Deaktiviert die Farbausgabe fuer diesen Aufruf (z.B. bei Umleitung in eine Datei). Bei nicht-VT-faehigen Konsolen und Umleitung werden Farben automatisch abgeschaltet; der Schalter NO_COLOR=1 oben im Skript schaltet sie dauerhaft ab."
  set "L_PARAM=Parameter:"
  set "L_HELP_PATH=(Erforderlich) Der Pfad zu einer Datei, einem Ordner oder ein Platzhalter (z.B. *.txt)."
  set "L_HELP_PATH2=Wenn ein Ordner angegeben wird, werden alle darin enthaltenen Dateien rekursiv geprueft. Platzhalter (Wildcards) werden unterstuetzt."
  set "L_HELP_ALGO=(Optional) Legt den Hash-Algorithmus fest."
  set "L_HELP_ALGO2=Wird dieser weggelassen, wird der Algorithmus beim Abgleich mit einer Hashdatei AUTOMATISCH aus der Hashdatei erkannt (32=MD5, 40=SHA1, 64=SHA256, 96=SHA384, 128=SHA512). Ohne Hashdatei gilt der Standard aus dem Script (Voreinstellung: %ALGO%). Eine explizite Angabe hat Vorrang. MD2/MD4 haben die Laenge 32 und werden als MD5 erkannt - bitte explizit angeben."
  set "L_HELP_HASH=(Optional) Pfad zu einer Textdatei mit Referenz-Hashes."
  set "L_HELP_HASH2=Das Script sucht nach dem Hash innerhalb jeder Zeile. Es ist egal, ob in der Zeile nur der Hash oder auch ein Dateiname steht."
  set "L_AUTO_DETECT=Erkenne Algorithmus aus der Hashdatei ..."
  set "L_AUTO_OK=Algorithmus aus Hashdatei erkannt:"
  set "L_AUTO_FAIL=Kein bekannter Hash in der Hashdatei erkannt - verwende Standard:"
  set "L_REDIR_TITLE=Shell-Umleitung (Ausgabe in Datei speichern):"
  set "L_REDIR_TEXT=Sie koennen die Bildschirmausgabe direkt in eine Textdatei umleiten, um die berechneten Hashwerte zu speichern."
  set "L_REDIR_TEXT2=Ein einzelnes "^>" ueberschreibt eine bestehende Datei. Ein doppeltes "^>^>" haengt die Ausgabe an eine bestehende Datei an."
  set "L_EXAMPLES=Beispiele:"
  set "L_ERR_NO_PATH=Fehler: Kein Pfad angegeben."
  set "L_ERR_HINT=Geben Sie "%SCRIPT_NAME% -h" ein, um die Hilfe anzuzeigen."
  set "L_ERR_HASHFILE=Hashdatei nicht gefunden"
  set "L_ERR_PATH_NOT_FOUND=Pfad, Platzhalter oder Ordner nicht gefunden:"
  set "L_ERROR=FEHLER"
)

REM Name: Hashdatei-Validierung
REM Erklaerung: Ueberprueft, ob eine Hashdatei angegeben wurde und ob diese tatsaechlich existiert.
if defined HASHFILE if not exist "%HASHFILE%" (
  echo %RED_H%%L_ERR_HASHFILE%%RESET%
  exit /b 1
)

REM ====================================================================
REM Name: Automatische Algorithmus-Erkennung (Hashdatei)
REM Erklaerung: Wurde kein Algorithmus explizit angegeben und eine
REM            Hashdatei uebergeben, wird der Algorithmus automatisch
REM            aus dem ersten gefundenen Hash der Datei erkannt
REM            (Hash-Laenge: 32=MD5, 40=SHA1, 64=SHA256, 96=SHA384,
REM            128=SHA512). Eine explizite Angabe hat Vorrang.
REM ====================================================================
if defined HASHFILE if not "%ALGO_EXPLICIT%"=="1" (
  echo !YELLOW_H!!L_AUTO_DETECT!!RESET!
  call :DetectAlgo
  if defined DA_ALGO (
    set "ALGO=!DA_ALGO!"
    echo !GREEN_O!!L_AUTO_OK!!RESET! !MAGENTA_L!!DA_ALGO!!RESET!
  ) else (
    echo !YELLOW_H!!L_AUTO_FAIL!!RESET! !MAGENTA_L!!ALGO!!RESET!
  )
  echo.
)

REM ====================================================================
REM Name: Wildcard-Erkennung (Sichere Methode)
REM Erklaerung: Prueft mit findstr, ob der Ziel-Parameter ein * oder ? enthaelt.
REM            Das ist sicherer als eine Textersetzung, da * sonst als 
REM            Systemvariable (%* = alle Parameter) fehlinterpretiert werden kann.
REM ====================================================================
echo !TARGET!| findstr /C:"*" >nul 2>&1 && goto :IsWildcard
echo !TARGET!| findstr /C:"?" >nul 2>&1 && goto :IsWildcard

REM ====================================================================
REM Name: Pfad-Routing
REM Erklaerung: Unterscheidet, ob der Ziel-Pfad ein Ordner oder eine Datei ist, 
REM            und startet dementsprechend die Hash-Berechnung.
REM ====================================================================
if exist "%TARGET%\*" (
  for /r "%TARGET%" %%F in (*) do call :One "%%~fF"
) else if exist "%TARGET%" (
  call :One "%TARGET%"
) else (
  echo %RED_H%%L_ERR_PATH_NOT_FOUND%%RESET% %MAGENTA_L%"%TARGET%"%RESET%
  exit /b 1
)
goto :EndRouting


REM ====================================================================
REM FUNKTION: IsWildcard
REM Name: Wildcard-Verarbeitung
REM Erklaerung: Wird aufgerufen, wenn * oder ? im Parameternamen steht.
REM            Verarbeitet alle Treffer im aktuellen (oder angegebenen) Ordner.
REM ====================================================================
:IsWildcard
set "FOUND=0"
for %%F in (%TARGET%) do (
  if exist "%%F" (
    set "FOUND=1"
    call :One "%%~fF"
  )
)

REM Name: Wildcard-Fehlerabfrage
REM Erklaerung: Wenn kein einziges File gefunden wurde, gibt es eine Fehlermeldung.
if "!FOUND!"=="0" (
  echo %RED_H%%L_ERR_PATH_NOT_FOUND%%RESET% %MAGENTA_L%"%TARGET%"%RESET%
  exit /b 1
)
:EndRouting

exit /b 0


REM ====================================================================
REM FUNKTION: Help
REM Name: Hilfeseite
REM Erklaerung: Gibt die lokalisierte Hilfeseite an. 
REM            Wird aufgerufen, sobald -h oder --help erkannt wird.
REM ====================================================================
:Help
REM Name: Hilfetext-Fallback
REM Erklaerung: Weil diese Funktion VOR der normalen Text-Zuweisung (:Run) 
REM            aufgerufen werden kann, sind die Variablen (wie L_USAGE) 
REM            zu diesem Zeitpunkt moeglicherweise noch leer. 
REM            Dieser Block fuellt die Variablen "im Notfall" mit den 
REM            wichtigsten Texten, damit die Hilfe immer funktioniert.
if not defined L_USAGE (
  if /i "%LANG%"=="EN" (
    set "L_USAGE=Usage:" & set "L_OPT=Options:" & set "L_HELP_OPT=Shows this help page." & set "L_HELP_DE=Forces German output." & set "L_HELP_EN=Forces English output." & set "L_HELP_NC=Disables colors for this call; NO_COLOR=1 at script top disables them permanently." & set "L_PARAM=Parameters:" & set "L_HELP_PATH=(Required) Path to a file, directory, or wildcard." & set "L_HELP_PATH2=Directories are processed recursively. Wildcards are supported." & set "L_HELP_ALGO=(Optional) Sets the hash algorithm." & set "L_HELP_ALGO2=If omitted, auto-detected from the hashfile (32=MD5, 40=SHA1, 64=SHA256, 96=SHA384, 128=SHA512). Valid values: MD2, MD4, MD5, SHA1, SHA256, SHA384, SHA512." & set "L_HELP_HASH=(Optional) Path to a hash file." & set "L_HELP_HASH2=Searches for the hash inside each line." & set "L_REDIR_TITLE=Shell Redirection:" & set "L_REDIR_TEXT=Redirect output to a file." & set "L_REDIR_TEXT2="^>" overwrites, "^>^>" appends." & set "L_EXAMPLES=Examples:"
  ) else (
    set "L_USAGE=Verwendung:" & set "L_OPT=Optionen:" & set "L_HELP_OPT=Zeigt diese Hilfeseite an." & set "L_HELP_DE=Erzwingt die deutsche Ausgabe." & set "L_HELP_EN=Erzwingt die englische Ausgabe." & set "L_HELP_NC=Deaktiviert Farben fuer diesen Aufruf; NO_COLOR=1 oben im Skript schaltet dauerhaft ab." & set "L_PARAM=Parameter:" & set "L_HELP_PATH=(Erforderlich) Pfad zu einer Datei, einem Ordner oder einem Platzhalter." & set "L_HELP_PATH2=Ordner werden rekursiv verarbeitet. Platzhalter werden unterstuetzt." & set "L_HELP_ALGO=(Optional) Legt den Hash-Algorithmus fest." & set "L_HELP_ALGO2=Wird weggelassen: automatische Erkennung aus der Hashdatei (32=MD5, 40=SHA1, 64=SHA256, 96=SHA384, 128=SHA512). Gueltige Werte: MD2, MD4, MD5, SHA1, SHA256, SHA384, SHA512." & set "L_HELP_HASH=(Optional) Pfad zu einer Hash-Datei." & set "L_HELP_HASH2=Sucht den Hash innerhalb jeder Zeile." & set "L_REDIR_TITLE=Shell-Umleitung:" & set "L_REDIR_TEXT=Ausgabe in Datei umleiten." & set "L_REDIR_TEXT2="^>" ueberschreibt, "^>^>" haengt an." & set "L_EXAMPLES=Beispiele:"
  )
)

REM Name: Ausgabe der Hilfe
REM Erklaerung: Gibt die formatierte Hilfe unter Verwendung der zuvor geladenen Variablen aus.
echo.
echo %CYAN_H%%L_USAGE% %SCRIPT_NAME% [Option] "Path" [Algorithm] [Hashfile]%RESET%
echo.
echo %CYAN_H%%L_OPT%%RESET%
echo   %MAGENTA_L%-h --help /? -?%RESET%  %YELLOW_H%%L_HELP_OPT%%RESET%
echo   %MAGENTA_L%-de%RESET%            %YELLOW_H%%L_HELP_DE%%RESET%
echo   %MAGENTA_L%-en%RESET%            %YELLOW_H%%L_HELP_EN%%RESET%
echo   %MAGENTA_L%-nc%RESET%            %YELLOW_H%%L_HELP_NC%%RESET%
echo.
echo %CYAN_H%%L_PARAM%%RESET%
echo   %MAGENTA_L%"Path"%RESET%         %YELLOW_H%%L_HELP_PATH%%RESET%
echo                  %YELLOW_H%%L_HELP_PATH2%%RESET%
echo.
echo   %MAGENTA_L%[Algorithm]%RESET%    %YELLOW_H%%L_HELP_ALGO%%RESET%
echo                  %YELLOW_H%%L_HELP_ALGO2%%RESET%
echo.
echo   %MAGENTA_L%[Hashfile]%RESET%     %YELLOW_H%%L_HELP_HASH%%RESET%
echo                  %YELLOW_H%%L_HELP_HASH2%%RESET%
echo.
echo %CYAN_H%%L_REDIR_TITLE%%RESET%
echo   %YELLOW_H%%L_REDIR_TEXT%%RESET%
echo   %YELLOW_H%%L_REDIR_TEXT2%%RESET%
echo.
echo %CYAN_H%%L_EXAMPLES%%RESET%
echo   %MAGENTA_L%%SCRIPT_NAME% "C:\MyFile.exe"%RESET%
echo   %MAGENTA_L%%SCRIPT_NAME% -en "C:\MyFile.exe" MD5%RESET%
echo   %MAGENTA_L%%SCRIPT_NAME% "C:\MyFolder" SHA256 "C:\Hashes.txt" -de%RESET%
echo   %MAGENTA_L%%SCRIPT_NAME% * .\sha.txt%RESET%
echo   %MAGENTA_L%%SCRIPT_NAME% * ^> sha.txt%RESET%
echo   %MAGENTA_L%%SCRIPT_NAME% * ^>^> sha.txt%RESET%
echo.
exit /b 0


REM ====================================================================
REM FUNKTION: One
REM Name: Hash-Berechnung und Vergleich (OPTIMIERTE VERSION)
REM Erklaerung: Berechnet den Hash und vergleicht ihn blitzschnell 
REM            mit der Referenzdatei, ohne das System aufzuhaengen.
REM ====================================================================
:One
set "FILE=%~1"
set "H="

REM Name: Hash-Auslesen
REM Erklaerung: Fuehrt certutil fuer die aktuelle Datei aus. 
REM            "skip=1" ueberspringt die erste Zeile (Algorithmus-Name). 
REM            Die zweite Zeile enthaelt den reinen Hash-Wert und wird in 
REM            der Variable H gespeichert.
for /f "skip=1 delims=" %%H in ('certutil -hashfile "%FILE%" %ALGO%') do (
  if not defined H set "H=%%H"
)

REM Name: Fehlerabfrage
REM Erklaerung: Wenn certutil keinen Hash zurueckgeben konnte (z.B. wegen 
REM            fehlender Leserechte), ist die Variable H leer. 
REM            In diesem Fall wird ein Fehlertext ausgegeben.
if not defined H (
  echo %RED_H%[%L_ERROR%]%RESET% %MAGENTA_L%"%FILE%"%RESET%
  exit /b 0
)

REM Name: Hash-Vergleichs-Logik
REM Erklaerung: Prueft, ob im Hauptprogramm eine Hashdatei uebergeben wurde.
if defined HASHFILE (
  set "O=0"
  
  REM Name: Hash bereinigen
  REM Erklaerung: Entfernt alle Leerzeichen aus dem von certutil berechneten Hash 
  REM            (z.B. "d5 54 a1" wird zu "d554a1").
  set "H_CLEAN=!H: =!"
  
  REM Name: Blitzschneller Datei-Vergleich (LF/CRLF/BOM-Kompatibilitaet)
  REM Erklaerung: findstr ignoriert Dateien mit Unix-Zeilenenden (LF) komplett, 
  REM            wenn sie nicht mit CRLF enden (bekannter Windows-Bug). 
  REM            Um dieses Problem zu umgehen, leiten wir die Datei durch "more". 
  REM            "more" konvertiert LF-Zeilenenden zuverlaessig in CRLF und 
  REM            umgeht stoerende Kodierungen, sodass findstr den Hash garantiert findet.
  more "%HASHFILE%" | findstr /i /c:"!H_CLEAN!" >nul 2>&1
  if !errorlevel! equ 0 set "O=1"
  
  REM Name: Ergebnis-Ausgabe (mit Vergleich)
  REM Erklaerung: Wertet die Variable O aus und gibt [OK] oder [FAIL] aus.
  if "!O!"=="1" (
    echo %GREEN_O%[OK]%RESET%   %MAGENTA_L%"%FILE%"%RESET% = %YELLOW_H%!H!%RESET%
  ) else (
    echo %RED_H%[FAIL]%RESET% %MAGENTA_L%"%FILE%"%RESET% = %YELLOW_H%!H!%RESET%
  )
) else (
  REM Name: Ergebnis-Ausgabe (ohne Vergleich)
  REM Erklaerung: Wenn keine Hashdatei angegeben war, wird der berechnete 
  REM            Hash einfach nur direkt in der Konsole angezeigt.
  echo %MAGENTA_L%"%FILE%"%RESET% = %YELLOW_H%!H!%RESET%
)

exit /b 0


REM ====================================================================
REM FUNKTION: DetectAlgo
REM Name: Automatische Algorithmus-Erkennung aus der Hashdatei
REM Erklaerung: Reines Batch - KEINE Kindprozesse (kein PowerShell und
REM            kein cmd-Kind via for /f-Backquote; genau dieser fruehere
REM            PS-Aufruf lief beim Abgleich und veraenderte die Konsolen-
REM            Fenstergroesse). Erkennt die erste Hex-Zeichenfolge, die
REM            exakt einer Hash-Laenge entspricht (32=MD5, 40=SHA1,
REM            64=SHA256, 96=SHA384, 128=SHA512):
REM            Stufe 1: Token-Scan der Zeile - erkennt sha256sum-Format
REM            "hash  datei" und csum-Ausgabe '"pfad" = hash' auch dann,
REM            wenn der Dateiname mit Hex-Zeichen (a-f) beginnt.
REM            Stufe 2: Zeile ohne Leerzeichen als Ganzes - erkennt
REM            certutil-Spaced-Hashes auf eigener Zeile.
REM            MD2/MD4 sind ebenfalls 32 Zeichen lang und werden als
REM            MD5 interpretiert - fuer sie muss man explizit angeben.
REM            Scheitert die Erkennung, bleibt der Standard-ALGO aktiv.
REM ====================================================================
:DetectAlgo
set "DA_ALGO="
for /f "usebackq delims=" %%L in ("%HASHFILE%") do if not defined DA_ALGO (
  set "DA_LINE=%%L"
  call :DaScanTokens
  if not defined DA_ALGO (
    set "DA_CLEAN=!DA_LINE: =!"
    call :DaScanWhole
  )
)
if defined DA_ALGO set "ALGO=!DA_ALGO!"
exit /b 0

REM Name: Token-Scan (Stufe 1)
REM Erklaerung: Zerlegt die Zeile in Leerzeichen-Token und prueft jeden,
REM            ob er ein reiner Hex-String EXAKTER Hash-Laenge ist.
:DaScanTokens
set "DA_REST=!DA_LINE!"
:DaTokLoop
if not defined DA_REST exit /b 0
for /f "tokens=1*" %%a in ("!DA_REST!") do (
  set "DA_TOK=%%a"
  set "DA_REST=%%b"
  call :DaCheckLen
)
goto DaTokLoop

REM Name: Ganzzeilen-Scan (Stufe 2)
REM Erklaerung: Prueft die leerzeichenbereinigte Zeile als Ganzes.
:DaScanWhole
if not defined DA_CLEAN exit /b 0
set "DA_TOK=!DA_CLEAN!"
call :DaCheckLen
exit /b 0

REM Name: Laengen- und Hex-Pruefung eines Kandidaten
REM Erklaerung: DA_TOK muss reines Hex sein UND exakt eine Hash-Laenge
REM            haben (Substring-Grenzen: Position n leer = laenger als
REM            n nicht moeglich, Position n-1 belegt = genau n Zeichen).
:DaCheckLen
if not defined DA_TOK exit /b 0
set "DA_HEX=0"
echo(!DA_TOK!| findstr /r /i "^[0-9A-F][0-9A-F]*$" >nul 2>&1 && set "DA_HEX=1"
if "!DA_HEX!"=="0" exit /b 0
for %%n in (128 96 64 40 32) do if not defined DA_ALGO (
  set /a DA_N1=%%n-1
  for %%m in (!DA_N1!) do (
    if "!DA_TOK:~%%n!"=="" if not "!DA_TOK:~%%m,1!"=="" (
      if "%%n"=="128" set "DA_ALGO=SHA512"
      if "%%n"=="96" set "DA_ALGO=SHA384"
      if "%%n"=="64" set "DA_ALGO=SHA256"
      if "%%n"=="40" set "DA_ALGO=SHA1"
      if "%%n"=="32" set "DA_ALGO=MD5"
    )
  )
)
exit /b 0