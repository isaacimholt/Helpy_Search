; requires AutoHotkey_L

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
;#Warn  ; Recommended for catching common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#Include Array.ahk

; ==== GLOBALS ==== 

CONFIG_FILE := "Helpy Config.txt"


; ==== INIT ==== 

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

DATA := ParseConfig(CONFIG_FILE)
For HOTKEY_STR, _ in DATA
  hotkey, %HOTKEY_STR%, execute, On
msgbox % DumpData(DATA)

; ==== INTERFACE ==== 

Menu, tray, add, Open Config, open_config
Menu, tray, add, Open Readme online, open_readme
; add separator line
Menu, tray, add
; place standard tray items under mine
Menu, tray, NoStandard
Menu, tray, Standard

return

open_config:
  run %CONFIG_FILE%
return

open_readme:
  run http://github.com/miloir/Helpy_Search/#helpy-search
return


; ==== MAIN ==== 

execute:
  ; todo: parse config again if recently modified
  
  HOTKEY_USED := A_ThisHotKey
  
  ; Save the entire clipboard
  ClipSaved := ClipboardAll
  ; ... here make temporary use of the clipboard
  clipboard = ; Start off empty to allow ClipWait to detect when the text has arrived.
  Send ^c
  ClipWait  ; Wait for the clipboard to contain text.
  
  selected_text := trim(clipboard)
  
  Clipboard := ClipSaved  ; Restore the original clipboard. Note the use of Clipboard (not ClipboardAll).
  ClipSaved = ; Free the memory in case the clipboard was very large.
  
  For REGEX_STR, URLS in DATA[HOTKEY_USED] 
  {
    if ( RegExMatch(selected_text, REGEX_STR) ){
      For _, URL in URLS
      {
        Run % ParseFlags(URL, selected_text)
        sleep, 750  ; need to make sure tabs have time to load
      }
      break ; want to exit after finding a match
    }
  }
  
return


; ==== PARSERS ==== 

ParseConfig(config_filename, default_hotkey="^space")
{
  
  ; init with some defaults, will be stripped later if unused
  temp_data := Object(default_hotkey, Object("", Object()) )
  
  IN_SKIP_SECTION := 0
  CURRENT_HOTKEY := default_hotkey
  CURRENT_REGEX := ""
  
  Loop, read, %config_filename%
  {
    
    tokens := ConfigTokenizer(A_LoopReadLine)
    
    if ( tokens[1] = "blank" or tokens[1] = "comment" ) {
      continue
    } else if ( tokens[1] = "off" ) {
      IN_SKIP_SECTION := 1
    } else if ( tokens[1] = "on" ) {
      IN_SKIP_SECTION := 0
    } else if ( IN_SKIP_SECTION ) {
      continue
    } else if ( tokens[1] = "hotkey" ) {
      CURRENT_HOTKEY := tokens[2]
      if not temp_data.HasKey( CURRENT_HOTKEY )
        temp_data.Insert( CURRENT_HOTKEY, Object("", Object()) )
    } else if ( tokens[1] = "regex" ) {
      CURRENT_REGEX := tokens[2]
      if not temp_data[CURRENT_HOTKEY].HasKey( CURRENT_REGEX )
        temp_data[CURRENT_HOTKEY].Insert( CURRENT_REGEX, Object() )
    } else if ( tokens[1] = "url" ) {
      temp_data[CURRENT_HOTKEY][CURRENT_REGEX].Insert(tokens[2])
    }
    
  }
  
  ; todo: clean out temp_data of hotkeys and regexes with no urls
  ; also empty ("") hotkeys
  
  return temp_data
}

ConfigTokenizer(line)
{
  line := trim(line)
  if ( not line ) {
    return ["blank", ""]
  } else if ( RegExMatch(line, "^;") ) {
    return ["comment", ""]
  } else if ( RegExMatch(line, "^!OFF") ) {
    return ["off", ""]
  } else if ( RegExMatch(line, "^!ON") ) {
    return ["on", ""]
  } else if ( RegExMatch(line, "^!HOTKEY") ) {
    hotkey_str := trim( SubStr(line, 8) )
    return ["hotkey", hotkey_str]
  } else if ( RegExMatch(line, "^!REGEX") ) {
    regex_str := trim( SubStr(line, 7) )
    return ["regex", regex_str]
  } else {
    return ["url", line]
  }
}

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


; ==== FXNS ==== 

DumpData(data)
{
  data_str := ""
  for hk, regex_data in data
  {
    data_str := data_str . "!HOTKEY " . hk . "`n"
    for regex_str, urls in regex_data
    {
      data_str := data_str . "!REGEX " . regex_str . "`n"
      for _, url in urls
      {
        data_str := data_str . url . "`n"
      }
    }
  }
  
  return data_str
}

trim(item)
{
  return RegExReplace(item,"^\s*|\s*$","")
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