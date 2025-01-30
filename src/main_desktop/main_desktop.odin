package main_desktop

import app ".."
import "core:flags"
import "core:fmt"
import "core:log"
import "core:mem"
import "core:os"
import "core:path/filepath"
import rl "vendor:raylib"

_ :: mem
_ :: fmt

LOG_LEVEL :: log.Level.Debug when ODIN_DEBUG else log.Level.Info

Options :: struct {
	rom: string `args:"required,pos=0" usage:"The ROM file."`,
}

parse_and_validate_options :: proc(args: []string) -> Options {
	opt: Options
	style: flags.Parsing_Style = .Unix
	flags.parse_or_exit(&opt, args, style)

	return opt
}

main :: proc() {
	when ODIN_DEBUG {
		rl.SetTraceLogLevel(.DEBUG)

		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	} else {
		rl.SetTraceLogLevel(.ERROR)
	}

	exe_path := os.args[0]
	exe_dir := filepath.dir(string(exe_path), context.temp_allocator)
	os.set_current_directory(exe_dir)

	context.logger = log.create_console_logger()
	context.logger.lowest_level = LOG_LEVEL

	opt := parse_and_validate_options(os.args)
	log.debugf("%#v", opt)

	app.init(opt.rom)

	for app.should_run() {
		app.update()
	}

	app.shutdown()
}
