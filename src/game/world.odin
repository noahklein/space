package game

import "core:fmt"
import "core:math/linalg"
import rl "vendor:raylib"
import "../entity"

World :: struct {
    state: WorldState,
    timescale: f32,
    screen: rl.Vector2,
    camera: rl.Camera2D,
    cam_follow: entity.ID,

    entities: entity.Storage,
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
    Select,

    Slower, Faster, PredictFuture,
}

get_input :: proc(w: World) -> (input: bit_set[Input]) {
         if rl.IsKeyDown(.UP)    || rl.IsKeyDown(.W) do input += {.Up}
    else if rl.IsKeyDown(.DOWN)  || rl.IsKeyDown(.S) do input += {.Down}
         if rl.IsKeyDown(.LEFT)  || rl.IsKeyDown(.A) do input += {.Left}
    else if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) do input += {.Right}

    // if rl.IsKeyPressed(.SPACE) do input += {.Pause} if w.timescale != 0 else {.Play}
         if rl.IsKeyPressed(.PERIOD) do input += {.Faster}
    else if rl.IsKeyPressed(.COMMA)  do input += {.Slower}

    if rl.IsMouseButtonPressed(.LEFT) do input += {.Select}

    if rl.IsKeyPressed(.F) do input += {.PredictFuture}

    return input
}

init :: proc() -> (w: World) {
    w.screen = {1600, 900}
    w.camera = rl.Camera2D{ zoom = 1, offset = w.screen / 2}

    w.entities = entity.storage_init(128)
    entity.create(&w.entities, entity.Entity{
        pos = {0, 1000},
        scale = 500, texture = entity.Circle{rl.YELLOW},
        rigidbody = {mass = 50000, velocity = {0, 0}},
    })
    entity.create(&w.entities, entity.Entity{
        scale = 200, texture = entity.Circle{rl.BLUE},
        rigidbody = {mass = 20000, velocity = {20, 0}}
    })
    entity.create(&w.entities, entity.Entity{
        pos = {0, -400},
        scale = 10, texture = entity.Circle{rl.RED},
        rigidbody = {mass = 1000, velocity = {40, 0}}
    })

    return w
}

deinit :: proc(w: ^World) {
    entity.storage_deinit(w.entities)
}

update :: proc(w: ^World, input: bit_set[Input], dt: f32) {
    TIMESCALE_STEP :: 1
    if .Faster in input {
        w.timescale += TIMESCALE_STEP
    } else if .Slower in input {
        w.timescale -= TIMESCALE_STEP
        w.timescale = max(0, w.timescale)
    }

    SCROLL_SPEED :: 0.2
    w.camera.zoom += rl.GetMouseWheelMove() * SCROLL_SPEED
    w.camera.zoom = clamp(w.camera.zoom, 0.1, 50)

    CAM_SPEED :: 10
    cam_vel : rl.Vector2
    if .Up in input {
        cam_vel.y -= CAM_SPEED
    } else if .Down in input {
        cam_vel.y += CAM_SPEED
    }
    if .Left in input {
        cam_vel.x -= CAM_SPEED
    } else if .Right in input {
        cam_vel.x += CAM_SPEED
    }

    if cam_vel != {0, 0} {
        w.camera.target += cam_vel
        w.cam_follow = -1
    }

    cursor := rl.GetScreenToWorld2D(rl.GetMousePosition(), w.camera)
    // Click on entity to follow it.
    iter_state : entity.IterState
    if .Select in input do for ent, id in entity.iter(w.entities, &iter_state) {
        switch tex in ent.texture {
        case rl.Texture2D:
        case entity.Circle:
            if rl.CheckCollisionPointCircle(cursor, ent.pos, ent.scale) {
                w.cam_follow = id
            }
        }
    }

    // Smooth camera follow target.
    if follow, ok := entity.get(w.entities, w.cam_follow); ok {
        if linalg.distance(follow.pos, w.camera.target) > 2 {
            w.camera.target += (follow.pos - w.camera.target) * 0.9 * dt
        }
    }
}

draw :: proc(w: World) {
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(rl.BLACK)

    rl.BeginMode2D(w.camera)
    defer rl.EndMode2D()

    iter_state : entity.ID
    for ent in entity.iter(w.entities, &iter_state) {
        switch tex in ent.texture {
        case entity.Circle:
            rl.DrawCircleV(ent.pos, ent.scale, tex.color)
            when ODIN_DEBUG {
                start := ent.pos + ent.scale
                draw_text(start + {0,  0}, 10, "P=%.1f", ent.pos)
                draw_text(start + {0, 10}, 10, "V=%.1f", ent.rigidbody.velocity)
                draw_text(start + {0, 20}, 10, "M=%.0f", ent.rigidbody.mass)
            }
        case rl.Texture2D:
            panic("Textures not yet supported")
        }
    }

    iter_state = 0
    for ent in entity.iter(future.world.entities, &iter_state) {
        switch tex in ent.texture {
        case entity.Circle:
            rl.DrawCircleV(ent.pos, ent.scale, tex.color - {0, 0, 0, 150})
        case rl.Texture2D:
            panic("Textures not yet supported - future prediction")
        }
    }

    for ent_id, points in future.points {
        circ_iter : CircularIter
        prev : rl.Vector2
        init : bool
        for p in circular_iter(points, &circ_iter){
        // for p, i in points {
            if !init {
                init = true
                prev = p
                continue
            }

            ent := entity.get(future.world.entities, ent_id) or_continue
            rl.DrawLineV(prev, p, ent.texture.(entity.Circle).color)

            prev = p
        }
    }

    when ODIN_DEBUG {
        draw_gui2d(w)
    }
}

mouse_to_world :: proc(cam: rl.Camera2D) -> rl.Vector2 {
    return rl.GetScreenToWorld2D(rl.GetMousePosition(), cam)
}