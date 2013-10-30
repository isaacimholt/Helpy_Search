#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
;#Warn  ; Recommended for catching common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

;#Include Array.ahk

; todo: handle lists of keys with various separators & more specific mid regex for this as well. also, a gui.

; remember to install AutoHotkey_L, not the regular ahk

CONFIG_FILE := "config.hlpy"
DEFAULT_HOTKEY := "^space"
;HOTKEYS := Array()

Menu, tray, add, Open Config, open_config
; add separator line
Menu, tray, add
; place standard tray items under mine
Menu, tray, NoStandard
Menu, tray, Standard

hotkey, %DEFAULT_HOTKEY%, main

return

init_hotkeys:
    IfExist, %CONFIG_FILE%
    {
    }
return

open_config:
    run notepad %CONFIG_FILE%
return

main:
    ; register which hotkey was used so we know which lines to execute
    HOTKEY_USED := A_ThisHotKey
    ClipSaved := ClipboardAll   ; Save the entire clipboard
    ; ... here make temporary use of the clipboard
    clipboard =  ; Start off empty to allow ClipWait to detect when the text has arrived.
    Send ^c
    ClipWait  ; Wait for the clipboard to contain text.
    
    ; trim top & tail & rename for clarity
    selected_text := RegExReplace(clipboard,"^\s*|\s*$","")
    
    IfExist, %CONFIG_FILE%
    {
        
        IN_SKIP_SECTION = 0
        REGEX_STR := ""
        REGEX_MATCHES = 0
        
        Loop, read, %CONFIG_FILE%
        {
            ;url_string = %A_LoopReadLine%   ; rename for clarity and autotrim
            ; trim top & tail & rename for clarity
            url_string := RegExReplace(A_LoopReadLine,"^\s*|\s*$","")
            
            ; skip empty lines
            if not url_string
                continue
            
            ; skip comments
            if ( RegExMatch(url_string, "^;") )
                continue
            
            ; skip off sections
            if ( RegExMatch(url_string, "^!OFF") ) {
                IN_SKIP_SECTION := 1
                continue               
            } else if ( RegExMatch(url_string, "^!ON") ) {
                IN_SKIP_SECTION := 0
                continue
            } else if (IN_SKIP_SECTION) {
                continue
            }
            
            ; register regex section
            if ( RegExMatch(url_string, "^!REGEX") ) {
                
                ; want to exit after finding a matching REGEX block
                if REGEX_MATCHES
                    break
                
                ; get regex
                REGEX_STR := SubStr(url_string, 7)
                ; trim
                REGEX_STR := RegExReplace(REGEX_STR,"^\s*|\s*$","")
                
                if ( RegExMatch(selected_text, REGEX_STR) ) {
                    REGEX_MATCHES = 1
                } else {
                    REGEX_MATCHES = 0
                }
                continue
            }
            
            ; do werk
            if ( REGEX_MATCHES ) {
                url_string := ParseFlags(url_string, selected_text)
                Run % url_string
                sleep, 750 ; need to make sure tabs have time to load
            }
            
        }
    }
    
    Clipboard := ClipSaved   ; Restore the original clipboard. Note the use of Clipboard (not ClipboardAll).
    ClipSaved =   ; Free the memory in case the clipboard was very large.
return

ParseFlags(url_string, selected_text)
{
    flag_delimiter := "|"
    is_even := 0
    search_strings := Array()
    replace_strings := Array()

    Loop, parse, url_string, %flag_delimiter%
    {
        if is_even
        {
            flags := A_LoopField    ; rename for clarity
            search_var := flag_delimiter . flags . flag_delimiter
            search_strings.Insert(search_var)
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
            
            replace_strings.Insert(result_text)
            
            is_even := 0
        }
        else
        {
            is_even := 1
        }
    }
    
    Loop % search_strings.MaxIndex()
    {
        search_str := search_strings[A_Index]
        replace_str := replace_strings[A_Index]
        StringReplace, url_string, url_string, %search_str%, %replace_str%
    }
    
    Return, url_string
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