package chip8

/*
Process a key press event.

Inputs:
- e: The emulator.
- key: The key.
- pressed: Whether the key is pressed.
*/
key_press :: proc(e: ^Emulator, key: u8, pressed: bool) {
	e.key[key] = pressed
}
