package game

import "core:fmt"
import "core:math/linalg"
import rl "vendor:raylib"

import "../entity"
import "../ngui"

gui : GuiState

FONT :: 10
SCALE_TO_M :: 100

GuiState :: struct {
    mode: GuiMode,
    prev_mouse: rl.Vector2,
    ent: entity.Entity, // Preview in gui before creating.
}

GuiMode :: enum {
    None,
    SpawnMass,
    SpawnVel,
}

update_gui :: proc(w: ^World) {
    if rl.IsMouseButtonPressed(.RIGHT) {
        gui.mode = .None
        gui.ent = {}
    }

    should_spawn := rl.IsKeyPressed(.Q)

    switch gui.mode {
    case .None:
        if should_spawn {
            gui.mode = .SpawnMass
            gui.ent.pos = mouse_to_world(w.camera)
            gui.ent.texture = entity.Circle{ rl.GREEN }
        }
    case .SpawnMass:
        gui.ent.scale = linalg.distance(mouse_to_world(w.camera), gui.ent.pos)
        gui.ent.rigidbody.mass = gui.ent.scale * SCALE_TO_M
        if should_spawn {
            gui.mode = .SpawnVel
        }

    case .SpawnVel:
        target := mouse_to_world(w.camera)
        gui.ent.rigidbody.velocity = 0.1 * (target - gui.ent.pos)
        if should_spawn {
            id := entity.create(&w.entities, gui.ent)
            entity.create(&future.world.entities, gui.ent)
            physics_deinit(&w.physics)
            physics_init(w.entities)

            gui.mode = .None
            gui.ent = {}
        }
    }

    ngui.update()
}

draw_gui :: proc(w: ^World) {
    {
    // Top-left panel
    X :: 10
    Y :: 10
    TITLE :: 18
    rl.GuiPanel({0, 0, 200, 10 * Y}, fmt.ctprintf("%d FPS", rl.GetFPS()))
    ngui.slider({X, 1 * Y + TITLE, 100, Y}, &w.timescale, 0, 100, fmt.ctprintf("Timescale: %v", w.timescale))
    }
}

draw_gui2d :: proc(w: World) {
    if circle, ok := gui.ent.texture.(entity.Circle); ok {
        rl.DrawCircleV(gui.ent.pos, gui.ent.scale, circle.color)
    }

    switch gui.mode {
    case .None:
    case .SpawnMass:
        text_white(gui.ent.pos, 3 * FONT, "M=%v", gui.ent.rigidbody.mass)
    case .SpawnVel:
        target := mouse_to_world(w.camera)
        rl.DrawLineV(gui.ent.pos, target, rl.WHITE)
        text_white(gui.ent.pos, 3 * FONT, "V0=%v", gui.ent.rigidbody.velocity)
    }
}

text_white :: proc(pos: rl.Vector2, font_size: i32, format: string, args: ..any) {
    x, y := i32(pos.x), i32(pos.y)
    str := fmt.ctprintf(format, ..args)
    rl.DrawText(str, x, y, font_size, rl.WHITE)
}

text_black :: proc(pos: rl.Vector2, font_size: i32, format: string, args: ..any) {
    x, y := i32(pos.x), i32(pos.y)
    str := fmt.ctprintf(format, ..args)
    rl.DrawText(str, x, y, font_size, rl.BLACK)
}