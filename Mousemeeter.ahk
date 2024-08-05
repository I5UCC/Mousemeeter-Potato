;@Ahk2Exe-Let Version = 2.0
;@Ahk2Exe-IgnoreBegin
;@Ahk2Exe-IgnoreEnd
;@Ahk2Exe-SetMainIcon icon.ico
;@Ahk2Exe-SetVersion %U_Version%
;@Ahk2Exe-SetName Mousemeeter
;@Ahk2Exe-SetDescription Mousemeeter
;@Ahk2Exe-Bin Unicode 64*
;@Ahk2Exe-Obey U_au, = "%A_IsUnicode%" ? 2 : 1 ; .Bin file ANSI or Unicode?

#SingleInstance Force
Persistent
SetWorkingDir(A_ScriptDir)
SendMode("Input")
#Include "VMR.ahk"

global RunAsAdmin := True
global TitleMatchMode := 3
global ResetOnStartup := True
global SetAffinity := True
global SetCracklingFix := True
global OUTPUT_1 := 6
global OUTPUT_2 := 7
global OUTPUT_3 := 8
global VOLUME_CHANGE_AMOUNT := 0.5

global vm := Voicemeeter()
global isActivated := True
global HotkeyState := False
global DeactivateOnWindow := False

global default_file := "default.xml"
global profile1_file := "profile1.xml"
global profile2_file := "profile2.xml"
global current_file := default_file

Class Voicemeeter {
    vm := ""

    __New() {
        this.vm := VMR()
        this.vm.login()
    }

    volumeUp(strip) {
        this.vm.strip[strip].gain += VOLUME_CHANGE_AMOUNT
    }

    volumeDown(strip) {
        this.vm.strip[strip].gain -= VOLUME_CHANGE_AMOUNT
    }

    volumeMute(strip, v := -1) {
        if (v != -1)
            this.vm.strip[strip].mute := v
        Else
            this.vm.strip[strip].mute--
    }

    restart() {
        this.vm.command.restart()
    }

    load(file) {
        this.vm.command.load(A_ScriptDir . "\" . file)
    }
}

ProcessExists(name) {
    ErrorLevel := ProcessExist(name)
    return ErrorLevel
}

While (!ProcessExists("voicemeeter8.exe") && !ProcessExists("voicemeeter8x64.exe"))
    Sleep(1000)
Sleep(5000)

Tray := A_TrayMenu
Tray.Delete() 
Tray.Add("Reload", ReloadHandler)
Tray.Add("Refresh Config", RefreshHandler)
Tray.Add("")
Tray.Add("Open Config", OpenConfigHandler)
Tray.Add("")
Tray.Add("Exit", ExitHandler)

Start()

ReloadHandler(A_ThisMenuItem, A_ThisMenuItemPos, MyMenu)
{ 
    global 
    Reload()
    return
} 

RefreshHandler(A_ThisMenuItem, A_ThisMenuItemPos, MyMenu)
{ 
    global 
    If (FileExist("config.ini"))
        ReadConfigIni()
    return
} 

OpenConfigHandler(A_ThisMenuItem, A_ThisMenuItemPos, MyMenu)
{ 
    global 
    If (FileExist("config.ini")) {
        RunWait("config.ini")
        ReadConfigIni()
    }
    return
} 

ExitHandler(A_ThisMenuItem, A_ThisMenuItemPos, MyMenu)
{ 
    global 
    ExitApp()
    return
} 

Start() {
    If (FileExist("config.ini"))
        ReadConfigIni()

    if (!A_IsAdmin && RunAsAdmin) {
        Try {
            Run("*RunAs `"" A_ScriptFullPath "`"")
        } catch {
            MsgBox("Declined Elevation, if you want to start this up without Admin Rights, change 'RunAsAdmin' to 0 in config.json")
            ExitApp()
        }
    }

    SetTitleMatchMode(TitleMatchMode)

    If (SetAffinity)
        ProcessSetPriority("High")

    If (SetCracklingFix)
        Run("powershell `"$Process = Get-Process audiodg; $Process.ProcessorAffinity=1; $Process.PriorityClass=`"`"High`"`"`"", , "Hide")

    If (ResetOnStartup)
        vm.load(default_file)

    MainLoop()
}

MainLoop() {
    If (DeactivateOnWindow) {
        Loop
        {
            Loop Parse, DeactivateOnWindow, "`n", "`r"
            {
                if WinActive(A_LoopField) {
                    isActivated := False
                    WinWaitNotActive(A_LoopField)
                    isActivated := True
                }
                Sleep(300)
            }
            Sleep(500)
        }
    }
}

ReadConfigIni() {
    SettingSectionExist := IniRead("config.ini", "Settings")
    If (SettingSectionExist) {
        RunAsAdmin := IniRead("config.ini", "Settings", "RunAsAdmin")
        TitleMatchMode := IniRead("config.ini", "Settings", "TitleMatchMode")
        ResetOnStartup := IniRead("config.ini", "Settings", "ResetOnStartup")
        SetAffinity := IniRead("config.ini", "Settings", "SetAffinity")
        SetCracklingFix := IniRead("config.ini", "Settings", "SetCracklingFix")
    }

    VoicemeeterSectionExist := IniRead("config.ini", "VoicemeeterSettings")
    If (VoicemeeterSectionExist) {
        OUTPUT_1 := IniRead("config.ini", "VoicemeeterSettings", "OUTPUT_1")
        OUTPUT_2 := IniRead("config.ini", "VoicemeeterSettings", "OUTPUT_2")
        OUTPUT_3 := IniRead("config.ini", "VoicemeeterSettings", "OUTPUT_3")
        VOLUME_CHANGE_AMOUNT := IniRead("config.ini", "VoicemeeterSettings", "VOLUME_CHANGE_AMOUNT")
        default_file := IniRead("config.ini", "VoicemeeterSettings", "default_file")
        profile1_file := IniRead("config.ini", "VoicemeeterSettings", "profile1_file")
        profile2_file := IniRead("config.ini", "VoicemeeterSettings", "profile2_file")
    }

    DeactivateOnWindow := IniRead("config.ini", "DeactivateOnWindow")
}

;KB-HOTKEYS
^!F4::
{ 
    global 
    active_id := WinGetPID("A")
    Run("taskkill /PID " active_id " /F", , "Hide")
    return
} 

^+R::
{ 
    global 
    ErrorLevel := !KeyWait("R")
    ErrorLevel := !KeyWait("R", "d t0.250")
    If (Errorlevel) {
        vm.restart()
    }
    Else {
        vm.load(default_file)
        current_file := default_file
    }
    Return

    ;Mouse-HOTKEYS
} 
#HotIf isActivated
XButton1::
{ 
    global 
    While GetKeyState("XButton1", "P") {
        HotkeyState := True
        Sleep(200)
    }
    HotkeyState := False
    Return
} 

XButton2::
{ 
    global 
    While GetKeyState("XButton2", "P") {
        HotkeyState := True
        Sleep(200)
    }
    HotkeyState := False
    Return
} 

XButton1 Up::
{ 
    global 
    HotkeyState := False
    If (A_PriorHotkey == "XButton1")
        Send("{XButton1}")
    Return
} 

XButton2 Up::
{ 
    global 
    HotkeyState := False
    If (A_PriorHotkey == "XButton2")
        Send("{XButton2}")
    Return
} 

#HotIf isActivated && HotkeyState
LButton::
{ 
    global 
    If (GetKeyState("XButton1", "P") && GetKeyState("XButton2", "P"))
        Send("{LButton}")
    Else If (GetKeyState("XButton1", "P"))
        Send("{LButton}")
    Else If (GetKeyState("XButton2", "P"))
        Send("{Media_Prev}")
    Return
} 

RButton::
{ 
    global 
    If (GetKeyState("XButton1", "P") && GetKeyState("XButton2", "P"))
        Send("{RButton}")
    Else If (GetKeyState("XButton1", "P"))
        Send("{RButton}")
    Else If (GetKeyState("XButton2", "P"))
        Send("{Media_Next}")
    Return
} 

MButton::
{ 
    global 
    If (GetKeyState("XButton1", "P") && GetKeyState("XButton2", "P"))
        Send("{MButton}")
    Else If (GetKeyState("XButton1", "P"))
        Send("{MButton}")
    Else If (GetKeyState("XButton2", "P"))
        Send("{Media_Play_Pause}")
    Return
} 

WheelUp::
{ 
    global 
    If (GetKeyState("XButton1", "P") && GetKeyState("XButton2", "P")) ;VAIO3
        vm.volumeUp(OUTPUT_3)
    Else If (GetKeyState("XButton1", "P")) ;VAIO
        vm.volumeUp(OUTPUT_1)
    Else If (GetKeyState("XButton2", "P")) ;AUX
        vm.volumeUp(OUTPUT_2)
    Return
} 

WheelDown::
{ 
    global 
    If (GetKeyState("XButton1", "P") && GetKeyState("XButton2", "P")) ;VAIO3
        vm.volumeDown(OUTPUT_3)
    Else If (GetKeyState("XButton1", "P")) ;VAIO
        vm.volumeDown(OUTPUT_1)
    Else If (GetKeyState("XButton2", "P")) ;AUX
        vm.volumeDown(OUTPUT_2)
    Return
} 

#HotIf
F24::
{ 
    global 
    If (GetKeyState("XButton1", "P") && GetKeyState("XButton2", "P")) ;VAIO3
        vm.volumeMute(OUTPUT_3)
    Else If (GetKeyState("XButton1", "P")) ;VAIO
        vm.volumeMute(OUTPUT_1)
    Else If (GetKeyState("XButton2", "P")) ;AUX
        vm.volumeMute(OUTPUT_2)
    Else {
        ErrorLevel := !KeyWait(A_ThisHotkey)
        ErrorLevel := !KeyWait(A_ThisHotkey, "d t0.250")
        If (Errorlevel) {
            if (current_file == profile1_file) {
                vm.load(default_file)
                current_file := default_file
            }
            Else {
                vm.load(profile1_file)
                current_file := profile1_file
            }
        }
        Else {
            if (current_file == profile2_file) {
                vm.load(default_file)
                current_file := default_file
            }
            Else {
                vm.load(profile2_file)
                current_file := profile2_file
            }
        }
    }
    Return
}
