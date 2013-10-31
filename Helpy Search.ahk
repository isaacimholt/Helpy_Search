#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
;#Warn  ; Recommended for catching common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#Include Array.ahk

; requires AutoHotkey_L

CONFIG_FILE := "config.hlpy"
DEFAULT_HOTKEY := "^space"
HOTKEYS := Array()

Menu, tray, add, Open Config, open_config
Menu, tray, add, Show Active Hotkeys, show_active_hotkeys
Menu, tray, add, Reload Hotkeys from Config, update_hotkeys
Menu, tray, add, Open Readme online, open_readme
; add separator line
Menu, tray, add
; place standard tray items under mine
Menu, tray, NoStandard
Menu, tray, Standard

IfNotExist, %CONFIG_FILE%
{
  FileAppend,
  (
; This is the default config file.
; Customize it to your needs.
http://www.google.com/search?q=|e|
http://en.wikipedia.org/w/index.php?search=|e|
http://www.youtube.com/results?search_query=|e|
  ), %CONFIG_FILE%
}

scan_hotkeys(0)

return

update_hotkeys:
  scan_hotkeys()
return

show_active_hotkeys:
  msgbox % HOTKEYS.join("`n")
return

scan_hotkeys(tray_tip=1)
{
  global CONFIG_FILE
  global HOTKEYS
  global DEFAULT_HOTKEY
  
  TEMP_HOTKEYS := Array() ; init / reset
  
  Loop, read, %CONFIG_FILE%
  {
    config_line := RegExReplace(A_LoopReadLine,"^\s*|\s*$","") ; trim & rename
    ; register hotkey section
    if ( RegExMatch(config_line, "^!HOTKEY") ) {
      ; get hotkey
      HOTKEY_STR := SubStr(config_line, 8)
      ; trim
      HOTKEY_STR := RegExReplace(HOTKEY_STR,"^\s*|\s*$","")
      ; Check str is not empty and doesn't already exist in TEMP_HOTKEYS
      if ( HOTKEY_STR and not TEMP_HOTKEYS.indexOf(HOTKEY_STR) )
        TEMP_HOTKEYS.append(HOTKEY_STR)
    } else if ( not TEMP_HOTKEYS.len()
      and config_line
      and not RegExMatch(config_line, "^;")
      and not RegExMatch(config_line, "^!OFF")
      and not RegExMatch(config_line, "^!ON")
      and not RegExMatch(config_line, "^!REGEX")
      and not ) {
      
    }
  }
  
  ; add default hk if no others
  if not TEMP_HOTKEYS.len()
    TEMP_HOTKEYS.append(DEFAULT_HOTKEY)
  
  HK_REMOVED := 0
  HK_ADDED :=   0
  
  ; disable old hotkeys
  for index, hk in HOTKEYS
  {
    if not TEMP_HOTKEYS.indexOf(hk)
    {
      hotkey, %hk%, main, Off
      HK_REMOVED++
    }
  }
  
  ; enable new hotkeys
  for index, hk in TEMP_HOTKEYS
  {
    if not HOTKEYS.indexOf(hk)
    {
      hotkey, %hk%, main, On
      HK_ADDED++
    }
  }
  
  ; set HOTKEYS to new values
  HOTKEYS := TEMP_HOTKEYS
  
  if not tray_tip
    return
  
  ; notify user of changed hotkeys
  if ( HK_ADDED or HK_REMOVED )
  {
    bubble_text := ""
    if HK_ADDED
      bubble_text := bubble_text . HK_ADDED . " hotkey(s) added."
    if HK_ADDED and HK_REMOVED
      bubble_text := bubble_text . "`n"
    if HK_REMOVED
      bubble_text := bubble_text . HK_REMOVED . " hotkey(s) removed."
    TrayTip, Hotkeys Updated, %bubble_text%, , 1
  }
}

open_config:
  run notepad %CONFIG_FILE%
return

open_readme:
  run http://github.com/miloir/Helpy_Search/#helpy-search
return

main:
  
  scan_hotkeys()
  
  ; init  
  IN_SKIP_SECTION :=  0
  HOTKEY_USED :=      A_ThisHotKey
  HOTKEY_EXISTS :=    0 ; remains false if config doesn't have any !HOTKEY cmds
  HOTKEY_STR :=       ""
  HOTKEY_MATCHES :=   0
  REGEX_EXISTS :=     0 ; remains false if config doesn't have any !REGEX cmds
  REGEX_STR :=        ""
  REGEX_MATCHES :=    0
  
  ; Save the entire clipboard
  ClipSaved := ClipboardAll
  ; ... here make temporary use of the clipboard
  clipboard = ; Start off empty to allow ClipWait to detect when the text has arrived.
  Send ^c
  ClipWait  ; Wait for the clipboard to contain text.
  
  selected_text := RegExReplace(clipboard,"^\s*|\s*$","") ; trim & rename
  
  Loop, read, %CONFIG_FILE%
  {
    config_line := RegExReplace(A_LoopReadLine,"^\s*|\s*$","") ; trim & rename
    
    ; skip empty lines
    if not config_line
      continue
    
    ; skip comments
    if ( RegExMatch(config_line, "^;") )
      continue
    
    ; skip off sections
    if ( RegExMatch(config_line, "^!OFF") ) {
      IN_SKIP_SECTION := 1
      continue               
    } else if ( RegExMatch(config_line, "^!ON") ) {
      IN_SKIP_SECTION := 0
      continue
    } else if (IN_SKIP_SECTION) {
      continue
    }
    
    ; register hotkey section
    if ( RegExMatch(config_line, "^!HOTKEY") ) {
      
      HOTKEY_EXISTS = 1
      
      ; get hotkey
      HOTKEY_STR := SubStr(config_line, 8)
      ; trim
      HOTKEY_STR := RegExReplace(HOTKEY_STR,"^\s*|\s*$","")
      ;msgbox % HOTKEY_STR . " " . HOTKEY_USED
      if ( HOTKEY_STR = HOTKEY_USED ) {
        HOTKEY_MATCHES = 1
      } else {
        HOTKEY_MATCHES = 0
      }
      continue
    }
    
    ; register regex section
    if ( HOTKEY_MATCHES or not HOTKEY_EXISTS and RegExMatch(config_line, "^!REGEX") ) {
      
      REGEX_EXISTS = 1
      
      ; want to exit after finding a matching REGEX block
      if REGEX_MATCHES
        break
      
      ; get regex
      REGEX_STR := SubStr(config_line, 7)
      ; trim
      REGEX_STR := RegExReplace(REGEX_STR,"^\s*|\s*$","")
      
      if ( RegExMatch(selected_text, REGEX_STR) ) {
        REGEX_MATCHES = 1
      } else {
        REGEX_MATCHES = 0
      }
      continue
    }
    ; msgbox % HOTKEY_MATCHES . " " . HOTKEY_EXISTS
    ; msgbox % REGEX_MATCHES . " " . REGEX_EXISTS
    ; do werk
    if ( (HOTKEY_MATCHES or not HOTKEY_EXISTS) 
      and (REGEX_MATCHES or not REGEX_EXISTS) ) {
      
      config_line := ParseFlags(config_line, selected_text)
      Run % config_line
      sleep, 750  ; need to make sure tabs have time to load
    }
    
  }
  
  Clipboard := ClipSaved  ; Restore the original clipboard. Note the use of Clipboard (not ClipboardAll).
  ClipSaved = ; Free the memory in case the clipboard was very large.
return

ParseFlags(config_line, selected_text)
{
  flag_delimiter := "|"
  is_even := 0
  search_strings := Array()
  replace_strings := Array()

  Loop, parse, config_line, %flag_delimiter%
  {
    if is_even
    {
      flags := A_LoopField    ; rename for clarity
      search_var := flag_delimiter . flags . flag_delimiter
      search_strings.append(search_var)
      result_text := selected_text ; make copy
      IfInString, flags, e
      {
        result_text := UriEncode(result_text)
      }
      IfInString, flags, e-p
      {
        ; e-p flag is "encode with pluses"
        ; text will have already been encoded so just do replacement
        StringReplace, result_text, result_text, `%20, +, All
      }
      IfInString, flags, q
      {
        result_text := "%22" . result_text . "%22"
      }
      
      replace_strings.append(result_text)
      
      is_even := 0
    }
    else
    {
      is_even := 1
    }
  }
  
  Loop % search_strings.len()
  {
    search_str := search_strings[A_Index]
    replace_str := replace_strings[A_Index]
    StringReplace, config_line, config_line, %search_str%, %replace_str%
  }
  
  Return, config_line
}

; enc fxns
; http://www.autohotkey.com/board/topic/75390-ahk-l-unicode-uri-encode-url-encode-function/

; modified from jackieku's code (http://www.autohotkey.com/forum/post-310959.html#310959)
UriEncode(Uri, Enc = "UTF-8")
{
	StrPutVar(Uri, Var, Enc)
	f := A_FormatInteger
	SetFormat, IntegerFast, H
	Loop
	{
		Code := NumGet(Var, A_Index - 1, "UChar")
		If (!Code)
			Break
		If (Code >= 0x30 && Code <= 0x39 ; 0-9
			|| Code >= 0x41 && Code <= 0x5A ; A-Z
			|| Code >= 0x61 && Code <= 0x7A) ; a-z
			Res .= Chr(Code)
		Else
			Res .= "%" . SubStr(Code + 0x100, -1)
	}
	SetFormat, IntegerFast, %f%
	Return, Res
}

UriDecode(Uri, Enc = "UTF-8")
{
	Pos := 1
	Loop
	{
		Pos := RegExMatch(Uri, "i)(?:%[\da-f]{2})+", Code, Pos++)
		If (Pos = 0)
			Break
		VarSetCapacity(Var, StrLen(Code) // 3, 0)
		StringTrimLeft, Code, Code, 1
		Loop, Parse, Code, `%
			NumPut("0x" . A_LoopField, Var, A_Index - 1, "UChar")
		StringReplace, Uri, Uri, `%%Code%, % StrGet(&Var, Enc), All
	}
	Return, Uri
}

StrPutVar(Str, ByRef Var, Enc = "")
{
	Len := StrPut(Str, Enc) * (Enc = "UTF-16" || Enc = "CP1200" ? 2 : 1)
	VarSetCapacity(Var, Len, 0)
	Return, StrPut(Str, &Var, Enc)
}