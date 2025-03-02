#Requires AutoHotkey v2.0
#SingleInstance Force
#include <JXON>

global IsCalling := false

class Strategem extends Object {
	Name := "Unused"
	id := "blank"
	CalldownCode := ""
	Category := ""
	Type := "misc"
	__New(ClassID, Name, CalldownCode, Category, type, calldownDelay?, *) {
		this.Name := Name
		this.id := ClassID
		this.CalldownCode := CalldownCode
		this.Category := Category
		this.Type := type
		if IsSet(calldownDelay) {
			this.calldownDelay := calldownDelay
		} else {
			this.calldownDelay := ""
		}
	}
	CallDown() {
		global IsCalling
		if(this.CalldownCode == "")
			Return
		
		IsCalling := true
		SetKeyDelay(6,0)
		SendEvent(
			"{" Config.Get("output").Get("up") " Up}"
			"{" Config.Get("output").Get("down") " Up}"
			"{" Config.Get("output").Get("left") " Up}"
			"{" Config.Get("output").Get("right") " Up}"
		)
		SetKeyDelay(Config.Get("keyDownTime"),Config.Get("keyUpTime"))
		local CallDownInputs := ":"
		Loop Parse this.CallDownCode {
			if(A_LoopField == "w")
				CallDownInputs := CallDownInputs . "{" Config.Get("output").Get("up") "}"
			if(A_LoopField == "a")
				CallDownInputs := CallDownInputs . "{" Config.Get("output").Get("left") "}"
			if(A_LoopField == "s")
				CallDownInputs := CallDownInputs . "{" Config.Get("output").Get("down") "}"
			if(A_LoopField == "d")
				CallDownInputs := CallDownInputs . "{" Config.Get("output").Get("right") "}"
		}
		SendEvent(CallDownInputs "{Ctrl Up}")
		IsCalling := false
	}
}

global Strategems := Map()
Strategems.Set("empty", Strategem("empty", "[Unbound]", "", "", "misc"))
Strategems.Set("default", Strategem("default", "[Default]", "", "", "misc"))
Strategems.Set("all", Strategem("all", "[All]", "", "", "misc"))

LoadStrategems() {
	local text := FileRead("strategems.json")
	local json := Jxon_Load(&text)
	for key, value in json.Get("departments") {
		for strat in value {
			Strategems.Set(strat.Get("id"), Strategem(strat.Get("id"), strat.Get("name"), strat.Get("combo"), key, strat.Get("type", "misc"), strat.Get("calldownTime", "")))
		}
	}
}
LoadStrategems()
ConfigText := FileRead("config.json")
Config := Jxon_Load(&ConfigText)
ConfigText := ""

class LoadoutController {
	Reload() {
		LoadoutText := FileRead("loadouts.json")
		This.JSON := Jxon_Load(&LoadoutText)
		This.currentBinding := This.JSON.Get("latest").Get("bindings")
		This.currentLoadout := This.JSON.Get("latest").Get("loadout")
	}
	__New() {
		if FileExist("loadouts.json") {
			This.Reload()
		} else {
			This.JSON := Map()
			This.JSON.Set("favorites", [])
			loadouts := Map()
			startLoadout := Map()
			startLoadout.Set("bindings", [
				"reinforce",
				"resupply",
				"default",
				"default",
				"default",
				"default",
				"default",
				"default",
			])
			startLoadout.Set("loadout", ["empty", "empty", "empty", "empty"])

			loadouts.Set("Default", startLoadout)
			This.JSON.Set("loadouts", loadouts)
			This.JSON.Set("selected", "Default")
			This.currentBinding := loadouts.Get("Default").Get("bindings").Clone()
			This.currentLoadout := loadouts.Get("Default").Get("loadout").Clone()

			This.Save()
		}
	}
	Save(*) { ; Variadic so it makes a convenient callback
		l := Map()
		l.Set("bindings", This.currentBinding.Clone())
		l.Set("loadout", This.currentLoadout.Clone())
		This.JSON.Set("latest", l)
		LoadoutText := Jxon_Dump(This.JSON, "`t")
		if FileExist("loadouts.json") {
			FileDelete("loadouts.json")
		}
		FileAppend(LoadoutText, "loadouts.json")
	}
	IsFavorite(name) {
		return This.JSON.Get("favorites").Has(name)
	}
	AddFavorite(name) {
		This.JSON.Get("favorites").Push(name)
	}
	LoadoutNames {
		get {
			output := []
			for key, value in This.JSON.Get("loadouts")
				output.Push(key)
			
			return output
		}
	}
	LoadoutName {
		get => This.JSON.Get("selected")
		set => This.JSON.Set("selected", Value)
	}
	SetBindingEntry(i, id) {
		This.currentBinding[i] := id
	}
	SetLoadoutEntry(i, id) {
		This.currentLoadout[i] := id
	}
	SaveLoadout(name) {
		This.LoadoutName := name
		l := Map()
		l.Set("bindings", This.currentBinding.Clone())
		l.Set("loadout", This.currentLoadout.Clone())
		This.JSON.Get("loadouts").Set(name, l)
		This.Save()
	}
	LoadLoadout(name) {
		This.LoadoutName := name
		This.currentBinding := This.JSON.Get("loadouts").Get(name).Get("bindings")
		This.currentLoadout := This.JSON.Get("loadouts").Get(name).Get("loadout")
	}
	DeleteLoadout(name) {
		if This.LoadoutName == name {
			This.LoadoutName := This.LoadoutNames.Get(1, "Default")
		}
		This.JSON.Get("loadouts").Delete(name)
		This.Save()
	}
}

Loadouts := LoadoutController()

ExitHandler(*) {
	Loadouts.Save()
}

OnExit(ExitHandler)

#include "gui.ahk"
SCP := StrategemControlPanel(Strategems, Loadouts)
SCP.UpdateBindingButtons(Loadouts.currentBinding)
SCP.UpdateLoadoutButtons(Loadouts.currentLoadout)

TriggerStrategem(num, tryOthers) {
	id := Loadouts.currentBinding[num]
	strat := strategems.Get(id)
	if strat.id == "default" and tryOthers != false {
		if Mod(num, 2) == 0
			TriggerStrategem(num-1, false)
		else
			TriggerStrategem(num+1, false)
	} else if strat.id == "all" {
		SCP.status := "Preparing..."
		toCall := []
		for id in Loadouts.currentBinding {
			s := strategems.Get(id)
			if s.type == "supportWeapon" and s.id != "expendableAntiTank" {
				toCall.Push(s)
			} else if s.type == "backpack" {
				toCall.Push(s)
			}
		}
		loop { ; Really bad sorting algorithm
			changed := false
			loop toCall.Length-1 {
				cur := toCall[A_Index]
				next := toCall[A_Index + 1]
				if cur.calldownDelay != "" and next.calldownDelay != "" {
					; MsgBox("compare " cur.calldownDelay " to " next.calldownDelay)
					if cur.calldownDelay < next.calldownDelay {
						toCall[A_Index] := next
						toCall[A_Index + 1] := cur
						changed := true
					}
				}
				if cur == next {
					toCall.RemoveAt(A_Index)
					changed := true
					break
				}
			}
		} until !changed
		SCP.status := "Calling All"
		for s in toCall {
			SCP.status .= "`n-"
			s.CallDown()
			SCP.status .= "- "
			SendMode("Event")
			if A_Index > 1 {
				prev := toCall[A_Index-1]
				if prev.calldownDelay != "" and s.calldownDelay != "" {
					SCP.status .= "... "
					delay := ((prev.calldownDelay - s.calldownDelay) * 1000) - 200
					; Send "{{" delay "}}"
					Sleep(delay)
				}
			}
			SCP.status .= s.Name
			; MouseClick()
			SendEvent("{Enter}")
			Sleep(200)
			; SendEvent("{Ctrl Down}{Ctrl Up}{Ctrl Down}{Ctrl Up}")
			; {Ctrl Down}
		}
		SCP.status .= "`nDone"
	} else {
		SCP.status := "Calling:`n" strat.Name
		strat.CallDown()
		SCP.status := "Called:`n" strat.Name
	}
}

NumPad1::TriggerStrategem(1, true)
NumPad2::TriggerStrategem(2, true)
NumPad3::TriggerStrategem(3, true)
NumPad4::TriggerStrategem(4, true)
NumPad5::TriggerStrategem(5, true)
NumPad6::TriggerStrategem(6, true)
NumPad7::TriggerStrategem(7, true)
NumPad8::TriggerStrategem(8, true)