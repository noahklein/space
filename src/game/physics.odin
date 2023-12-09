package game

import "core:math/linalg"
import rl "vendor:raylib"
import "../entity"

FIXED_DT :: 1.0 / 120.0
GRAVITY  :: 10

Physics :: struct {
    dt_acc: f32,
}

FUTURE_TIMESTEPS  :: 1500
FUTURE_STEPSIZE   :: 1.0 // In seconds

// Copy the world and predict the future.
Future :: struct {
    world: World, // We only care about entities and physics.
    paths: map[entity.ID]Circular,
    dt_acc: f32,
}

future: Future

physics_init :: proc(ents: entity.Storage) {
    future.world.entities = entity.storage_init(128)
    future.paths = make(map[entity.ID]Circular)

    // Copy entities to future world.
    for ent in ents.data {
        id := entity.create(&future.world.entities, ent)
        future.paths[id] = {}
    }

    acc := FUTURE_STEPSIZE * FUTURE_TIMESTEPS
    future_acc : f32
    timestep : int
    for acc >= FIXED_DT {
        acc -= FIXED_DT
        physics_subupdate(&future.world, FIXED_DT)

        future_acc += FIXED_DT
        if future_acc < FUTURE_STEPSIZE {
            continue
        }

        // Add a point to the future path.
        timestep += 1
        future_acc -= FUTURE_STEPSIZE
        future_update(ents)
        for ent, id in future.world.entities.data {
            id := entity.ID(id)
            circular, ok := &future.paths[id]
            if !ok {
                panic("entity missing from future.paths")
            }
            circular.points[timestep] = ent.pos
        }
    }
}

physics_deinit :: proc(p: ^Physics) {
    entity.storage_deinit(future.world.entities)
    delete(future.paths)
}

physics_update :: proc(w: ^World, dt: f32) {
    w.physics.dt_acc += dt
    for w.physics.dt_acc >= FIXED_DT {
        w.physics.dt_acc -= FIXED_DT
        physics_subupdate(w, FIXED_DT)
        physics_subupdate(&future.world, FIXED_DT)

        future.dt_acc += FIXED_DT
        if future.dt_acc >= FUTURE_STEPSIZE {
            future.dt_acc -= FUTURE_STEPSIZE
            future_update(w.entities)
        }
    }
}

physics_subupdate :: proc(w: ^World, dt: f32) {
    for &ent, id_a in w.entities.data {
        rb := &ent.rigidbody

        // Apply gravity from each body. F = GMm / r²
        for ent_b, id_b in w.entities.data do if id_a != id_b {
            rb_b := ent_b.rigidbody
            ab := ent_b.pos - ent.pos
            dist_squared := ab.x * ab.x + ab.y * ab.y

            f := GRAVITY * rb_b.mass * rb.mass / dist_squared
            acceleration := f / rb.mass
            rb.velocity += linalg.normalize(ab) * acceleration * dt
        }
    }

    for &ent in w.entities.data {
        ent.pos += ent.rigidbody.velocity * dt
    }
}

future_update :: proc(entities: entity.Storage) {
    for ent, id in future.world.entities.data {
        id := entity.ID(id)
        circular, ok := &future.paths[id]
        if !ok {
            panic("entity missing from future.paths")
        }
        circular_add(circular, ent.pos)
    }
}

// Circular buffer of 2D points.
Circular :: struct {
    start: int,
    points: [FUTURE_TIMESTEPS]rl.Vector2,
}

circular_add :: proc(c: ^Circular, point: rl.Vector2) {
    c.points[c.start] = point
    c.start = (c.start + 1) % len(c.points)
}