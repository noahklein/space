package game

import "core:math/linalg"
import rl "vendor:raylib"
import "../entity"

FIXED_DT :: 1.0 / 120.0
GRAVITY  :: 10

Physics :: struct {
    dt_acc: f32,
}

FUTURE_TIMESTEPS :: 1000
FUTURE_STEPSIZE  :: 1.0 // In seconds

// Copy the world and predict the future.
Future :: struct {
    world: World, // We only care about entities and physics.
    points: map[entity.ID]Circular,
    dt_acc: f32,
}

future: Future

physics_init :: proc(w: ^World) {
    future.world.entities = entity.storage_init(128)
    future.points = make(map[entity.ID]Circular)

    iter: entity.IterState
    for ent in entity.iter(w.entities, &iter) {
        // Copy bodies to future world.
        id := entity.create(&future.world.entities, ent^)
        future.points[id] = {}
    }

    for timestep in 0..<FUTURE_TIMESTEPS {
        physics_subupdate(&future.world, 1)
        future_update(w.entities)

        iter = 0
        for ent, id in entity.iter(future.world.entities, &iter) {
            circular, ok := &future.points[id]
            if !ok {
                panic("entity missing from future points")
            }
            circular.points[timestep] = ent.pos
        }
    }
}

physics_deinit :: proc(p: ^Physics) {
    entity.storage_deinit(future.world.entities)
    delete(future.points)
}

physics_update :: proc(w: ^World, dt: f32) {
    w.physics.dt_acc += dt
    for w.physics.dt_acc >= FIXED_DT {
        w.physics.dt_acc -= FIXED_DT
        physics_subupdate(w, FIXED_DT)
    }

    // Future update
    future.dt_acc += dt
    for future.dt_acc >= FUTURE_STEPSIZE {
        future.dt_acc -= FUTURE_STEPSIZE
        physics_subupdate(&future.world, FUTURE_STEPSIZE)
        future_update(w.entities)
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

future_update :: proc(entities: entity.Storage) {
    iter : entity.IterState
    for ent, id in entity.iter(future.world.entities, &iter) {
        circular, ok := &future.points[id]
        if !ok {
            panic("entity missing from future points")
        }
        circular_add(circular, ent.pos)
        circular.points[circular.start] = ent.pos
    }

    iter = 0
    for ent, id in entity.iter(entities, &iter) {
        circular, ok := &future.points[id]
        if !ok {
            panic("entity missing from future points")
        }
        circular.points[circular.start] = ent.pos
    }
}

// Circular buffer of 2D points.
Circular :: struct {
    start: int,
    points: [FUTURE_TIMESTEPS]rl.Vector2,
}

CircularIter :: struct {
    curr: int,
    init: bool
}

circular_add :: proc(c: ^Circular, point: rl.Vector2) {
    c.points[c.start] = point
    c.start = (c.start + 1) % len(c.points)
}

circular_iter :: proc(c: Circular, state: ^CircularIter) -> (rl.Vector2, bool) {
    defer state.curr = (state.curr + 1) % len(c.points)

    if !state.init {
        state.init = true
        state.curr = c.start

        return c.points[state.curr], true
    }

    if state.curr == c.start {
        return {}, false
    }

    return c.points[state.curr], true
}