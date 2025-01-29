package chip8

import "core:log"
import "core:math"
import "core:math/rand"

/*
Tick the CPU.

Inputs:
- e: The emulator.
*/
cpu_tick :: proc(e: ^Emulator) {
	op := cpu_fetch(e)
	cpu_execute(e, op)
}

/*
Fetch the next opcode.

Inputs:
- e: The emulator.

Returns:
- The opcode.
*/
cpu_fetch :: proc(e: ^Emulator) -> u16 {
	high := e.ram[e.pc]
	low := e.ram[e.pc + 1]

	op := (u16(high) << 8) | u16(low)
	e.pc += 2

	return op
}

/*
Execute an opcode instruction.

Inputs:
- e: The emulator.
- op: The opcode.
*/
cpu_execute :: proc(e: ^Emulator, op: u16) {
	x := (op & 0x0F00) >> 8
	y := (op & 0x00F0) >> 4

	switch op & 0xF000 {
	case 0x0000:
		switch op {
		case 0x00E0:
			e.screen = [SCREEN_WIDTH * SCREEN_HEIGHT]bool{}
		case 0x00EE:
			e.pc = stack_pop(e)
		}
	case 0x1000:
		e.pc = op & 0xFFF
	case 0x2000:
		stack_push(e, e.pc)
		e.pc = op & 0xFFF
	case 0x3000:
		if e.v_reg[x] == u8(op & 0xFF) {
			e.pc += 2
		}
	case 0x4000:
		if e.v_reg[x] != u8(op & 0xFF) {
			e.pc += 2
		}
	case 0x5000:
		if e.v_reg[x] == e.v_reg[y] {
			e.pc += 2
		}
	case 0x6000:
		e.v_reg[x] = u8(op & 0xFF)
	case 0x7000:
		e.v_reg[x] += u8(op & 0xFF)
	case 0x8000:
		switch op & 0xF {
		case 0x0:
			e.v_reg[x] = e.v_reg[y]
		case 0x1:
			e.v_reg[x] |= e.v_reg[y]
		case 0x2:
			e.v_reg[x] &= e.v_reg[y]
		case 0x3:
			e.v_reg[x] ~= e.v_reg[y]
		case 0x4:
			sum := u16(e.v_reg[x] + e.v_reg[y])

			e.v_reg[0xF] = 0
			if sum > 0xFF {
				e.v_reg[0xF] = 1
			}

			e.v_reg[x] = u8(sum & 0xFF)
		case 0x5:
			e.v_reg[0xF] = 0

			if e.v_reg[x] > e.v_reg[y] {
				e.v_reg[0xF] = 1
			}

			e.v_reg[x] -= e.v_reg[y]
		case 0x6:
			e.v_reg[0xF] = e.v_reg[x] & 0x1
			e.v_reg[x] >>= 1
		case 0x7:
			e.v_reg[0xF] = 0
			if e.v_reg[y] > e.v_reg[x] {
				e.v_reg[0xF] = 1
			}
			e.v_reg[x] = e.v_reg[y] - e.v_reg[x]
		case 0xE:
			e.v_reg[0xF] = e.v_reg[x] & 0x80
			e.v_reg[x] <<= 1
		}
	case 0x9000:
		if e.v_reg[x] != e.v_reg[y] {
			e.pc += 2
		}
	case 0xA000:
		e.i_reg = op & 0xFFF
	case 0xB000:
		e.pc = (op & 0xFFF) + u16(e.v_reg[0])
	case 0xC000:
		r := u8(math.floor(rand.float32() * 0xFF))
		e.v_reg[x] = r & u8(op & 0xFF)
	case 0xD000:
		width: u16 = 8
		height := op & 0xF
		e.v_reg[0xF] = 0

		for row in 0 ..< height {
			sprite := e.ram[e.i_reg + row]

			for col in 0 ..< width {
				if (sprite & (0x80 >> col)) != 0 {
					x_pos := (u16(e.v_reg[x]) + col) % SCREEN_WIDTH
					y_pos := (u16(e.v_reg[y]) + row) % SCREEN_HEIGHT

					idx := y_pos * SCREEN_WIDTH + x_pos

					if e.screen[idx] {
						e.v_reg[0xF] = 1
					}

					e.screen[idx] ~= true
				}
			}
		}
	case 0xE000:
		switch op & 0xFF {
		case 0x9E:
			if e.key[e.v_reg[x]] {
				e.pc += 2
			}
		case 0xA1:
			if !e.key[e.v_reg[x]] {
				e.pc += 2
			}
		}
	case 0xF000:
		switch op & 0xFF {
		case 0x07:
			e.v_reg[x] = e.dt
		case 0x0A:
			pressed := false
			for i in 0 ..< len(e.key) {
				if e.key[i] {
					e.v_reg[x] = u8(i)
					pressed = true
					break
				}
			}

			if !pressed {
				e.pc -= 2
			}
		case 0x15:
			e.dt = e.v_reg[x]
		case 0x18:
			e.st = e.v_reg[x]
		case 0x1E:
			e.i_reg += u16(e.v_reg[x])
		case 0x29:
			e.i_reg = u16(e.v_reg[x]) * 5
		case 0x33:
			e.ram[e.i_reg] = e.v_reg[x] / 100
			e.ram[e.i_reg + 1] = (e.v_reg[x] / 10) % 10
			e.ram[e.i_reg + 2] = e.v_reg[x] % 10
		case 0x55:
			for i in 0 ..< x + 1 {
				e.ram[e.i_reg + i] = e.v_reg[i]
			}
		case 0x65:
			for i in 0 ..< x + 1 {
				e.v_reg[i] = e.ram[e.i_reg + i]
			}
		}
	case:
		log.errorf("Unknown opcode %s", op)
	}
}
