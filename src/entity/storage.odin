package entity

ID :: distinct int

Storage :: struct {
    data: [dynamic]Entity,
}

storage_init :: proc(size: int) -> (s: Storage) {
    reserve(&s.data, size)
    return s
}

storage_deinit :: proc(s: Storage) {
    delete(s.data)
}

size :: #force_inline proc(s: Storage) -> int { return len(s.data) }

create :: proc(s: ^Storage, e: Entity) -> ID {
    append(&s.data, e)
    return ID(len(s.data) - 1)
}

get :: proc(s: Storage, id: ID) -> (Entity, bool) {
    if id < 0 || id > ID(len(s.data)) {
        return {}, false
    }

    return s.data[id], true
}