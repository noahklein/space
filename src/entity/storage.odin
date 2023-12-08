package entity

ID :: distinct int

Storage :: struct {
    entities: [dynamic]Entity,
}

storage_init :: proc(size: int) -> (s: Storage) {
    reserve(&s.entities, size)
    return s
}

storage_deinit :: proc(s: Storage) {
    delete(s.entities)
}

size :: #force_inline proc(s: Storage) -> int { return len(s.entities) }

create :: proc(s: ^Storage, e: Entity) -> ID {
    append(&s.entities, e)
    return ID(len(s.entities) - 1)
}

get :: proc(s: Storage, id: ID) -> (Entity, bool) {
    if id < 0 || id > ID(len(s.entities)) {
        return {}, false
    }

    return s.entities[id], true
}

IterState :: ID

iter :: proc(s: Storage, offset: ^IterState) -> (^Entity, ID, bool) {
    defer offset^ += 1

    if offset^ <= ID(len(s.entities) - 1) {
        return &s.entities[offset^], offset^, true
    }

    return nil, -1, false
}