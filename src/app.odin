package app

import "core:log"
import "core:os"

import c8 "./lib/chip8"
import rl "vendor:raylib"

SCALE :: 15
WINDOW_WIDTH :: c8.SCREEN_WIDTH * SCALE
WINDOW_HEIGHT :: c8.SCREEN_HEIGHT * SCALE
TICKS_PER_CYCLE :: 10

run: bool
beep: rl.Sound
key_map: map[rl.KeyboardKey]u8
emu: c8.Emulator
rom: []byte

key_map_init :: proc() -> map[rl.KeyboardKey]u8 {
	km := make(map[rl.KeyboardKey]u8)
	km[rl.KeyboardKey.ONE] = 0x1
	km[rl.KeyboardKey.TWO] = 0x2
	km[rl.KeyboardKey.THREE] = 0x3
	km[rl.KeyboardKey.FOUR] = 0xC
	km[rl.KeyboardKey.Q] = 0x4
	km[rl.KeyboardKey.W] = 0x5
	km[rl.KeyboardKey.E] = 0x6
	km[rl.KeyboardKey.R] = 0xD
	km[rl.KeyboardKey.A] = 0x7
	km[rl.KeyboardKey.S] = 0x8
	km[rl.KeyboardKey.D] = 0x9
	km[rl.KeyboardKey.F] = 0xE
	km[rl.KeyboardKey.Z] = 0xA
	km[rl.KeyboardKey.X] = 0x0
	km[rl.KeyboardKey.C] = 0xB
	km[rl.KeyboardKey.V] = 0xF

	return km
}

init :: proc(rom_path: string) {
	run = true

	ok: bool
	rom, ok = _read_entire_file(rom_path)
	if !ok {
		log.errorf("Failed to load the file at %s", rom_path)
		os.exit(1)
	}

	key_map = key_map_init()

	emu = c8.emulator_init()
	c8.emulator_load_rom(&emu, rom)

	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Odin Chip-8 Emulator")
	rl.InitAudioDevice()

	beep = rl.LoadSound("sounds/beep.wav")

	rl.SetTargetFPS(60)
}

update :: proc() {
	for k, v in key_map {
		if rl.IsKeyDown(k) {
			c8.key_press(&emu, v, true)
		} else {
			c8.key_press(&emu, v, false)
		}
	}

	for _ in 0 ..< TICKS_PER_CYCLE {
		c8.cpu_tick(&emu)
	}
	if c8.timers_tick(&emu) {
		rl.PlaySound(beep)
	}

	draw_screen()
}

draw_screen :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.RAYWHITE)

	for pixel, i in emu.screen {
		if pixel {
			x := i32(i % c8.SCREEN_WIDTH)
			y := i32(i / c8.SCREEN_WIDTH)
			rl.DrawRectangle(x * SCALE, y * SCALE, SCALE, SCALE, rl.BLACK)
		}
	}

	rl.EndDrawing()
}

shutdown :: proc() {
	log.destroy_console_logger(context.logger)
	delete(key_map)
	delete(rom)
	rl.UnloadSound(beep)
	rl.CloseAudioDevice()
	rl.CloseWindow()
}

should_run :: proc() -> bool {
	when ODIN_OS != .JS {
		if rl.WindowShouldClose() {
			run = false
		}
	}

	return run
}
