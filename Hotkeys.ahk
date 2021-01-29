﻿#SingleInstance ignore
#Persistent
#NoTrayIcon
#NoEnv
SetWorkingDir %A_ScriptDir%
SendMode Input
#Include VMR/VMR.ahk
#include auto_oculus_touch/bin/auto_oculus_touch.ahk

setHotkeyState(False)
setProcessPriorities()
CMD("w32tm.exe /resync", "C:\Windows\System32", True)
SysGet, mc, MonitorCount
If (GetKeyState("JoyInfo"))
    setMode("TV")
Else If (mc != 3)
    setMode("PC")

global voicemeeter
voicemeeter := new VMR()
voicemeeter.login()
Voicemeeter("RESET")

Loop {
    Process, Wait, OculusClient.exe
    Voicemeeter("VR")
    
    InitOculus()
    Loop {
        Sleep 55
        Poll()
        down     := GetButtonsDown()
        pressed  := GetButtonsPressed()
        released := GetButtonsReleased()
        rightY        := GetThumbStick(RightHand, YAxis)

        if (rightY >= 0.7) && ovrRThumb & down
            SendInput {Volume_Up}
        else if (rightY <= -0.7) && ovrRThumb & down
            SendInput {Volume_Down}

        Process, Exist, OculusClient.exe
    } Until !ErrorLevel

    Process, WaitClose, OculusClient.exe
    Process, Close, Steam.exe
    Voicemeeter("RESET")
}

;Methods
notImpl() {
    ;MsgBox, 64, NOT IMPLEMENTED, NOT IMPLEMENTED, 5
}

CMD(cmd, Directory, bhide:=False) {
    If Directory not contains :
        Directory = %A_ScriptDir%%Directory%
    Run, %ComSpec% /c %cmd%, %Directory%, (bhide ? Hide : Show)
}

Voicemeeter_setMainOutput(output, unmute := False) {
    for i, strip in voicemeeter.strip {
        If (i > 5) {
            strip.A1 := 0
            strip.A2 := 0
            strip.A3 := 0
            strip.A4 := 0
            strip.A5 := 0
            switch output {
                case "A1": strip.A1 := -1
                case "A2": strip.A2 := -1
                case "A3": strip.A3 := -1
                case "A4": strip.A4 := -1
                case "A5": strip.A5 := -1
            }
            If (unmute)
                strip.mute := 0
        }
    }
}

Voicemeeter(macrolabel) {
    switch macrolabel {
        case "RESET":
            Voicemeeter_setMainOutput("A1",True)
            voicemeeter.strip[1].device["wdm"]:= "Microphone (HyperX Quadcast)"
            voicemeeter.strip[1].Color_x := -0.23
            voicemeeter.strip[1].Color_y = +0.37

            voicemeeter.strip[6].gain := -20
            voicemeeter.strip[7].gain := -20
            voicemeeter.strip[8].gain := -10
            voicemeeter.command.restart()
        Return

        ;Modes
        case "TV":
            Voicemeeter_setMainOutput("A4")
            voicemeeter.strip[6].gain := 0
            voicemeeter.strip[7].gain := 0
            voicemeeter.strip[8].mute := -1
        Return
        case "VR":
            Voicemeeter_setMainOutput("A3")
            voicemeeter.strip[1].device["mme"]:= "VR (2- Rift S)"
            voicemeeter.strip[6].gain := -20
            voicemeeter.strip[7].gain := -20
            voicemeeter.strip[8].gain := -10
        Return
        case "Speakers":
            If (voicemeeter.strip[6].A2) {
                Voicemeeter_setMainOutput("A1")
            }
            Else {
                Voicemeeter_setMainOutput("A2")
            }
        Return
        case "Bluetooth":
            If (voicemeeter.strip[6].A5) {
                Voicemeeter_setMainOutput("A1")
            }
            Else {
                Voicemeeter_setMainOutput("A5")
                voicemeeter.command.restart()
            }
        Return

        ;Main
        case "MainVolUp": voicemeeter.strip[6].gain += 0.5
        case "MainVolDown": voicemeeter.strip[6].gain -= 0.5
        case "MainMute": voicemeeter.strip[6].mute--

        ;Media
        case "MediaVolUp": voicemeeter.strip[7].gain += 0.5
        case "MediaVolDown": voicemeeter.strip[7].gain -= 0.5
        case "MediaMute": voicemeeter.strip[7].mute--

        ;VOIP
        case "VOIPVolUp": voicemeeter.strip[8].gain += 0.5
        case "VOIPVolDown": voicemeeter.strip[8].gain -= 0.5
        case "VOIPMute": voicemeeter.strip[8].mute--
    }
}

MonitorSwitcher(mode:="PC") {
    cmd = "MonitorSwitcher.exe -load:%mode%.xml"
    CMD(cmd, "\MonitorProfileSwitcher", True)
    Sleep 3000
}

setHotkeyState(sw) {
    If (sw) {
        Hotkey, WheelUp, On
        Hotkey, WheelDown, On
        Hotkey, LButton, On
        Hotkey, RButton, On
        Hotkey, MButton, On
    }
    Else {
        Hotkey, WheelUp, Off
        Hotkey, WheelDown, Off
        Hotkey, LButton, Off
        Hotkey, RButton, Off
        Hotkey, MButton, Off
    }
}

setProcessPriorities() {
    Process, Wait, voicemeeter8.exe
    Process, Wait, Light Host.exe
    
    Process, Priority, Hotkeys.exe, H
    Process, Priority, Light Host.exe, H
    Process, Priority, voicemeeter8.exe, H
}

setMode(mode) {
    If (mode == "PC") {
        MonitorSwitcher()
        Voicemeeter("RESET")
    }
    Else If (mode == "TV") {
        MsgBox, 64, Switching Monitor Mode, Switching to TV-Mode, 2
        MonitorSwitcher("TV")
        Run, "steam://open/bigpicture"
        CMD("easyrp.exe", "\EasyRP", True)
        Sleep, 5000
        Voicemeeter("TV")
        MouseMove, 0, 2160
        WinWaitClose, Steam
        Process, Close, easyrp.exe
        setMode("PC")
    }
}

;KB-HOTKEYS
^!F4::
    WinGet, active_id, PID, A
    run, taskkill /PID %active_id% /F,,Hide
return

^+R:: voicemeeter.command.restart()

;Mouse-HOTKEYS
XButton1::
    state := False
    While GetKeyState("XButton1", "P")
        setHotkeyState(True)
    setHotkeyState(False)
Return

XButton2::
    state := False
    While GetKeyState("XButton2", "P")
        setHotkeyState(True)
    setHotkeyState(False)
Return

XButton1 Up::
    If (!state)
        Send, {XButton1}
Return

XButton2 Up::
    If (!state)
        Send, {XButton2}
Return

WheelUp::
    If (GetKeyState("XButton1","P") && GetKeyState("XButton2","P")) ;VOIP
        Voicemeeter("VOIPVolUp")
    Else If (GetKeyState("XButton1","P")) ;Main
        Voicemeeter("MainVolUp")
    Else If (GetKeyState("XButton2","P")) ;Media
        Voicemeeter("MediaVolUp")
    state := True
Return

WheelDown::
    If (GetKeyState("XButton1","P") && GetKeyState("XButton2","P")) ;VOIP
        Voicemeeter("VOIPVolDown")
    Else If (GetKeyState("XButton1","P")) ;Main
        Voicemeeter("MainVolDown")
    Else If (GetKeyState("XButton2","P")) ;Media
        Voicemeeter("MediaVolDown")
    state := True
Return

LButton::
    If (GetKeyState("XButton1","P") && GetKeyState("XButton2","P")) ;VOIP
        notImpl() ;#TODO: Implement an action
    Else If (GetKeyState("XButton1","P")) ;Main
        notImpl() ;#TODO: Implement an action
    Else If (GetKeyState("XButton2","P")) ;Media
        Send, {Media_Prev}
    state := True
Return

RButton::
    If (GetKeyState("XButton1","P") && GetKeyState("XButton2","P")) ;VOIP
        notImpl() ;#TODO: Implement an action
    Else If (GetKeyState("XButton1","P")) ;Main
        notImpl() ;#TODO: Implement an action
    Else If (GetKeyState("XButton2","P")) ;Media
        Send, {Media_Next}
    state := True
Return

MButton::
    If (GetKeyState("XButton1","P") && GetKeyState("XButton2","P")) ;VOIP
        notImpl() ;#TODO: Implement an action
    Else If (GetKeyState("XButton1","P")) ;Main
        notImpl() ;#TODO: Implement an action
    Else If (GetKeyState("XButton2","P")) ;Media
        Send, {Media_Play_Pause}
    state := True
Return

F24::
    If (GetKeyState("XButton1","P") && GetKeyState("XButton2","P")) ;VOIP
        Voicemeeter("VOIPMute")
    Else If (GetKeyState("XButton1","P")) ;Main
        Voicemeeter("MainMute")
    Else If (GetKeyState("XButton2","P")) ;Media
        Voicemeeter("MediaMute")
    Else {
        KeyWait, %A_ThisHotkey%
        KeyWait, %A_ThisHotkey%, d t0.250 ;Wait for double click
        If (Errorlevel)
            Voicemeeter("Speakers")
        Else
            Voicemeeter("Bluetooth")
    }
    state := True
Return

;Controller-HOTKEYS
~$vk07::
    SysGet, mc, MonitorCount
    If (mc > 1) {
        Loop {
            Sleep, 300
        } Until (GetKeyState("vk07") == "0")
        Sleep, 1000
        If (GetKeyState("JoyInfo"))
            setMode("TV")
    }
Return