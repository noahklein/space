package ngui

import rl "vendor:raylib"

FONT :: 10
TEXT_COLOR :: rl.BLACK

SLIDER_WIDTH :: 16

state : NGui

NGui :: struct {
    want_mouse, want_keyboard: bool
}

update :: proc() {
    state.want_mouse = false
    state.want_keyboard = false
}

on_click :: proc() {
    state.want_mouse = true
}

slider :: proc(rect: rl.Rectangle, val: ^f32, $low, $high: f32, text: cstring) {
    #assert(low < high)
    pct := val^ / (high - low)

    mouse := rl.GetMousePosition()
    clicked := rl.IsMouseButtonPressed(.LEFT)

    slider_x := rect.x + pct * rect.width - SLIDER_WIDTH / 2 // Cursor should be in center of slider control
    // slider_x = clamp(slider_x)
    slider_rect := rl.Rectangle{slider_x, rect.y, SLIDER_WIDTH, rect.height}
    hovered := rl.CheckCollisionPointRec(mouse, rect)
    if hovered && rl.IsMouseButtonDown(.LEFT) {
        on_click()
        mouse_pct := (mouse.x - rect.x) / rect.width
        val^ = mouse_pct * (high - low)
    }

    rl.DrawRectangleRec({rect.x - SLIDER_WIDTH / 2, rect.y, rect.width + SLIDER_WIDTH / 2, rect.height}, rl.BLACK)
    rl.DrawRectangleRec(slider_rect, hovered ? rl.VIOLET : rl.BLUE)
    rl.DrawText(text, i32(rect.x + rect.width + SLIDER_WIDTH / 2), i32(rect.y), FONT, TEXT_COLOR)
}