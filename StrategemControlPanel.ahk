#Requires AutoHotkey v2.0
#SingleInstance Force
#include <JXON>

SetCapsLockState "AlwaysOff"

global StratUP    := "F1"
global StratLEFT  := "F3"
global StratDOWN  := "F6"
global StratRIGHT := "F4"

global StrategemAssignment := [ ; These are the default strategems when you start the script.
	"Reinforce",
	"Resupply",
	"[Default]", ; "Default" means the same as "Unbound," but if the other paired vertical key is bound, it will clone that action.
	"[Default]", ; Example: I have a WASP Launcher, so no backpack. I bind "5" to call down my WASP.
	"[Default]", ; Now, when I hit "6" on accident, it calls down a WASP Launcher (6 is above 5)
	"[Default]",
	"[Default]",
	"[Default]",
]

#NoTrayIcon
TraySetIcon(EnvGet("HOME") "HelldiverSkull.ico")

forceEnableNumbers := false

try {
	throw "poopy"
;	global AHI := AutoHotInterception()
;	mouseID := AHI.GetKeyboardId(0x258A, 0x002F)
;	mouseContext := AHI.CreateContextManager(mouseID)
} catch Any {
	forceEnableNumbers := true
}

;This is the delay that I found makes all the difference so that HD2 accepts my input. This is 4 frames/key at 60FPS.
KeyDownTime := 30
KeyUpTime := 30

global IsCalling := false

class Strategem extends Object {
	Name := "Unused"
	ClassID := "blank"
	CalldownCode := ""
	Category := ""
	Complexity := 0
	__New(ClassID, Name, CalldownCode, Category, Complexity) {
		this.Name := Name
		this.ClassID := ClassID
		this.CalldownCode := CalldownCode
		this.Category := Category
		this.Complexity := Complexity
	}
	CallDown() {
		global StateBar
		global IsCalling
		if(this.CalldownCode == "")
			Return
		
		IsCalling := true
		SetKeyDelay(6,0)
		StateBar.SetText("Calling " this.Name, 3)
		if(not StrategemHeroMode.Value)
			SendEvent("{Ctrl Down}")
		SendEvent("{" StratUP " Up}{" StratDOWN " Up}{" StratLEFT " Up}{" StratRIGHT " Up}")
		SetKeyDelay(KeyDownTime,KeyUpTime)
		local CallDownInputs := ""
		Loop Parse this.CallDownCode {
			if(A_LoopField == "w")
				CallDownInputs := CallDownInputs . "{" StratUP "}"
			if(A_LoopField == "a")
				CallDownInputs := CallDownInputs . "{" StratLEFT "}"
			if(A_LoopField == "s")
				CallDownInputs := CallDownInputs . "{" StratDOWN "}"
			if(A_LoopField == "d")
				CallDownInputs := CallDownInputs . "{" StratRIGHT "}"
		}
		SendEvent(CallDownInputs)
		if(not StrategemHeroMode.Value)
			SendEvent("{Ctrl Up}")
		IsCalling := false
		StateBar.SetText("Last: " this.Name, 3)
	}
}

global Strategems := [
	Strategem("empty", "[Unbound]", "", "", 0),
	Strategem("empty", "[Default]", "", "", 0),
	; Mission Strategems
	Strategem("reinforce", "Reinforce", "wsdaw", "Mission - Utility", 3),
	Strategem("resupply", "Resupply", "sswd", "Mission - Utility", 2),
	Strategem("eagleRearm", "Eagle Rearm", "wwawd", "Mission - Utility", 3),
	Strategem("hellbomb", "Hellbomb", "swaswdsw", "Mission - Utility", 9),
	Strategem("SOSBeacon", "SOS Beacon", "wsdw", "Mission - Utility", 2),
	; Objectives
	Strategem("SSSDDelivery", "SSSD Delivery", "sssww", "Mission - Objective", 0),
	Strategem("prospectingDrill", "Prospecting Drill", "ssadss", "Mission - Objective", 0),
	Strategem("superEarthFlag", "Super Earth Flag", "swsw", "Mission - Objective", 0),
	Strategem("uploadData", "Upload Data", "adwww", "Mission - Objective", 0),
	Strategem("seismicProbe", "Seismic Probe", "wwadss", "Mission - Objective", 0),
;	Strategem("orbitalIlluminationFlare", "Orbital Illumination Flare", "ddaa", "Mission - Objective", 0), ; This strategem no longer (or never) exists in-game
	Strategem("SEAFArtillery", "SEAF Artillery", "dwws", "Mission - Objective", 0),
;	Strategem("darkFluidVessel", "Dark Fluid Vessel", "wadsww", "Mission - Objective", 0), ; This strategem's major order is no longer active.
;	Strategem("tectonicDrill", "Tectonic Drill", "wswsws", "Mission - Objective", 0), ; This atrategem's major order is no longer active.
	Strategem("hiveBreakerDrill", "Hive Breaker Drill", "awsdss", "Mission - Objective", 0),

	; Eagles
	Strategem("eagleStrafingRun", "Eagle Strafing Run", "wdd", "Eagle", 1),
	Strategem("eagleAirstrike", "Eagle Airstrike", "wdsd", "Eagle", 2),
	Strategem("eagleClusterBomb", "Eagle Cluster Bomb", "wdssd", "Eagle", 3),
	Strategem("eagleNapalmAirstrike", "Eagle Napalm Airstrike", "wdsw", "Eagle", 2),
	Strategem("eagleSmokeStrike", "Eagle Smoke Strike", "wdws", "Eagle", 2),
	Strategem("eagle110mmRocketPods", "Eagle 110mm Rocket Pods", "wdwa", "Eagle", 2),
	Strategem("eagle500KGBomb", "Eagle 500KG Bomb", "wdsss", "Eagle", 2),
	; Orbitals
	Strategem("orbitalPrecisionStrike", "Orbital Precision Strike", "ddw", "Orbital - Explosive", 1),
	Strategem("orbitalGasStrike", "Orbital Gas Strike", "ddsd", "Orbital - Explosive", 1),
	Strategem("orbitalGatlingBarrage", "Orbital Gatling Barrage", "dsaww", "Orbital - Explosive", 4),
	Strategem("orbitalAirburstStrike", "Orbital Airburst Strike", "ddd", "Orbital - Explosive", 1),
	Strategem("orbital120mmHEBarrage", "Orbital 120mm HE Barrage", "ddsads", "Orbital - Explosive", 3),
	Strategem("orbital380mmHEBarrage", "Orbital 380mm HE Barrage", "dswwass", "Orbital - Explosive", 5),
	Strategem("orbitalWalkingBarrage", "Orbital Walking Barrage", "dsdsds", "Orbital - Explosive", 2),
	Strategem("orbitalLaser", "Orbital Laser", "dswds", "Orbital", 3),
	Strategem("orbitalNapalmBarrage", "Orbital Napalm Barrage", "ddsadw", "Orbital", 4),
	Strategem("orbitalRailcannonStrike", "Orbital Railcannon Strike", "dwssd", "Orbital", 4),

	; Support Weapons
	Strategem("machineGun", "Machine Gun", "saswd", "Support - Machine Gun", 4),
	Strategem("stalwart", "Stalwart", "saswwa", "Support - Machine Gun", 4),
	Strategem("heavyMachineGun", "Heavy Machine Gun", "sawss", "Support - Machine Gun", 4),
	Strategem("antiMaterielRifle", "Anti-Materiel Rifle", "sadws", "Support", 4),
	Strategem("expendableAntiTank", "Expendable Anti-Tank", "ssawd", "Support - Anti-Tank", 3),
	Strategem("recoillessRifle", "Recoilless Rifle", "sadda", "Support - Anti-Tank", 4),
	Strategem("commando", "Commando", "sawsd", "Support - Anti-Tank", 5),
	Strategem("SPEAR", "S.P.E.A.R.", "sswss", "Support - Anti-Tank", 3),
	Strategem("quasarCannon", "Quasar Cannon", "sswad", "Support - Anti-Tank", 4),
	Strategem("airburstRocketLauncher", "Airburst Rocket Launcher", "swwad", "Support - Explosive", 4),
	Strategem("autocannon", "Autocannon", "saswwd", "Support - Explosive", 4),
	Strategem("grenadeLauncher", "Grenade Launcher", "sawas", "Support - Explosive", 4),
	Strategem("railgun", "Railgun", "sdswad", "Support", 5),
	Strategem("WASPLauncher", "W.A.S.P. Launcher", "sswsd", "Support - Explosive", 4),
	Strategem("laserCannon", "Laser Cannon", "saswa", "Support", 4),
	Strategem("arcThrower", "Arc Thrower", "sdswaa", "Support", 4),
	Strategem("flamethrower", "Flamethrower", "sawsw", "Support", 4),
	Strategem("sterilizer", "Sterilizer", "sawsa", "Support", 4),
	;Backpacks
	Strategem("jumpPack", "Jump Pack", "swwsw", "Backpack - Utility", 6),
	Strategem("supplyPack", "Supply Pack", "saswws", "Backpack - Utility", 5),
	Strategem("ballisticShield", "Ballistic Shield", "sasswa", "Backpack - Defense", 5),
	Strategem("hellbombPack", "Portable Hellbomb", "sdwww", "Backpack - Defense", 5),
	Strategem("shieldGeneratorPack", "Shield Generator Pack", "swadad", "Backpack - Defense", 5),
	Strategem("directionalShield", "Directional Shield", "swadww", "Backpack - Defense", 5),
	Strategem("guardDog", "Guard Dog", "swawds", "Backpack - Offense", 5),
	Strategem("guardDogRover", "Guard Dog - Rover", "swawdd", "Backpack - Offense", 5),
	Strategem("guardDogDogBreath", "Guard Dog - Dog Breath", "swawdw", "Backpack - Offense", 5),
	; Vehicles
	Strategem("fastReconVehicle", "Fast Recon Vehicle", "asdsdsw", "Vehicle", 9),
	Strategem("patriotExosuit", "Patriot Exosuit", "asdwass", "Vehicle", 9),
	Strategem("emancipatorExosuit", "Emancipator Exosuit", "asdwasw", "Vehicle", 9),

	; Turrets & Emplacements
	Strategem("HMGEmplacement", "HMG Emplacement", "swadda", "Emplacement - Offense", 4),
	Strategem("ATEmplacement", "Anti-Tank Emplacement", "swaddd", "Emplacement - Offense", 4),
	Strategem("shieldGeneratorRelay", "Shield Generator Relay", "ssadad", "Emplacement - Defense", 4),
	Strategem("teslaTower", "Tesla Tower", "swdwad", "Emplacement - Defense", 4),
	Strategem("APMinefield", "Anti-Personnel Minefield", "sawd", "Emplacement - Defense", 2),
	Strategem("incendiaryMinefield", "Incendiary Mines", "saas", "Emplacement - Defense", 2),
	Strategem("ATMinefield", "Anti-Tank Mines", "saww", "Emplacement - Defense", 2),
	Strategem("gasMinefield", "Gas Mines", "saad", "Emplacement - Defense", 2),
	Strategem("machineGunSentry", "Machine Gun Sentry", "swddw", "Emplacement - Turret", 3),
	Strategem("gatlingSentry", "Gatling Sentry", "swda", "Emplacement - Turret", 3),
	Strategem("mortarSentry", "Mortar Sentry", "swdds", "Emplacement - Turret", 3),
	Strategem("autocannonSentry", "Autocannon Sentry", "swdwaw", "Emplacement - Turret", 5),
	Strategem("rocketSentry", "Rocket Sentry", "swdda", "Emplacement - Turret", 3),
	Strategem("EMSMortarSentry", "EMS Mortar Sentry", "swdsd", "Emplacement - Turret", 4),
	Strategem("flameSentry", "Flamethrower Sentry", "swdsww", "Emplacement - Turret", 5),
]

AssignStrategem(slot, stratName) {
	global StrategemAssignment
	global StrategemButtons
	
	StrategemAssignment[slot] := stratName
	StrategemButtons[slot].Text := stratName
}

FindStrategem(name) {
	global Strategems
	For strat in Strategems {
		if(strat.Name == name)
			Return strat
	}
}

CloseWindow(*) {
	ExitApp
}
ToggleMode(*) {
	StrategemHeroMode.Value := not StrategemHeroMode.Value
}

SetEditIndex(i,*) {
	global CurrentEditIndex
	if(InstantMode.Value) {
		try {
			WinActivate("HELLDIVERS")
			FindStrategem(StrategemAssignment[i]).CallDown()
			WinActivate(ControlMenu.hwnd)
		} catch {
			MsgBox("HELLDIVERS 2 is not running.", "Error", "OK Iconx")
		}
	} else {
		CurrentEditIndex := i
	}
}

global CurrentEditIndex := 1
ClickStrategemList(_, Row) {
	global CurrentEditIndex
	
	local s := FindStrategem(StrategemList.GetText(Row,3))
	if(InstantMode.Value) {
		try {
			WinActivate("HELLDIVERS")
			s.CallDown()
			WinActivate(ControlMenu.hwnd)
		} catch {
			MsgBox("HELLDIVERS 2 is not running.", "Error", "OK Iconx")
		}
	} else {
		AssignStrategem(CurrentEditIndex, s.Name)
	}
}

SaveLoadout(Name := "", *) {
	if(Name == "")
		Name := LoadoutSelector.Text
	if(Name == "") {
		MsgBox("Loadout name cannot be empty.", "Error", "OK Iconx")
		Return
	}
	if(Name != "__latest" and not Loadouts.has(Name)) {
		LoadoutSelector.Add([LoadoutSelector.Text])
		LoadoutNames.Push(LoadoutSelector.Text)
	}
	
	Loadouts[Name] := StrategemAssignment.Clone()
	FileDelete("HD2Loadouts.json")
	FileAppend(JXON_Dump(Loadouts,4), "HD2Loadouts.json")
}
OnExit SaveLoadout.bind("__latest")

LoadLoadout(Name := "", *) {
	if(Name == "")
		Name := LoadoutSelector.Text
	if(Loadouts.has(Name))
		For stratName in Loadouts[Name] {
			AssignStrategem(A_Index, stratName)
		}
}

RemoveLoadout(Name := "", *) {
	if(Name == "")
		Name := LoadoutSelector.Text
	if(Loadouts.has(Name))
		Loadouts.Delete(Name)
	For index, loadoutName in LoadoutNames {
		if(loadoutName == Name) {
			LoadoutSelector.Delete(index)
			LoadoutNames.RemoveAt(index)
			break
		}
	}
	
}

SelectLoadout(delta) {
	NewIndex := LoadoutSelector.Value + delta
	if(NewIndex > LoadoutNames.Length)
		NewIndex := Mod(NewIndex-1, LoadoutNames.Length)+1
	while(NewIndex < 1)
		NewIndex := LoadoutNames.Length + NewIndex
	
	LoadoutSelector.Value := NewIndex
}

OpenLoadoutFile(*) {
	try Run "edit " A_WorkingDir "\HD2Loadouts.json"
	catch {
		Run "notepad " A_WorkingDir "\HD2Loadouts.json"
	}
}

ShowKeyBindings(*) {
	KeybindingGUI := Gui("+AlwaysOnTop +Owner" ControlMenu.hwnd, "Keybindings")
	KeyList := KeybindingGUI.Add("ListView", "R15 -Hdr W300", ["Keybinding", "Action"])
	
	KeyList.Add(,"1", "Send Strategem #1")
	KeyList.Add(,"2", "Send Strategem #2")
	KeyList.Add(,"3", "Send Strategem #3")
	KeyList.Add(,"4", "Send Strategem #4")
	KeyList.Add(,"5", "Send Strategem #5")
	KeyList.Add(,"6", "Send Strategem #6")
	KeyList.Add(,"7", "Send Strategem #7")
	KeyList.Add(,"8", "Send Strategem #8")
	KeyList.Add(,"Win+S", "Toggle Strategem Hero mode")
	KeyList.Add(,"Win+W", "Toggle Focus on Strategem Control Panel")
	KeyList.Add(,"Win+R", "Restart Strategem Control Panel")
	KeyList.Add(,"Win+Scroll", "Hot-Switch Selected Loadout")
	KeyList.Add(,"Win+RClick", "Load Selected Loadout")
	
	KeyList.ModifyCol(1, "Auto")
	KeybindingGUI.Show()
	
	WinWaitClose(KeybindingGUI)
}
ShowAbout(*) {
	AboutGUI := Gui("+AlwaysOnTop +Owner" ControlMenu.hwnd, "About")
	AboutGUI.Add("Text", "+Wrap W300", "This program is meant to interface with a Redragon Zone Aatrox mouse (M811-RGB Pro). It should work with minimal changes (Device PID and VID) to the source code. My mouse has 8 side keys which send numbers 1-8 with an emulated keyboard. This software depends on AutoHotInterception and JXON to properly function.")
	AboutGUI.Show()
	WinWaitClose(AboutGUI.hwnd)
}
ShowLicense(*) {
	LicenseGUI := Gui("+AlwaysOnTop +Owner" ControlMenu.hwnd, "License")
	LicenseGUI.Add("Text", "+Wrap W300", "©️2025 Perodactyl (Github User). This software is licensed under the GNU GPLv3 License. Users have the right to freely modify and redistribute the program and its source code as long as they retain the same (or a later version of this) license. This product comes with no warranty.")
	LicenseGUI.Show()
	WinWaitClose(LicenseGUI.hwnd)
}

if(not FileExist("HD2Loadouts.json")) {
	FileAppend('{}', "HD2Loadouts.json")
}
LoadoutString := FileRead("HD2Loadouts.json")
Loadouts := JXON_Load(&LoadoutString)
LoadoutNames := []
For key, value in Loadouts {
	if(key != "__latest") {
		LoadoutNames.push(key)
	}
}

FileMenu := Menu()
FileMenu.Add("Open &Loadouts.json", OpenLoadoutFile)
FileMenu.Add("&Remove selected loadout", RemoveLoadout.Bind(""))
ScriptMenu := Menu()
ScriptMenu.AddStandard()
HelpMenu := Menu()
HelpMenu.Add("Key&bindings`tCtrl+/", ShowKeyBindings)
HelpMenu.Add("&About", ShowAbout)
HelpMenu.Add("&License", ShowLicense)

Menus := MenuBar()
Menus.Add("&File", FileMenu)
Menus.Add("&Script", ScriptMenu)
Menus.Add("&Help", HelpMenu)

ControlMenu := Gui("+AlwaysOnTop +MinimizeBox -MaximizeBox +MinSize400x400", "Strategem Control Panel")
ControlMenu.OnEvent("Close", CloseWindow)
ControlMenu.MenuBar := Menus

StrategemList := ControlMenu.Add("ListView", "R15 Section -Multi W300 Count" Strategems.Length, ["#", "Category", "Name"])

; Mode Selector
ControlMenu.Add("GroupBox", "XP+0 W170 H65 Section", "Mode")
StrategemHeroMode := ControlMenu.Add("Checkbox", "XS+10 YP+15", "Strategem Hero")
InstantMode := ControlMenu.Add("Checkbox", "XP+0", "Instant Input Mode")

; Loadout Selector
ControlMenu.Add("GroupBox", "XP+170 YS+0 Section W120 H65", "Loadouts")
LoadoutSelector := ControlMenu.Add("ComboBox", "XP+10 YP+15 W100", LoadoutNames)
LoadoutSelector.Choose(1)

LoadoutSave := ControlMenu.Add("Button", "XP+0 YP+22 W50", "Save")
LoadoutLoad := ControlMenu.Add("Button", "XP+50 YP+0 W50", "Load")
LoadoutSave.OnEvent("Click", SaveLoadout.Bind(""))
LoadoutLoad.OnEvent("Click", LoadLoadout.Bind(""))

; Strategem Assignment Panel
ControlMenu.Add("GroupBox", "Section Y0 W110 R18", "Assignment")

global StrategemButtons := []

; The first button has different positioning rules.
StrategemButtons.Push(ControlMenu.Add("Button", "XS+10 YS+20 R2 W90", StrategemAssignment[1]))
For assignment in StrategemAssignment {
	if(A_Index != 1)
		StrategemButtons.Push(ControlMenu.Add("Button", "XP+0 WP+0 R2 W90", StrategemAssignment[A_Index]))
}

StrategemList.OnEvent("Click", ClickStrategemList)
For b in StrategemButtons {
	b.OnEvent("Click", SetEditIndex.Bind(A_Index))
}

For strat in Strategems {
	StrategemList.Add(, StrLen(strat.CalldownCode), strat.Category, strat.Name)
}
StrategemList.ModifyCol(2, "Auto")

; Statusbar
StateBar := ControlMenu.Add("Statusbar", "", "")
StateBar.SetParts(80, 80)
StateBar.SetText(Strategems.Length " strategems", 1)

LoadLoadout("__latest")

WinLeft := 0
WinTop := 0
MonitorGet(MonitorGetPrimary(),&WinLeft,&WinTop)
ControlMenu.Show("X" WinLeft+25 " Y" WinTop+25)

#HotIf false

*1::{
	global StrategemAssignment
	s := FindStrategem(StrategemAssignment[1])
	if(s.Name == "[Default]") {
		FindStrategem(StrategemAssignment[2]).CallDown()
	} else s.CallDown()
}
*2::{
	global StrategemAssignment
	s := FindStrategem(StrategemAssignment[2])
	if(s.Name == "[Default]") {
		FindStrategem(StrategemAssignment[1]).CallDown()
	} else s.CallDown()
}
*3::{
	global StrategemAssignment
	s := FindStrategem(StrategemAssignment[3])
	if(s.Name == "[Default]") {
		FindStrategem(StrategemAssignment[4]).CallDown()
	} else s.CallDown()
}
*4::{
	global StrategemAssignment
	s := FindStrategem(StrategemAssignment[4])
	if(s.Name == "[Default]") {
		FindStrategem(StrategemAssignment[3]).CallDown()
	} else s.CallDown()
}
*5::{
	global StrategemAssignment
	s := FindStrategem(StrategemAssignment[5])
	if(s.Name == "[Default]") {
		FindStrategem(StrategemAssignment[6]).CallDown()
	} else s.CallDown()
}
*6::{
	global StrategemAssignment
	s := FindStrategem(StrategemAssignment[6])
	if(s.Name == "[Default]") {
		FindStrategem(StrategemAssignment[5]).CallDown()
	} else s.CallDown()
}
*7::{
	global StrategemAssignment
	s := FindStrategem(StrategemAssignment[7])
	if(s.Name == "[Default]") {
		FindStrategem(StrategemAssignment[8]).CallDown()
	} else s.CallDown()
}
*8::{
	global StrategemAssignment
	s := FindStrategem(StrategemAssignment[8])
	if(s.Name == "[Default]") {
		FindStrategem(StrategemAssignment[7]).CallDown()
	} else s.CallDown()
}
#HotIf

#HotIf WinActive("HELLDIVERS") or WinActive(ControlMenu.hwnd)
#S::{
	ToggleMode
}
#R::{
	Reload
}

; Hot loadout selection
#WheelDown::SelectLoadout(1)
#WheelUp::SelectLoadout(-1)

#RButton::LoadLoadout()

; Stim
*XButton1::SendEvent("{v Down}")
*XButton1 Up::SendEvent("{v Up}")

; Reload / Weapon Settings
*XButton2::SendEvent("{r Down}")
*XButton2 Up::SendEvent("{r Up}")

#HotIf

#HotIf WinActive("HELLDIVERS")
#W::{
	WinActivate(ControlMenu.hwnd)
}

~*W::{
	global IsCalling
	if(not IsCalling)
		Send("{" StratUP " Down}")
}
~*W Up::{
	global IsCalling
	if(not IsCalling)
		Send("{" StratUP " Up}")
}
~*A::{
	global IsCalling
	if(not IsCalling)
		Send("{" StratLEFT " Down}")
}
~*A Up::{
	global IsCalling
	if(not IsCalling)
		Send("{" StratLEFT " Up}")
}
~*S::{
	global IsCalling
	if(not IsCalling)
		Send("{" StratDOWN " Down}")
}
~*S Up::{
	global IsCalling
	if(not IsCalling)
		Send("{" StratDOWN " Up}")
}
~*D::{
	global IsCalling
	if(not IsCalling)
		Send("{" StratRIGHT " Down}")
}
~*D Up::{
	global IsCalling
	if(not IsCalling)
		Send("{" StratRIGHT " Up}")
}

#HotIf

#HotIf WinActive(ControlMenu.hwnd)
#W::{
	WinActivate("HELLDIVERS")
}