package chip8

RAM_SIZE :: 4096
SCREEN_WIDTH :: 64
SCREEN_HEIGHT :: 32
NUM_REGISTERS :: 16
STACK_SIZE :: 16
NUM_KEYS :: 16
START_ADDR :: 0x200

Emulator :: struct {
	// Program counter
	pc:     u16,
	// Memory
	ram:    [RAM_SIZE]u8,
	// Screen
	screen: [SCREEN_WIDTH * SCREEN_HEIGHT]bool,
	// V register
	v_reg:  [NUM_REGISTERS]u8,
	// Index register
	i_reg:  u16,
	// Stack pointer
	sp:     u16,
	// Stack
	stack:  [STACK_SIZE]u16,
	// Keypad
	key:    [NUM_KEYS]bool,
	// Delay timer
	dt:     u8,
	// Sound timer
	st:     u8,
}

/*
Initialize the emulator.

Returns:
- The initialized emulator.
*/
emulator_init :: proc() -> Emulator {
	e := Emulator {
		pc = START_ADDR,
	}
	fontset_load_into_memory(&e)
	return e
}

/*
Reset the emulator to its initial state.

Inputs:
- e: The emulator.
*/
emulator_reset :: proc(e: ^Emulator) {
	e.pc = START_ADDR
	e.ram = [RAM_SIZE]u8{}
	e.screen = [SCREEN_WIDTH * SCREEN_HEIGHT]bool{}
	e.v_reg = [NUM_REGISTERS]u8{}
	e.i_reg = 0
	e.sp = 0
	e.stack = [STACK_SIZE]u16{}
	e.key = [NUM_KEYS]bool{}
	e.dt = 0
	e.st = 0
	fontset_load_into_memory(e)
}


/*
Load a ROM into the emulator's memory.

Inputs:
- e: The emulator.
- rom: The ROM to load.
*/
emulator_load_rom :: proc(e: ^Emulator, rom: []u8) {
	for b, i in rom {
		e.ram[START_ADDR + i] = b
	}
}

/*
Push a value onto the stack.

Inputs:
- e: The emulator.
*/
stack_push :: proc(e: ^Emulator, val: u16) {
	e.stack[e.sp] = val
	e.sp += 1
}

/*
Pop a value from the stack.

Inputs:
- e: The emulator.

Returns:
- The value popped from the stack.
*/
stack_pop :: proc(e: ^Emulator) -> u16 {
	e.sp -= 1
	return e.stack[e.sp]
}

/*
Ticks the delay and sound timers. 

Inputs:
- e: The emulator.

Returns:
- true if the sound timer should beep.
*/
timers_tick :: proc(e: ^Emulator) -> bool {
	beep := false

	if e.dt > 0 {
		e.dt -= 1
	}

	if e.st > 0 {
		if e.st == 1 {
			beep = true
		}
		e.st -= 1
	}

	return beep
}
