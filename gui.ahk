#Requires AutoHotkey v2.0
#include "StrategemControlPanel.ahk"

; #NoTrayIcon
TraySetIcon("icon.ico", 1)

OpenFile(path, *) {
	try Run("edit " path)
	catch {
		Run("notepad " path)
	} 
}

CreateMenuBar() {
	FileMenu := Menu()
	FileMenu.Add("Open &strategems.json", OpenFile.Bind("strategems.json"))
	FileMenu.Add("Open &loadouts.json", OpenFile.Bind("loadouts.json"))
	FileMenu.Add("Open &config.json", OpenFile.Bind("config.json"))
	ScriptMenu := Menu()
	ScriptMenu.AddStandard()
	HelpMenu := Menu()
	; HelpMenu.Add("Key&bindings`tCtrl+/", ShowKeyBindings)
	; HelpMenu.Add("&About", ShowAbout)
	; HelpMenu.Add("&License", ShowLicense)

	Menus := MenuBar()
	Menus.Add("&File", FileMenu)
	Menus.Add("&Script", ScriptMenu)
	Menus.Add("&Help", HelpMenu)

	return Menus
}

Show(ControlMenu) {
	WinLeft := 99999999999
	WinTop  := 99999999999

	Loop MonitorGetCount() {
		MonitorLeft := 0
		MonitorTop := 0
		MonitorGet(A_Index, &MonitorLeft, &MonitorTop)
		if MonitorLeft <= WinLeft {
			WinLeft := MonitorLeft
			WinTop := MonitorTop
		}
	}

	ControlMenu.Show("X" WinLeft+25 " Y" WinTop+25)
}

BindingGridCellSize := 100

; @param Strategems Strategem[]
class StrategemControlPanel {

	Selected := 1
	LoadoutSelected := -1

	__New(Strategems, Loadouts) {
		this.Loadouts := Loadouts

		local Icons := IL_Create(80, 3, true)
		if !Icons {
			throw "Failed to create icon list"
		}
		DefaultIcon := IL_Add(Icons, "iconsSmall\icon.ico", 1)
		IconNameList := Map()
		loop Files "iconsSmall\*.png" {
			IconNameList.Set(A_LoopFileName, IL_Add(Icons, A_LoopFileFullPath, 0xFFFFFF, true))
		}

		ControlMenu := Gui("+MinimizeBox -MaximizeBox +MinSize400x400", "Strategem Control Panel")
		ControlMenu.MenuBar := CreateMenuBar()

		BindingGridWidth  := Config.Get("device").Get("width")
		BindingGridHeight := Config.Get("device").Get("height")
		This.BindingGridWidth  := BindingGridWidth
		This.BindingGridHeight := BindingGridHeight

		BindingMenu := ControlMenu.Add("GroupBox",
			"Section"
			" W" BindingGridWidth*BindingGridCellSize+10
			" H" BindingGridHeight*BindingGridCellSize+20,
		"Bindings")

		StrategemList := ControlMenu.Add("ListView", "Icon Background272727 CFFFFFF -Multi WP H400 Count" Strategems.Count, ["Name"])
		StrategemList.SetImageList(Icons)

		This.RowMap := Map()

		For id, strat in Strategems {
			This.RowMap.Set(StrategemList.Add("Icon" IconNameList.Get(strat.id ".png", DefaultIcon), strat.Name), strat.id)
		}
		StrategemList.OnEvent("DoubleClick", This.ClickStrategemButton.Bind(This))

		BindingMenuX := 0
		BindingMenuY := 0
		BindingMenu.GetPos(&BindingMenuX, &BindingMenuY)
		BindingButtonStartX := BindingMenuX + 5
		BindingButtonStartY := BindingMenuY + 15

		BindingButtons := []
		Loop BindingGridWidth {
			x := A_Index - 1
			Loop BindingGridHeight {
				y := BindingGridHeight - A_Index
				button := ControlMenu.Add("Picture",
					"Background272727"
					" w" BindingGridCellSize
					" h" BindingGridCellSize
					" x" BindingButtonStartX + BindingGridCellSize*x
					" y" BindingButtonStartY + BindingGridCellSize*y,
				"iconsLarge/icon.png")
				BindingButtons.Push(button)
				button.OnEvent("Click", This.ClickBindingButton.Bind(This, x, y, BindingButtons.Length))
			}
		}
		This.BindingButtons := BindingButtons
		This.Selection := 1 ; For the setter

		LoadoutsMenu := ControlMenu.Add("GroupBox", "YS W210 H65", "Loadout")
		This.LoadoutSelector := ControlMenu.Add("ComboBox", "Section XP+5 YP+15 W200", Loadouts.LoadoutNames)
		This.LoadoutSelector.Text := Loadouts.LoadoutName
		LoadoutSave := ControlMenu.Add("Button", "XP YP+22 W50", "Save")
		LoadoutSave.OnEvent("Click", This.SaveLoadout.Bind(This))
		LoadoutLoad := ControlMenu.Add("Button", "YP XP+50 W100", "Load")
		LoadoutLoad.OnEvent("Click", This.LoadLoadout.Bind(This))
		LoadoutDelete := ControlMenu.Add("Button", "YP XP+100 W50", "Delete")
		LoadoutDelete.OnEvent("Click", This.DeleteLoadout.Bind(This))
		This.StatusBox := ControlMenu.Add("Edit", "XS YS+70 ReadOnly W200 R5")

		LoadoutMenu := ControlMenu.Add("GroupBox",
			" XP W" BindingGridCellSize*2+10
			" H" BindingGridCellSize*2+40,
		"Loadout")
		LoadoutMenuX := 0
		LoadoutMenuY := 0
		LoadoutMenu.GetPos(&LoadoutMenuX, &LoadoutMenuY)
		LoadoutButtonStartX := LoadoutMenuX + 5
		LoadoutButtonStartY := LoadoutMenuY + 15
		This.LoadoutButtons := []
		
		Loop 2 {
			x := A_Index-1
			Loop 2 {
				y := A_Index-1
				i := x*2 + y
				button := ControlMenu.Add("Picture",
				"Background272727"
				" w" BindingGridCellSize
				" h" BindingGridCellSize
				" x" LoadoutButtonStartX + BindingGridCellSize*x
				" y" LoadoutButtonStartY + BindingGridCellSize*y,
				"iconsLarge/icon.png")
				button.OnEvent("Click", This.ClickLoadoutButton.Bind(this, x, y, i+1))
				This.LoadoutButtons.Push(button)
			}
		}
		LoadoutApplyButton := ControlMenu.Add("Button",
		"X" LoadoutButtonStartX
		" YP+" BindingGridCellSize
		" W" BindingGridCellSize*2,
		"Generate Bindings")
		LoadoutApplyButton.OnEvent("Click", This.GenerateBindings.Bind(This))

		Show(ControlMenu)

		ControlMenu.OnEvent("Close", This.CloseHandler.Bind(This))
	}
	CloseHandler(*) {
		ExitApp()
	}
	ClickStrategemButton(obj, row) {
		if row == 0 { ; Clicked in between.
			return
		}
		id := This.RowMap.Get(row)
		if This.Selection != -1 {
			This.UpdateBindingButton(This.Selection, id)
		} else {
			if id == "default" {
				id := "empty"
			}
			if (id != "empty" and Strategems.Get(id).Type == "misc") or id == "eagleRearm" {
				SoundPlay("*64")
				This.status := "This strategem is not selectable for your loadout."
			} else {
				This.status := "Press `"Generate Bindings`" to apply this loadout."
				for stratID in This.Loadouts.currentLoadout {
					if stratID == "empty" or stratID == "default" {
						continue
					}
					if stratID == id { ; Swap
						This.UpdateLoadoutButton(A_Index, This.Loadouts.currentLoadout[This.LoadoutSelection])
						break
					}
				}
				This.UpdateLoadoutButton(This.LoadoutSelection, id)
				if This.LoadoutSelection < 4 {
					This.LoadoutSelection += 1
				}
			}
		}
	}
	ClickBindingButton(x, y, i, *) {
		This.Selection := i
	}
	ClickLoadoutButton(x, y, i, *) {
		This.LoadoutSelection := i
	}
	UpdateBindingButton(i, id) {
		This.Loadouts.SetBindingEntry(i, id)
		if This.BindingButtons[i].Value == "iconsLarge/" id ".png" {
			return
		}
		This.BindingButtons[i].Value := "iconsLarge/" id ".png"
	}
	UpdateLoadoutButton(i, id) {
		This.Loadouts.SetLoadoutEntry(i, id)
		if This.LoadoutButtons[i].Value == "iconsLarge/" id ".png" {
			return
		}
		This.LoadoutButtons[i].Value := "iconsLarge/" id ".png"
	}
	SaveLoadout(*) {
		This.Loadouts.SaveLoadout(This.LoadoutSelector.Text)
		This.LoadoutSelector.Add([This.LoadoutSelector.Text])
	}
	LoadLoadout(*) {
		This.Loadouts.LoadLoadout(This.LoadoutSelector.Text)
		This.UpdateBindingButtons(This.Loadouts.currentBinding)
		This.UpdateLoadoutButtons(This.Loadouts.currentLoadout)
	}
	DeleteLoadout(*) {
		This.LoadoutSelector.Delete(This.LoadoutSelector.Value)
		This.Loadouts.DeleteLoadout(This.LoadoutSelector.Text)
		This.LoadoutSelector.Text := This.Loadouts.LoadoutName
	}
	UpdateBindingButtons(strategemIDs) {
		Loop This.BindingGridWidth*This.BindingGridHeight {
			This.BindingButtons[A_Index].Value := "iconsLarge/" strategemIDs[A_Index] ".png"
		}
	}
	UpdateLoadoutButtons(strategemIDs) {
		Loop 4 {
			This.LoadoutButtons[A_Index].Value := "iconsLarge/" strategemIDs[A_Index] ".png"
		}
	}
	GenerateBindings(*) {
		try SoundPlay("bindGen.wav", 0)
		This.Selection := -1
		This.LoadoutSelection := -1
		This.status := "Binding defaults..."
		Loop This.BindingButtons.Length {
			This.UpdateBindingButton(A_Index, "default")
		}
		For num, rule in Config.Get("bindings") {
			if rule.Has("value") {
				This.UpdateBindingButton(num, rule.Get("value"))
			}
		}
		This.status .= "`nEnumerating..."
		stratsToAssign := Map()
		for stratID in This.Loadouts.currentLoadout {
			if stratID == "empty" or stratID == "default" {
				This.LoadoutButtons[A_Index].Opt("Background880000")
				This.LoadoutButtons[A_Index].Redraw()
			} else {
				stratsToAssign.Set(Strategems.Get(stratID), A_Index)
			}
		}
		This.status .= "`nBinding " stratsToAssign.Count " strategem(s)..."
		priority := 0
		PriorityLoop:
		loop {
			priority += 1
			This.status .= "`nNew Priority Level: " priority
			iterator := stratsToAssign.__Enum()
			AssignLoop:
			loop { ; For-Loops fail because removing elements preemptively ends the loop.
				; strat := "default"
				; button := 1
				if !iterator(&strat, &button) {
					break
				}
				This.status .= "`n  Trying: " strat.id
				assignIndex := A_Index
				validAcceptRules := 0
				RuleLoop:
				for rule in Config.Get("bindings") {
					slot := A_Index
					This.status .= "`n    " slot ": "
					if rule.Has("accept") {
						if priority > rule.Get("accept").Length {
							This.status .= "Rule has no validType for this priority."
							continue RuleLoop
						} else {
							validAcceptRules += 1
						}
						This.LoadoutButtons[button].Opt("Background888800")
							This.LoadoutButtons[button].Redraw()
						validType := rule.Get("accept").Get(priority)
						if This.Loadouts.currentBinding[slot] == "default" or This.Loadouts.currentBinding[slot] == "empty" {
							This.Selection := slot
							if validType == "any" or validType == strat.Type {
								This.status .= "ASSIGNED via accept: " validType
								This.UpdateBindingButton(slot, strat.id)
								stratsToAssign.Delete(strat)
								iterator := stratsToAssign.__Enum()
								if validType == "any" {
									This.LoadoutButtons[button].Opt("Background008888")
								} else {
									This.LoadoutButtons[button].Opt("Background008800")
								}
								This.LoadoutButtons[button].Redraw()
								break RuleLoop
							} else {
								This.status .= strat.Type " != " validType
							}
						} else {
							This.status .= "collision: " This.Loadouts.currentBinding[A_Index]
						}
					} else {
						This.status .= "Not an accept rule."
					}
				}
				if validAcceptRules == 0 {
					This.status .= "`n  Ran out of accept rules."
					break AssignLoop
				}
			}
		} until stratsToAssign.Count == 0 or validAcceptRules == 0
		This.status .= "`nDone in " priority " iteration(s)."
		This.Selection := -1
		try SoundPlay("bindGenEnd.wav", 0)
	}
	Selection {
		set {
			if This.Selected != -1 {
				This.BindingButtons[This.Selected].Opt("Background272727")
				if This.Selected != Value
					This.BindingButtons[This.Selected].Redraw()
			}
			if Value != -1 {
				This.LoadoutSelection := -1
				This.BindingButtons[Value].Opt("Background404040")
				This.BindingButtons[Value].Redraw()
			}
			This.Selected := Value
		}
		get {
			return This.Selected
		}
	}
	LoadoutSelection {
		set {
			if This.LoadoutSelected != -1 {
				This.LoadoutButtons[This.LoadoutSelected].Opt("Background272727")
				if This.LoadoutSelected != Value
					This.LoadoutButtons[This.LoadoutSelected].Redraw()
			}
			if Value != -1 {
				This.Selection := -1
				This.LoadoutButtons[Value].Opt("Background404040")
				This.LoadoutButtons[Value].Redraw()
			}
			This.LoadoutSelected := Value
		}
		get {
			return This.LoadoutSelected
		}
	}
	status {
		set {
			This.StatusBox.Value := Value
			ControlSend("^{End}", This.StatusBox.Hwnd)
		}
		get {
			return This.StatusBox.Value
		}
	}
}
