#Requires AutoHotkey v2.0
#SingleInstance Force

global WM_CHAR          := 0x0102
global WM_INPUT         := 0x00FF

global RIM_TYPEMOUSE    :=      0
global RIM_TYPEKEYBOARD :=      1
global RIM_TYPEHID      :=      2

global RI_KEY_MAKE		:=      0
global RI_KEY_BREAK     :=      1
global RI_KEY_E0        :=      2
global RI_KEY_E1        :=      4

class HIDDevice {

	__New(handle) {
		length := 0
		DllCall("GetRawInputDeviceInfo", "ptr", handle, "uint", 0x2000000b, "ptr", 0, "uint*", &length)
		buf := Buffer(length) ; RID_DEVICE_INFO
		NumPut("uint", length, buf, 0)
		DllCall("GetRawInputDeviceInfo", "ptr", handle, "uint", 0x2000000b, "ptr", buf, "uint*", &length)
		this.type := NumGet(buf, 4, "uint")
		this.infoBuf := buf
		if this.type == RIM_TYPEHID {
			this.vid := NumGet(this.infoBuf, 8, "uint")
			this.pid := NumGet(this.infoBuf, 12, "uint")
			this.usagePage := NumGet(this.infoBuf, 20, "ushort"),
			this.usage := NumGet(this.infoBuf, 22, "ushort")
		}
	}
	ToString() {
		typeString := "unknown"
		if this.type == RIM_TYPEMOUSE {
			typeString := "mouse"
		} else if this.type == RIM_TYPEKEYBOARD {
			typeString := "kbd"
		} else if this.type == RIM_TYPEHID {
			/* 
			DWORD	4 0		cbSize
			DWORD	4 4		dwType
			-- start of HID-specific struct
			DWORD	4 8		dwVendorId
			DWORD	4 12	dwProductId
			DWORD	4 16	dwVersionNumber
			USHORT	2 20	usUsagePage
			USHORT	2 22	usUsage
			*/
			typeString := Format("VID: 0x{1:04x} PID: 0x{2:04x} page: 0x{3:02x} usage: 0x{4:02x}",
				NumGet(this.infoBuf, 8, "uint"),
				NumGet(this.infoBuf, 12, "uint"),
				NumGet(this.infoBuf, 20, "ushort"),
				NumGet(this.infoBuf, 22, "ushort")
			)
		}
		return "hiddevice " typeString
	}
}

class HIDControl {
	__New(vid, pid) {
		this.GetHIDDevices()
		; this.Register(vid, pid)
	}
	GetHIDDevices() {
		count := 0
		; Args: nullptr pRawInputDeviceList, out uint* puiNumDevices, in uint cbSize
		; Action: Stores number of devices in puiNumDevices
		elementSize := A_PtrSize * 2
		DllCall("GetRawInputDeviceList", "ptr", 0, "uint*", &count, "uint", elementSize)
		buf := Buffer(count * elementSize)
		; Args: uint* pRawInputDeviceList[], in uint* puiNumDevices, in uint cbSize
		; Action: Stores {HANDLE hDevice, DWORD dwType} structs in pRawInputDeviceList
		DllCall("GetRawInputDeviceList", "ptr", buf, "uint*", &count, "uint", elementSize)
		; @type HIDDevice[]
		this.devices := []
		Loop count {
			this.devices.Push(HIDDevice(NumGet(buf, (A_Index-1) * elementSize, "uint")))
		}
	}
	Register(vid, pid) {
		targets := []
		For d in this.devices {
			if d.type == RIM_TYPEHID {
				; if d.vid == vid and d.pid == pid {
					targets.Push([d.usagePage, d.usage])
				; }
			}
		}
		; MsgBox("Registered " targets.Length " devices.")
		RawInputDeviceSize := 8 + A_PtrSize
		buf := Buffer(targets.Length * RawInputDeviceSize)
		For target in targets {
			offset := (A_Index - 1) * RawInputDeviceSize
			NumPut("ushort", target[1], buf, offset + 0)
			NumPut("ushort", target[1], buf, offset + 2)
			NumPut("uint", 0, buf, offset + 4)
			NumPut("ptr", window.Hwnd, buf, offset + 6)
		}
		DllCall("RegisterRawInputDevices", "ptr", buf, "uint", targets.Length, "uint", RawInputDeviceSize)
	}
	report() {
		output := ""
		For d in this.devices {
			output := output "`n" String(d)
		}
		
		MsgBox(output)
	}
	HANDLE_WM_INPUT(WParam, LParam, *) {
		MsgBox("aaaa")
		; pcbSize := 0
		; DllCall("GetRawInputData", "ptr", LParam, "uint", 0x10000003, "ptr", 0, "ptr", &pcbSize, "uint", 8 + A_PtrSize * 2)
		; buf := Buffer(pcbSize)
		; DllCall("GetRawInputData", "ptr", LParam, "uint", 0x10000003, "ptr", buf, "ptr", &pcbSize, "uint", 8 + A_PtrSize * 2)
		/*
		DWORD	4 0		dwType
		DWORD	4 4		dwSize
		HANDLE	p 8		hDevice
		WPARAM	p 8+p	wParam
		-- keyboard:
		USHORT	4 8+2p	MakeCode
		USHORT	4 12+2p	Flags
		USHORT	4 16+2p	Reserved
		USHORT	4 20+2p	VKey
		UINT	4 24+2p	Message
		ULONG	8 28+2p	ExtraInformation
		*/
		; MsgBox("VKey:" NumGet(buf, 20 + A_PtrSize * 2, "ushort"))
		; return 0
	}
}

global window := Gui(, "HID Tester")
ctl := HIDControl(0x258a, 0x002f)
ctl.Register(0x258a, 0x002f)
OnMessage(WM_INPUT, ctl.HANDLE_WM_INPUT)
; ctl.report()

; event := window.Add("Text", , "No events yet.")
window.Show("w300 h300")
list := window.Add("ListView", "r15", ["Type", "VID", "PID"])
list.ModifyCol()
for device in ctl.devices {
	if device.type == RIM_TYPEHID {
		list.Add(, "HID", Format("0x{1:04x}", device.vid), Format("0x{1:04x}", device.pid))
	} else {
		list.Add(,
			device.type == RIM_TYPEMOUSE
				? "Mouse"
				: device.type == RIM_TYPEKEYBOARD
					? "Keyboard"
					: device.type == RIM_TYPEHID
						? "HID"
						: "Unknown"
		)
	}
}

Persistent