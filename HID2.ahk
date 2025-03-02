; Register raw input devices
RegisterRawInputDevices()
{
    ; Initialize the RAWINPUTDEVICE structure for mouse
    rid := Buffer(16)
    NumPut("Ushort", 0, rid, 0x01) ; usUsagePage (Generic desktop controls)
    NumPut("Ushort", 2, rid, 0x02) ; usUsage (Mouse)
    NumPut("Uint", 0, rid, 0x04) ; dwFlags (No flags to exclude input or use legacy input)
    NumPut("Ptr", A_ScriptHwnd, rid, 0x08) ; hwndTarget (NULL to send input to the window with focus)

    if !DllCall("RegisterRawInputDevices", "Ptr", rid, "UInt", 1, "UInt", 16, "UInt")
    {
        MsgBox "Failed to register raw input devices"
        ExitApp
    }
}

; Set up the WM_INPUT message handler
OnMessage(0x00FF, HandleRawInput)

HandleRawInput(wParam, lParam, *)
{
    ; Get the size of the raw input data
    dwSize := 0
    DllCall("GetRawInputData", "Ptr", lParam, "UInt", 0x10000003, "Ptr", 0, "UIntP", dwSize, "UInt", 16)

    ; Allocate a buffer for the raw input data
    raw := Buffer(dwSize)
    
    ; Get the raw input data
    if (DllCall("GetRawInputData", "Ptr", lParam, "UInt", 0x10000003, "Ptr", raw, "UIntP", dwSize, "UInt", 16) != dwSize)
    {
        MsgBox "Failed to get raw input data"
        return
    }

    ; Process the raw input data
    rid := NumGet(raw, 0, "UInt") ; RAWINPUTHEADER.dwType
    if (rid == 0) ; RIM_TYPEMOUSE
    {
        ; Filter and handle mouse events here
        MsgBox "Mouse event detected from device " NumGet(raw, 8 + A_PtrSize, "Ptr")
    }
}

; Register the devices at script startup
RegisterRawInputDevices()

Persistent