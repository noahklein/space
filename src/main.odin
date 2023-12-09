package main

import "core:fmt"
import "core:mem"
import rl "vendor:raylib"

import "game"

main :: proc() {
    when ODIN_DEBUG {
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
    }
    defer free_all(context.temp_allocator)

    world := game.init()
    defer game.deinit(&world)

    rl.SetTraceLogLevel(.ALL if ODIN_DEBUG else .WARNING)
    rl.InitWindow(i32(world.screen.x), i32(world.screen.y), "Space")
    defer rl.CloseWindow()

    game.physics_init(world.entities)
    defer game.physics_deinit(&world.physics)

    rl.SetTargetFPS(90)
    for !rl.WindowShouldClose() {
        dt := rl.GetFrameTime() * world.timescale
        world.stats.frames += 1

        input := game.get_input(world)
        game.physics_update(&world, dt)
        game.update(&world, input, dt)
        game.draw(world)

        when ODIN_DEBUG {
            game.update_gui(&world)
            game.draw_gui(&world)
        }
    }
}