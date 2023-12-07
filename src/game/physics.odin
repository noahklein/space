package game

import "core:math/linalg"
import rl "vendor:raylib"
import "../entity"

Physics :: struct {
    dt_acc: f32,
}

FIXED_DT :: 1.0 / 120.0
GRAVITY  :: 0.000000001

physics_init :: proc(p: ^Physics) {
}

physics_deinit :: proc(p: ^Physics) {
}

physics_update :: proc(w: ^World, dt: f32) {
    w.physics.dt_acc += dt
    for w.physics.dt_acc >= FIXED_DT {
        w.physics.dt_acc -= FIXED_DT
        physics_subupdate(w, FIXED_DT)
    }
}

physics_subupdate :: proc(w: ^World, dt: f32) {
    for &ent in w.entities {
        rb := &ent.rigidbody

        for ent_b in w.entities {
            rb_b := ent_b.rigidbody
            ab := ent_b.pos - ent.pos
            dist_squared := ab.x * ab.x + ab.y * ab.y

            f := GRAVITY * rb_b.mass * rb.mass / dist_squared
            acceleration := f / rb.mass
            rb.velocity += linalg.normalize(ab) * acceleration * dt
        }
    }

    for &ent in w.entities {
        ent.pos += ent.rigidbody.velocity * dt
    }
}