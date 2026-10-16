#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%
#Persistent
#SingleInstance, Force
if (!A_IsCompiled && FileExist(A_ScriptDir "\Epub.ico"))
    Menu, Tray, Icon, %A_ScriptDir%\Epub.ico

global originalLines := []
global formattedLines := []
global lineMap := []
global currentLine := 1
global lastFile := ""
global _settingsini := A_ScriptDir "\settings.ini"
global _epubdir := A_ScriptDir "\TXT"
global mainHwnd := 0
global guiHover := false
global lastSearchTerm := ""
global lastSearchIdx := 0
global bgColor := "E8EFE9"
global fgColor := "23813B"

FileCreateDir, %_epubdir%

    ; --- Cargar colores guardados (RRGGBB) ---
    IniRead, bgColor, %_settingsini%, Colors, Background, E8EFE9
    IniRead, fgColor, %_settingsini%, Colors, Foreground, 23813B
    if (!RegExMatch(bgColor, "^[0-9A-Fa-f]{6}$"))
        bgColor := "E8EFE9"
    if (!RegExMatch(fgColor, "^[0-9A-Fa-f]{6}$"))
        fgColor := "23813B"

    Gui, +AlwaysOnTop -Caption +Border +ToolWindow +Owner
    Gui, Color, %bgColor%, %bgColor%
    ;Gui, Font, s10 bold c23813b, Consolas
    Gui, Font, s10 c%fgColor%, Verdana
    editW := A_ScreenWidth - 55
    Gui, Add, Edit, x0 y0 w%editW% h20 vText ReadOnly -E0x200 -VScroll -HScroll
    Gui, Add, Text, x%editW% y0 w50 h20 vPctText Right, 0`%
    Gui, Show, x0 y0 w%A_ScreenWidth% h20

    Gui, +LastFound
    mainHwnd := WinExist()

    Menu, Tray, NoStandard
    Menu, Tray, Add, Abrir archivo, OpenFile
    Menu, Tray, Add, Buscar texto, SearchText
    Menu, Tray, Add, Buscar siguiente (F3), SearchNext

    Menu, RecentMenu, Add
    Menu, Tray, Add, Archivos recientes, :RecentMenu

    Menu, ColoresMenu, Add, Color de fondo..., ChooseBgColor
    Menu, ColoresMenu, Add, Color de letra..., ChooseFgColor
    Menu, ColoresMenu, Add
    Menu, ColoresMenu, Add, Restaurar colores originales, ResetColors
    Menu, Tray, Add, Colores, :ColoresMenu

    Menu, Tray, Add, Salir, ExitScript
    Menu, Tray, Default, Abrir archivo

    Menu, RecentMenu, Add

    ; --- Restaurar ultima sesion ---
    IniRead, lastFile, %_settingsini%, General, LastFile
    if (lastFile != "ERROR" && FileExist(lastFile)) {
        IniRead, currentLine, %_settingsini%, %lastFile%, LastLine
        if (currentLine = "ERROR")
            currentLine := 1

        SplitPath, lastFile,,, fileExt
        if (fileExt = "epub") {
            txtPath := ""
            IniRead, txtPath, %_settingsini%, Converted, %lastFile%
            if (txtPath = "ERROR" || !FileExist(txtPath)) {
                MsgBox, 48, Error, No se encontro el TXT convertido para este EPUB.
                lastFile := ""
            } else {
                lastFile := txtPath
            }
        }

        if (lastFile != "")
            LoadFile(lastFile)

        if (formattedLines.Length() = 0)
            currentLine := 1
        else if (currentLine < 1 || currentLine > formattedLines.Length())
            currentLine := 1

        ShowLine()
    }

    BuildRecentMenu()
    SetTimer, CheckGuiHover, 50
Return

; ==================== ARCHIVOS ====================

OpenFile() {
    global lastFile, currentLine, _settingsini, _epubdir

    FileSelectFile, filePath,,, Selecciona un archivo TXT/EPUB, Documentos (*.txt; *.epub)|*.txt; *.epub
    if (!filePath)
        return

    SplitPath, filePath,,, fileExt
    if (fileExt = "epub") {
        txtPath := ""
        IniRead, txtPath, %_settingsini%, Converted, %filePath%
        if (txtPath = "ERROR" || !FileExist(txtPath))
            txtPath := ConvertEpub(filePath)
        if (txtPath = "")
            return
        filePath := txtPath
    }

    lastFile := filePath
    LoadFile(filePath)

    IniRead, currentLine, %_settingsini%, %lastFile%, LastLine
    if (currentLine = "ERROR")
        currentLine := 1

    if (formattedLines.Length() = 0)
        currentLine := 1
    else if (currentLine < 1 || currentLine > formattedLines.Length())
        currentLine := 1

    ShowLine()

    IniWrite, %lastFile%, %_settingsini%, General, LastFile
    UpdateRecentList(filePath)
    BuildRecentMenu()
}

OpenRecent(filePath) {
    global lastFile, currentLine, _settingsini

    SplitPath, filePath,,, fileExt
    if (fileExt = "epub") {
        txtPath := ""
        IniRead, txtPath, %_settingsini%, Converted, %filePath%
        if (txtPath = "ERROR" || !FileExist(txtPath))
            txtPath := ConvertEpub(filePath)
        if (txtPath = "")
            return
        filePath := txtPath
    }

    lastFile := filePath
    LoadFile(filePath)

    IniRead, currentLine, %_settingsini%, %lastFile%, LastLine
    if (currentLine = "ERROR")
        currentLine := 1

    if (formattedLines.Length() = 0)
        currentLine := 1
    else if (currentLine < 1 || currentLine > formattedLines.Length())
        currentLine := 1

    ShowLine()

    IniWrite, %lastFile%, %_settingsini%, General, LastFile
    UpdateRecentList(filePath)
    BuildRecentMenu()
}

UpdateRecentList(filePath) {
    global _settingsini

    IniRead, recent, %_settingsini%, General, RecentFiles
    if (recent = "ERROR")
        recent := ""

    arr := StrSplit(recent, "|")
    newArr := []
    newArr.Push(filePath)

    for i, f in arr {
        if (f != "" && f != filePath)
            newArr.Push(f)
    }

    while (newArr.Length() > 10)
        newArr.RemoveAt(newArr.Length())

    out := ""
    for i, f in newArr {
        if (out = "")
            out := f
        else
            out := out "|" f
    }

    IniWrite, %out%, %_settingsini%, General, RecentFiles
}

BuildRecentMenu() {
    global _settingsini

    Menu, RecentMenu, DeleteAll

    IniRead, recent, %_settingsini%, General, RecentFiles
    if (recent = "ERROR" || recent = "")
        return

    arr := StrSplit(recent, "|")
    for i, f in arr {
        Menu, RecentMenu, Add, %f%, RecentHandler
    }
}

RecentHandler:
    OpenRecent(A_ThisMenuItem)
return

; ==================== LECTURA ====================

LoadFile(filePath) {
    global originalLines, formattedLines, lineMap

    originalLines := []
    formattedLines := []
    lineMap := []

    FileRead, content, *P65001 %filePath%

    fragIndex := 1

    Loop, Parse, content, `n, `r
    {
        originalLines.Push(A_LoopField)
        lineMap.Push(fragIndex)

        fragCount := ProcessLine(A_LoopField)
        fragIndex += fragCount
    }
}

ProcessLine(line) {
    global formattedLines

    maxLen := 150
    count := 0

    while (StrLen(line) > maxLen) {
        cutPos := maxLen

        charAt150 := SubStr(line, maxLen, 1)
        charAt151 := SubStr(line, maxLen + 1, 1)

        if (charAt150 != " " && charAt150 != "`t" && charAt151 != " " && charAt151 != "`t") {
            prefix := SubStr(line, 1, maxLen)

            lastSpace := InStr(prefix, " ", false, -1)
            lastTab := InStr(prefix, "`t", false, -1)

            lastBreak := (lastSpace > lastTab) ? lastSpace : lastTab

            if (lastBreak > 1)
                cutPos := lastBreak - 1
        }

        fragment := SubStr(line, 1, cutPos)
        line := SubStr(line, cutPos + 1)

        fragment := RTrim(fragment, " `t")
        line := LTrim(line, " `t")

        formattedLines.Push(fragment)
        count++
    }

    formattedLines.Push(line)
    count++
    return count
}

; ==================== EPUB -> TXT ====================

ConvertEpub(epubPath) {
    global _settingsini, _epubdir

    CreateConversionGui()
    LogStep("Iniciando conversion de EPUB...")
    
    tempRoot := A_Temp "\EPUBAHK"
    FileCreateDir, %tempRoot%
    Random, rnd, 100000, 999999
    tempDir := tempRoot "\" A_Now "_" rnd
    FileCreateDir, %tempDir%
    LogStep("Directorio temporal creado: " tempDir)

    zipPath := tempDir "\book.zip"
    LogStep("Copiando EPUB a archivo temporal...")
    FileCopy, %epubPath%, %zipPath%
    if (!FileExist(zipPath)) {
        LogStep("ERROR: No se pudo copiar el EPUB.", true)
        FileRemoveDir, %tempDir%, 1
        DestroyConversionGui()
        return ""
    }
    LogStep("EPUB copiado correctamente.")

    extractDir := tempDir "\content"
    FileCreateDir, %extractDir%
    LogStep("Extrayendo contenido del EPUB...")

    sevenZ := ""
    if (FileExist(A_ProgramFiles "\7-Zip\7z.exe"))
        sevenZ := A_ProgramFiles "\7-Zip\7z.exe"
    else if (FileExist(A_ProgramFiles " (x86)\7-Zip\7z.exe"))
        sevenZ := A_ProgramFiles " (x86)\7-Zip\7z.exe"

    if (sevenZ != "") {
        LogStep("Usando 7-Zip para extraccion...")
        RunWait, "%sevenZ%" x "%zipPath%" -o"%extractDir%" -y,, Hide
    } else {
        LogStep("7-Zip no encontrado, usando Shell.Application...")
        shell := ComObjCreate("Shell.Application")
        srcZip := shell.Namespace(zipPath)
        if (IsObject(srcZip)) {
            dstFolder := shell.Namespace(extractDir)
            dstFolder.CopyHere(srcZip.Items(), 0x14)
            start := A_TickCount
            lastCount := -1
            stable := 0
            Loop {
                ; cuenta los archivos extraidos hasta que el numero deje de cambiar
                cnt := 0
                Loop, Files, %extractDir%\*.*, R
                    cnt++

                if (FileExist(extractDir "\META-INF\container.xml") && cnt > 0 && cnt = lastCount) {
                    stable++
                    if (stable >= 4)   ; ~2 segundos sin cambios = extraccion terminada
                        break
                } else {
                    stable := 0
                }
                lastCount := cnt

                if (A_TickCount - start > 60000)
                    break
                Sleep, 500
            }
        }
    }

    if (!FileExist(extractDir "\META-INF\container.xml")) {
        LogStep("ERROR: No se pudo extraer el EPUB. Instale 7-Zip para mejor compatibilidad.", true)
        FileRemoveDir, %tempDir%, 1
        DestroyConversionGui()
        return ""
    }
    LogStep("EPUB extraido correctamente.")

    title := ""
    opfPath := FindOpf(extractDir)
    if (opfPath != "") {
        LogStep("OPF encontrado: " opfPath)
        title := GetEpubTitle(opfPath)
        LogStep("Titulo extraido: " title)
    } else {
        LogStep("No se encontro archivo OPF.", true)
    }

    SplitPath, epubPath,,, , epubName
    txtName := (title != "") ? title : epubName
    txtName := SanitizeFilename(txtName)
    if (txtName = "")
        txtName := "epub"
    txtPath := _epubdir "\" txtName ".txt"

    n := 1
    while (FileExist(txtPath)) {
        txtPath := _epubdir "\" txtName "_" n ".txt"
        n++
    }
    LogStep("Archivo de salida: " txtPath)

    allLines := []

    LogStep("Buscando documentos del libro...")
    docs := []
    if (opfPath != "")
        docs := GetOrderedDocs(opfPath)

    if (docs.Length() = 0) {
        LogStep("No se pudo leer el orden del OPF; se usa el orden de archivos.")
        Loop, Files, %extractDir%\*.xhtml, R
            docs.Push(A_LoopFileFullPath)
        Loop, Files, %extractDir%\*.html, R
            docs.Push(A_LoopFileFullPath)
    }

    totalFiles := docs.Length()
    LogStep("Documentos encontrados: " totalFiles)

    if (totalFiles = 0) {
        LogStep("ERROR: No se encontro texto legible dentro del EPUB.", true)
        FileRemoveDir, %tempDir%, 1
        DestroyConversionGui()
        return ""
    }

    SetProgressRange(0, totalFiles)
    processed := 0

    for i, p in docs {
        processed++
        LogStep("Procesando documento " processed "/" totalFiles ": " GetFileName(p))
        UpdateProgress(processed, totalFiles, "Procesando: " GetFileName(p))

        chunk := []
        AppendDocText(p, chunk)
        if (chunk.Length() > 0) {
            if (allLines.Length() > 0)
                allLines.Push("#######################################################################")
            for j, ln in chunk
                allLines.Push(ln)
        }
    }

    LogStep("Documentos procesados: " processed ", lineas extraidas: " allLines.Length())
    
    if (allLines.Length() = 0) {
        LogStep("ERROR: No se pudo extraer texto de los archivos.", true)
        FileRemoveDir, %tempDir%, 1
        DestroyConversionGui()
        return ""
    }

    UpdateProgress(totalFiles, totalFiles, "Generando archivo TXT...")
    LogStep("Escribiendo archivo TXT...")
    
    out := ""
    for i, line in allLines
        out .= line "`r`n"

    FileAppend, %out%, %txtPath%, UTF-8
    LogStep("Archivo TXT creado: " txtPath)

    FileRemoveDir, %tempDir%, 1
    LogStep("Limpieza de archivos temporales completada.")

    IniWrite, %txtPath%, %_settingsini%, Converted, %epubPath%
    LogStep("Conversion completada exitosamente.")
    
    Sleep, 1000
    DestroyConversionGui()

    return txtPath
}

CreateConversionGui() {
    global convGuiHwnd, convGuiLogHwnd, convGuiProgressHwnd, ConvProgress, ConvStatus, ConvLog
    
    Gui, Conv:New, +AlwaysOnTop +ToolWindow +Owner, Conversión EPUB
    Gui, Conv:Color, E8EFE9
    Gui, Conv:Font, s9, Verdana
    Gui, Conv:Add, Text, x10 y10 w400 h20, Progreso de conversión:
    Gui, Conv:Add, Progress, x10 y35 w460 h20 vConvProgress cGreen, 0
    Gui, Conv:Add, Text, x10 y60 w460 h20 vConvStatus, Iniciando...
    Gui, Conv:Add, Edit, x10 y85 w460 h250 vConvLog ReadOnly -VScroll +HScroll
    Gui, Conv:Show, xCenter yCenter w480 h360, Conversión EPUB a TXT
    
    Gui, Conv:+LastFound
    convGuiHwnd := WinExist()
    GuiControlGet, convGuiLogHwnd, Hwnd, ConvLog
    GuiControlGet, convGuiProgressHwnd, Hwnd, ConvProgress
}

DestroyConversionGui() {
    global convGuiHwnd
    if (convGuiHwnd) {
        Gui, Conv:Destroy
        convGuiHwnd := 0
    }
    Gui, 1:Default   ; devuelve la GUI principal como predeterminada
}

LogStep(message, isError := false) {
    global convGuiHwnd, convGuiLogHwnd
    if (!convGuiHwnd)
        return
    Gui, Conv:Default
    
    timestamp := A_Hour ":" A_Min ":" A_Sec
    prefix := isError ? "[ERROR] " : "[OK]   "
    logEntry := "[" timestamp "] " prefix message "`n"
    
    GuiControlGet, currentLog,, ConvLog
    newLog := currentLog logEntry
    GuiControl,, ConvLog, % newLog
    
    ControlSend,, ^{End}, ahk_id %convGuiLogHwnd%
    
    if (isError)
        SoundPlay, *48
}

SetProgressRange(min, max) {
    global convGuiHwnd
    if (!convGuiHwnd)
        return
    Gui, Conv:Default
    GuiControl, +Range%min%-%max%, ConvProgress
    GuiControl,, ConvProgress, % min
}

UpdateProgress(current, max, status := "") {
    global convGuiHwnd
    if (!convGuiHwnd)
        return
    Gui, Conv:Default
    
    pct := Floor(current / max * 100)
    GuiControl,, ConvProgress, % current
    if (status != "")
        GuiControl,, ConvStatus, % status " (" pct "%)"
}

GetFileName(path) {
    SplitPath, path,,, , name
    return name
}

GetEpubTitle(opfPath) {
    FileRead, opf, *P65001 %opfPath%
    if (ErrorLevel)
        return ""
    if (RegExMatch(opf, "i)<dc:title\b[^>]*>([^<]*)</dc:title>", m))
        return m1
    return ""
}

SanitizeFilename(name) {
    name := RegExReplace(name, "[\\/:*?""<>|]+", "")
    name := RegExReplace(name, "\s+", "_")
    name := Trim(name, "._")
    return name
}

; ==================== HELPERS EPUB ====================

AppendDocText(docPath, ByRef outLines) {
    if (!FileExist(docPath))
        return

    FileRead, html, *P65001 %docPath%
    if (ErrorLevel || html = "")
        return

    txt := HtmlToText(html)

    Loop, Parse, txt, `n, `r
    {
        line := RegExReplace(A_LoopField, "\s+", " ")
        line := Trim(line)
        if (line != "")
            outLines.Push(line)
    }
}

HtmlToText(html) {
    txt := html

    txt := RegExReplace(txt, "is)<\?xml[^>]*>")
    txt := RegExReplace(txt, "is)<!DOCTYPE[^>]*>")
    txt := RegExReplace(txt, "is)<!--.*?-->")
    txt := RegExReplace(txt, "is)<head\b.*?</head>")
    txt := RegExReplace(txt, "is)<(script|style)\b.*?</\1>")

    txt := RegExReplace(txt, "i)<\s*br\b[^>]*>", "`n")
    txt := RegExReplace(txt, "is)<\s*/?\s*(p|div|h[1-6]|li|tr|td|th|table|thead|tbody|ul|ol|dl|dd|dt|blockquote|pre|section|article|aside|nav|figure|figcaption|hr|body|title)\b[^>]*>", "`n")

    txt := RegExReplace(txt, "s)<[^>]*>")

    txt := DecodeEntities(txt)

    return txt
}

DecodeEntities(s) {
    named := {}
    named["nbsp"] := " "
    named["lt"] := "<"
    named["gt"] := ">"
    named["quot"] := """"
    named["apos"] := "'"
    named["iexcl"] := Chr(161)
    named["iquest"] := Chr(191)
    named["aacute"] := Chr(225)
    named["eacute"] := Chr(233)
    named["iacute"] := Chr(237)
    named["oacute"] := Chr(243)
    named["uacute"] := Chr(250)
    named["uuml"] := Chr(252)
    named["ntilde"] := Chr(241)
    named["Ntilde"] := Chr(209)
    named["Aacute"] := Chr(193)
    named["Eacute"] := Chr(201)
    named["Iacute"] := Chr(205)
    named["Oacute"] := Chr(211)
    named["Uacute"] := Chr(218)
    named["Uuml"] := Chr(220)
    named["agrave"] := Chr(224)
    named["egrave"] := Chr(232)
    named["ccedil"] := Chr(231)
    named["laquo"] := Chr(171)
    named["raquo"] := Chr(187)
    named["deg"] := Chr(176)
    named["middot"] := Chr(183)
    named["bull"] := Chr(8226)
    named["hellip"] := Chr(8230)
    named["mdash"] := Chr(8212)
    named["ndash"] := Chr(8211)
    named["lsquo"] := Chr(8216)
    named["rsquo"] := Chr(8217)
    named["ldquo"] := Chr(8220)
    named["rdquo"] := Chr(8221)
    named["copy"] := Chr(169)
    named["reg"] := Chr(174)
    named["trade"] := Chr(8482)
    named["shy"] := ""

    for name, rep in named
        s := StrReplace(s, "&" name ";", rep)

    while (RegExMatch(s, "&#[xX][0-9a-fA-F]+;", m)) {
        hexVal := SubStr(m, 4, -1)
        code := ("0x" hexVal) + 0
        s := StrReplace(s, m, (code > 0 && code <= 1114111) ? Chr(code) : "")
    }

    while (RegExMatch(s, "&#[0-9]+;", m)) {
        digits := SubStr(m, 3, -1)
        code := digits + 0
        s := StrReplace(s, m, (code > 0 && code <= 1114111) ? Chr(code) : "")
    }

    s := StrReplace(s, "&amp;", "&")

    return s
}

GetAttr(text, name) {
    if (RegExMatch(text, "i)" name "\s*=\s*""([^""]*)""", m))
        return m1
    if (RegExMatch(text, "i)" name "\s*=\s*'([^']*)'", m))
        return m1
    return ""
}

FindOpf(root) {
    container := root "\META-INF\container.xml"

    if (FileExist(container)) {
        FileRead, xml, *P65001 %container%
        if (!ErrorLevel) {
            fullPath := GetAttr(xml, "full-path")
            if (fullPath != "") {
                cand := root "\" StrReplace(fullPath, "/", "\")
                if (FileExist(cand))
                    return cand
            }
        }
    }

    Loop, Files, %root%\*.opf, R
        return A_LoopFileFullPath

    return ""
}

GetOrderedDocs(opfPath) {
    docs := []
    seen := {}

    FileRead, opf, *P65001 %opfPath%
    if (ErrorLevel || opf = "")
        return docs

    SplitPath, opfPath,, opfDir

    ; --- manifest: id -> href ---
    manifest := {}
    pos := 1
    while (p := RegExMatch(opf, "isO)<item\s[^>]*>", mItem, pos)) {
        tag := mItem.Value()
        id := GetAttr(tag, "id")
        href := GetAttr(tag, "href")
        if (id != "" && href != "")
            manifest[id] := href
        pos := p + mItem.Len()
    }

    ; --- spine: orden real de lectura ---
    if (RegExMatch(opf, "isO)<spine\b.*?</spine>", mSpine)) {
        spineXml := mSpine.Value()
        spos := 1
        while (q := RegExMatch(spineXml, "isO)<itemref\s[^>]*>", mRef, spos)) {
            idRef := GetAttr(mRef.Value(), "idref")
            if (manifest.HasKey(idRef)) {
                path := ResolveDocPath(opfDir, manifest[idRef])
                if (FileExist(path) && !seen.HasKey(path)) {
                    seen[path] := true
                    docs.Push(path)
                }
            }
            spos := q + mRef.Len()
        }
    }

    return docs
}

ResolveDocPath(baseDir, href) {
    path := StrReplace(href, "/", "\")
    path := StrReplace(path, "%20", A_Space)

    hash := InStr(path, "#")
    if (hash)
        path := SubStr(path, 1, hash - 1)

    while (SubStr(path, 1, 3) = "..\") {
        path := SubStr(path, 4)
        parent := ""
        SplitPath, baseDir,, parent
        baseDir := parent
    }

    if (SubStr(path, 1, 2) = ".\")
        path := SubStr(path, 3)

    if (baseDir != "")
        return baseDir "\" path
    return path
}

; ==================== UI ====================

ShowLine() {
    global formattedLines, currentLine, mainHwnd

    Gui, 1:Default   ; asegura que se actua sobre la GUI principal

    if (formattedLines.Length() > 0) {
        if (currentLine < 1)
            currentLine := 1

        if (currentLine > formattedLines.Length())
            currentLine := formattedLines.Length()

        GuiControl,, Text, % formattedLines[currentLine]
        pct := Floor((currentLine - 1) / formattedLines.Length() * 100)
        GuiControl,, PctText, %pct%`%
        SendMessage, 0x115, 0, 0, Edit1, ahk_id %mainHwnd%
    }
}

SearchText() {
    global lastSearchTerm, lastSearchIdx

    InputBox, searchTerm, Buscar texto, Ingresa el texto a buscar:,,,,,,,,%lastSearchTerm%
    if (ErrorLevel || searchTerm = "")
        return

    lastSearchTerm := searchTerm
    lastSearchIdx := 0
    SearchNext()
}

SearchNext() {
    global originalLines, lineMap, currentLine, lastSearchTerm, lastSearchIdx

    if (lastSearchTerm = "") {
        SearchText()
        return
    }

    total := originalLines.Length()
    i := lastSearchIdx + 1
    while (i <= total) {
        if InStr(originalLines[i], lastSearchTerm) {
            lastSearchIdx := i
            currentLine := lineMap[i]
            ShowLine()
            ShowTip("Linea real " i " de " total "  -  F3: siguiente")
            return
        }
        i++
    }

    if (lastSearchIdx = 0)
        ShowTip("No se encontro """ lastSearchTerm """")
    else
        ShowTip("No hay mas coincidencias. F3 vuelve a buscar desde el inicio.")
    lastSearchIdx := 0
}

ShowTip(msg) {
    ToolTip, %msg%, 10, 30
    SetTimer, HideTip, -2500
}

HideTip:
    ToolTip
return

F3::SearchNext()

; ==================== COLORES ====================

ChooseBgColor() {
    global bgColor

    c := PickColor(("0x" bgColor) + 0)
    if (c = "")
        return
    bgColor := c
    ApplyColors()
    SaveColors()
}

ChooseFgColor() {
    global fgColor

    c := PickColor(("0x" fgColor) + 0)
    if (c = "")
        return
    fgColor := c
    ApplyColors()
    SaveColors()
}

ResetColors() {
    global bgColor, fgColor

    bgColor := "E8EFE9"
    fgColor := "23813B"
    ApplyColors()
    SaveColors()
}

ApplyColors() {
    global bgColor, fgColor, mainHwnd

    Gui, 1:Default
    Gui, Color, %bgColor%, %bgColor%      ; fondo de ventana y de controles
    GuiControl, +c%fgColor%, Text         ; color de letra del texto
    GuiControl, +c%fgColor%, PctText      ; color de letra del porcentaje
    WinSet, Redraw,, ahk_id %mainHwnd%
}

SaveColors() {
    global bgColor, fgColor, _settingsini

    IniWrite, %bgColor%, %_settingsini%, Colors, Background
    IniWrite, %fgColor%, %_settingsini%, Colors, Foreground
}

; Dialogo de seleccion de color de Windows. Recibe y devuelve RGB (hex "RRGGBB").
PickColor(initialRGB := 0xFFFFFF) {
    static custom, init := false
    if (!init) {
        VarSetCapacity(custom, 64, 0)     ; 16 colores personalizados
        init := true
    }

    ; RGB -> BGR (formato COLORREF)
    bgr := ((initialRGB & 0xFF) << 16) | (initialRGB & 0xFF00) | ((initialRGB >> 16) & 0xFF)

    cbSize := (A_PtrSize = 8) ? 72 : 36
    VarSetCapacity(CC, cbSize, 0)
    NumPut(cbSize, CC, 0, "UInt")                 ; lStructSize
    NumPut(bgr, CC, 3 * A_PtrSize, "UInt")        ; rgbResult
    NumPut(&custom, CC, 4 * A_PtrSize, "Ptr")     ; lpCustColors
    NumPut(0x103, CC, 5 * A_PtrSize, "UInt")      ; CC_ANYCOLOR | CC_FULLOPEN | CC_RGBINIT

    if (!DllCall("comdlg32\ChooseColor" (A_IsUnicode ? "W" : "A"), "Ptr", &CC, "UInt"))
        return ""                                 ; cancelado

    bgr := NumGet(CC, 3 * A_PtrSize, "UInt")
    rgb := ((bgr & 0xFF) << 16) | (bgr & 0xFF00) | ((bgr >> 16) & 0xFF)
    return Format("{:06X}", rgb)
}

Up::
    if (currentLine > 1) {
        currentLine--
        ShowLine()
    }
return

Down::
    if (currentLine < formattedLines.Length()) {
        currentLine++
        ShowLine()
    }
return

^+F12::
    SaveSession()
    ExitApp
return

Esc::
    SaveSession()
    ExitApp
return

ExitScript:
    SaveSession()
    ExitApp
return

SaveSession() {
    global lastFile, currentLine, _settingsini

    if (lastFile != "") {
        IniWrite, %currentLine%, %_settingsini%, %lastFile%, LastLine
    }
}

CheckGuiHover:
    if (mainHwnd = 0)
        return

    MouseGetPos, mouseX, mouseY
    WinGetPos, guiX, guiY, guiW, guiH, ahk_id %mainHwnd%

    mouseInside := (mouseX >= guiX && mouseX <= guiX + guiW && mouseY >= guiY && mouseY <= guiY + guiH)

    if (mouseInside && !guiHover) {
        guiHover := true
        WinSet, Transparent, 120, ahk_id %mainHwnd%
        WinSet, ExStyle, +0x20, ahk_id %mainHwnd%
    } else if (!mouseInside && guiHover) {
        guiHover := false
        WinSet, ExStyle, -0x20, ahk_id %mainHwnd%
        WinSet, Transparent, OFF, ahk_id %mainHwnd%
    }
return
