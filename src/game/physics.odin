package game

import "core:math/linalg"
import rl "vendor:raylib"
import "../entity"

Physics :: struct {
    dt_acc: f32,
}

FIXED_DT :: 1.0 / 120.0
GRAVITY  :: 10

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
    iter_a: entity.IterState
    for ent, id_a in entity.iter(w.entities, &iter_a) {
        rb := &ent.rigidbody

        // Apply gravity from each body. F = GMm / r²
        iter_b : entity.IterState
        for ent_b, id_b in entity.iter(w.entities, &iter_b) do if id_a != id_b {
            rb_b := ent_b.rigidbody
            ab := ent_b.pos - ent.pos
            dist_squared := ab.x * ab.x + ab.y * ab.y

            f := GRAVITY * rb_b.mass * rb.mass / dist_squared
            acceleration := f / rb.mass
            rb.velocity += linalg.normalize(ab) * acceleration * dt
        }
    }

    iter_a = 0 // Reuse iterator
    for ent in entity.iter(w.entities, &iter_a) {
        ent.pos += ent.rigidbody.velocity * dt
    }
}