﻿#SingleInstance ignore
#Persistent
#NoTrayIcon
#NoEnv
SetWorkingDir %A_ScriptDir%
SendMode Input
#Include VMR.ahk/VMR.ahk

global voicemeeter
global state

setHotkeyState(False)
voicemeeter := new Voicemeeter()
voicemeeter.reset()

;Methods
notImplemented() {

}

setHotkeyState(switch) {
    If (switch) {
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

;KB-HOTKEYS
^!F4::
    WinGet, active_id, PID, A
    run, taskkill /PID %active_id% /F,,Hide
return

^+R:: 
    KeyWait, R
    KeyWait, R, d t0.250 ;Wait for double click
    If (Errorlevel)
        voicemeeter.restart()
    Else
        voicemeeter.reset()
Return

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

LButton::
    If (GetKeyState("XButton1","P") && GetKeyState("XButton2","P"))
        notImplemented()
    Else If (GetKeyState("XButton1","P"))
        notImplemented()
    Else If (GetKeyState("XButton2","P"))
        Send, {Media_Prev}
    state := True
Return

RButton::
    If (GetKeyState("XButton1","P") && GetKeyState("XButton2","P"))
        notImplemented()
    Else If (GetKeyState("XButton1","P"))
        notImplemented()
    Else If (GetKeyState("XButton2","P"))
        Send, {Media_Next}
    state := True
Return

MButton::
    If (GetKeyState("XButton1","P") && GetKeyState("XButton2","P"))
        notImplemented()
    Else If (GetKeyState("XButton1","P"))
        notImplemented()
    Else If (GetKeyState("XButton2","P"))
        Send, {Media_Play_Pause}
    state := True
Return

WheelUp::
    If (GetKeyState("XButton1","P") && GetKeyState("XButton2","P")) ;VAIO3
        voicemeeter.volumeUp(8, 0.5)
    Else If (GetKeyState("XButton1","P")) ;VAIO
        voicemeeter.volumeUp(6, 0.5)
    Else If (GetKeyState("XButton2","P")) ;AUX
        voicemeeter.volumeUp(7, 0.5)
    state := True
Return

WheelDown::
    If (GetKeyState("XButton1","P") && GetKeyState("XButton2","P")) ;VAIO3
        voicemeeter.volumeDown(8, 0.5)
    Else If (GetKeyState("XButton1","P")) ;VAIO
        voicemeeter.volumeDown(6, 0.5)
    Else If (GetKeyState("XButton2","P")) ;AUX
        voicemeeter.volumeDown(7, 0.5)
    state := True
Return

F24::
    If (GetKeyState("XButton1","P") && GetKeyState("XButton2","P")) ;VAIO3
        voicemeeter.volumeMute(8)
    Else If (GetKeyState("XButton1","P")) ;VAIO
        voicemeeter.volumeMute(6)
    Else If (GetKeyState("XButton2","P")) ;AUX
        voicemeeter.volumeMute(7)
    Else {
        KeyWait, %A_ThisHotkey%
        KeyWait, %A_ThisHotkey%, d t0.250
        If (Errorlevel)
            voicemeeter.setMainOutput("A2")
        Else
            voicemeeter.setMainOutput("A3")
    }
    state := True
Return

;Classes
Class Voicemeeter {
    vm := ""
    
    __New() {
        this.vm := new VMR()
        this.vm.login()
    }

    volumeUp(strip, amount) {
        this.vm.strip[strip].gain += amount
    }

    volumeDown(strip, amount) {
        this.vm.strip[strip].gain -= amount
    }

    volumeMute(strip) {
        this.vm.strip[strip].mute--
    }
    
    setMainOutput(output, unmute := True) {
        switch output {
            case "A2": 
                If (this.vm.strip[6].A2)
                    output := "A1"
            case "A3":
                If (this.vm.strip[6].A3)
                    output := "A1"
            case "A4":
                If (this.vm.strip[6].A4)
                    output := "A1"
            case "A5":
                If (this.vm.strip[6].A5)
                    output := "A1"
        }
        for i, strip in this.vm.strip {
            If (i > 5) {
                strip.A1 := 0
                strip.A2 := 0
                strip.A3 := 0
                strip.A4 := 0
                strip.A5 := 0
                switch output {
                    case "A1": strip.A1 := 1
                    case "A2": strip.A2 := 1
                    case "A3": strip.A3 := 1
                    case "A4": strip.A4 := 1
                    case "A5": strip.A5 := 1
                }
            }
            If (unmute)
                strip.mute := 0
        }
    }

    restart() {
        voicemeeter.vm.command.restart()
    }

    reset() {
        this.setMainOutput("A1")

        this.vm.strip[6].gain := -20
        this.vm.strip[7].gain := -20
        this.vm.strip[8].gain := -20

        for i, strip in this.vm.strip {
            strip.mute := 0
        }

        this.restart()
    }
}
