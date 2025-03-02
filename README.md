# Strategem Control Panel
This is an AutoHotkey (v2) script I wrote for HELLDIVERS 2. I do not own the rights to any names, artwork, or ideas from Arrowhead Studios.

This program is written for users who have a mouse with 8 buttons. Currently, mouse input does not work as I am trying to reimplement AHKHID for ahkv2. Use the numpad instead. Some tweaks will be necessary to make it work with other models of mouse.

## Downloading
1. Clone or download this repository. Make sure you included submodules.
2. Generate icons:
	1. `npm install` or `bun install`
	2. `npm iconGenerator.js` or `bun iconGenerator.js`
3. (Optionally) add a short bindGen.wav and bindGenEnd.wav to be played while generating bindings (trust me, this step is very critical)

## Usage

### Bindings
This menu shows which mouse buttons are bound to each action. To change a binding, click the binding. Then, double-click a strategem in the Strategem Selector.

### Strategem Selector
This menu lists every registered strategem, along with 3 extras which are only valid in the bindings menu:
- `Unbound`: This binding does nothing.
- `Default`: If another binding is vertically adjacent to this binding, its action will occur instead.
- `All`: Calls down all support weapons (excluding EAT) and backpacks.

### Loadout: Save/Load
This menu can be used to save, load, or remove loadouts. Each loadout tracks strategem selections and bindings.

### Loadout: Strategems
This menu allows selection of 4 strategems. To select a strategem, click a slot. Then, double-click a strategem in the Strategem Selector. This will automatically advance your selection to the next box. If you selected a strategem which is already present, it will swap places.

Press `Generate Bindings` to automatically convert your selection of strategems to a set of bindings, following rules set in `config.json`. If `bindGen.wav` is present, it will play until the process finishes, at which point `bindGenEnd.wav` will play if present. The following colors may appear in your strategem selection:
- Yellow: Busy searching for a binding number
- Red: Not bound (most often because this strategem is unset)
- Green: Successfully bound
- Blue: Bound to an empty space because the space it would normally be in is already taken.