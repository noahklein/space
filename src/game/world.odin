package game

import "core:fmt"
import rl "vendor:raylib"
import "../entity"

World :: struct {
    state: WorldState,
    timescale: f32,
    screen: rl.Vector2,
    camera: rl.Camera2D,

    entities: [dynamic]entity.Entity,
    physics: Physics,
    stats: EngineStats,
}

WorldState :: enum {
    Space
}

EngineStats :: struct {
    frames: u32,
}

Input :: enum u8 {
    Up, Down,
    Left, Right,
    Slower, Faster,
}

get_input :: proc(w: World) -> (input: bit_set[Input]) {
         if rl.IsKeyDown(.UP)    || rl.IsKeyDown(.W) do input += {.Up}
    else if rl.IsKeyDown(.DOWN)  || rl.IsKeyDown(.S) do input += {.Down}
         if rl.IsKeyDown(.LEFT)  || rl.IsKeyDown(.A) do input += {.Left}
    else if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) do input += {.Right}

    // if rl.IsKeyPressed(.SPACE) do input += {.Pause} if w.timescale != 0 else {.Play}
         if rl.IsKeyPressed(.RIGHT_BRACKET) do input += {.Faster}
    else if rl.IsKeyPressed(.LEFT_BRACKET)  do input += {.Slower}

    return input
}

init :: proc() -> (w: World) {
    w.screen = {1600, 900}
    w.camera = rl.Camera2D{ zoom = 1, offset = w.screen / 2}
    reserve(&w.entities, 128)
    append(&w.entities, entity.Entity{
        scale = 5, texture = entity.Circle{rl.WHITE},
        rigidbody = {mass = 1, force = {1, 0.2}}
    })

    append(&w.entities, entity.Entity{
        pos = {-20, -20},
        scale = 5, texture = entity.Circle{rl.RED},
        rigidbody = {mass = 2, force = {0, 0}}
    })
    return w
}

deinit :: proc(w: ^World) {
    delete(w.entities)
}

update :: proc(w: ^World, input: bit_set[Input], dt: f32) {
    if .Faster in input {
        w.timescale += FIXED_DT
    } else if .Slower in input {
        w.timescale -= FIXED_DT
        w.timescale = max(0, w.timescale)
    }
}

draw :: proc(w: World) {
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(rl.BLACK)

    rl.BeginMode2D(w.camera)
    defer rl.EndMode2D()

    for ent in w.entities {
        switch tex in ent.texture {
        case entity.Circle:
            rl.DrawCircleV(ent.pos, ent.scale, tex.color)
        case rl.Texture2D:
            panic("Textures not yet supported")
        }
    }
}

draw_gui :: proc(w: ^World) {
    FONT :: 10
    {
    // Top-left panel
    X :: 10
    Y :: 10
    TITLE :: 18
    rl.GuiPanel({0, 0, 200, 10 * Y}, fmt.ctprintf("%d FPS", rl.GetFPS()))
    // rl.GuiSliderBar({X, 1 * Y + TITLE, 100, Y * 2}, "", "Timestep", &w.timescale, 0, 50)
    rl.GuiSlider({X, 1 * Y + TITLE, 100, Y}, "", "Timescale", &w.timescale, 0, 50)
    }

}

draw_text :: proc(x, y, font_size: i32, format: string, args: ..any) {
    str := fmt.ctprintf(format, ..args)
    rl.DrawText(str, x, y, font_size, rl.DARKBLUE)
}
