package entity

import rl "vendor:raylib"

Entity :: struct {
    using transform: Transform,
    texture: Texture,
    rigidbody: Rigidbody,
    flags: bit_set[EntityFlag],
}

Transform :: struct {
    pos: rl.Vector2,
    rot, scale: f32,
}

EntityFlag :: enum {
    Player,
}

Texture :: union{
    rl.Texture2D,
    Circle,
}

Circle :: struct {
    color: rl.Color
}

Rigidbody :: struct {
    mass: f32,
    velocity: rl.Vector2,
    flags: bit_set[RigidbodyFlag],
}

RigidbodyFlag :: enum { Disabled, }