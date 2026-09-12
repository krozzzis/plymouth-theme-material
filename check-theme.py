"""Exercise the theme using Plymouth's real script interpreter, without a daemon.

Usage: python3 check-theme.py /path/to/plymouth/lib/plymouth/script.so /path/to/theme
Only display geometry is stubbed; images, fonts, sprites and callbacks are real.
"""
import ctypes as C
import os
import subprocess
import sys

p = C.CDLL(sys.argv[1])
ptr = C.c_void_p


class Return(C.Structure):
    _fields_ = [("type", C.c_int), ("object", ptr)]


def bind(name, result, *args):
    fn = getattr(p, name)
    fn.restype = result
    fn.argtypes = args
    return fn


state = bind("script_state_new", ptr, ptr)(None)
parse = bind("script_parse_string", ptr, C.c_char_p, C.c_char_p)
execute = bind("script_execute", Return, ptr, ptr)
number = bind("script_obj_as_number", C.c_double, ptr)
for name in ("math", "string"):
    bind(f"script_lib_{name}_setup", ptr, ptr)(state)
bind("script_lib_image_setup", ptr, ptr, C.c_char_p)(state, sys.argv[2].encode())
displays = bind("ply_list_new", ptr)()
buffer = bind("ply_buffer_new", ptr)()
bind("script_lib_sprite_setup", ptr, ptr, ptr, ptr, C.c_char_p, C.c_uint32, C.c_uint32)(
    state, displays, buffer, b"Rubik 11", 0xFFFFFF, 0
)
bind("script_lib_plymouth_setup", ptr, ptr, C.c_int, C.c_int, ptr)(state, 0, 30, None)


def run(code):
    op = parse(code.encode(), b"theme-check")
    assert op, "Plymouth script parse failed"
    result = execute(state, op)
    assert result.type != 2, "Plymouth script execution failed"
    return result.object


def check(expression):
    assert number(run(f"return ({expression});")) == 1, expression


run("Window.GetWidth = fun() { return 1920; }; Window.GetHeight = fun() { return 1080; };"
    "Window.GetX = fun() { return 0; }; Window.GetY = fun() { return 0; };")
# The interpreter harness has no physical keyboard provider. Stub only its live
# Caps Lock query; production themes call Plymouth's native implementation.
run("Plymouth.GetCapslockState = fun() { return 0; };")
op = bind("script_parse_file", ptr, C.c_char_p)((sys.argv[2] + "/material.script").encode())
assert op, "Theme parse failed"
assert execute(state, op).type != 2
check("box.image.GetWidth() == 432 && entry.image.GetWidth() == 368")
check("title.image.GetWidth() > 100 && title.image.GetHeight() > 10")
check("box.sprite.GetOpacity() == 0")
run("progress_callback(1, 0.25);")
check("progress.track_sprite.GetOpacity() == 1 && progress.fill_sprite.GetOpacity() == 1 && progress.fill_sprite.GetImage().GetWidth() == progress.fill.GetWidth() / 4")
run("Plymouth.GetCapslockState = fun() { return 0; };")
run('display_password_callback("Enter passphrase for encrypted root:", 8);')
check("password_active == 1 && box.sprite.GetOpacity() == 1 && progress.track_sprite.GetOpacity() == 0")
check("box.sprite.GetX() + 216 == 960 && entry.sprite.GetX() + 184 == 960")
check("lock.sprite.GetX() + 28 == 960")
check("capslock.image.GetWidth() == 24 && capslock.image.GetHeight() == 24")
check("capslock.sprite.GetX() + 24 + 16 == entry.sprite.GetX() + 368")
check("capslock.sprite.GetOpacity() == 0")
run("Plymouth.GetCapslockState = fun() { return 1; }; layout();")
check("capslock.sprite.GetOpacity() == 1")
run("Plymouth.GetCapslockState = fun() { return 0; }; layout();")
check("capslock.sprite.GetOpacity() == 0")
check("bullet.sprites[0].GetX() + bullet.sprites[7].GetX() + 8 == 1920")
run("progress_callback(1, 0.6);")
check("progress.fill_sprite.GetOpacity() == 0")
run('display_password_callback("Retry password", 200); layout();')
check("bullet.sprites[19].GetOpacity() == 1 && !bullet.sprites[20]")
check("bullet.sprites[0].GetX() >= entry.x + 16")
check("bullet.sprites[19].GetX() + 8 <= entry.x + 368 - 16")
run('display_password_callback("Retry password", 0);')
check("bullet.sprites[0].GetOpacity() == 0 && box.sprite.GetOpacity() == 1")
run('display_message_callback("Wrong password"); hide_message_callback(""); display_message_callback("Try again");')
check("message.sprite.GetOpacity() == 1")
run('display_password_callback("' + 'long-device-name-' * 25 + '", 1);')
check("prompt.image.GetWidth() <= 368 && prompt.image.GetHeight() <= 40")
run("display_normal_callback(); progress_callback(1, 1.5);")
check("box.sprite.GetOpacity() == 0 && bullet.sprites[0].GetOpacity() == 0 && capslock.sprite.GetOpacity() == 0")
check("progress.track_sprite.GetOpacity() == 1 && progress.fill_sprite.GetOpacity() == 1 && progress.fill_sprite.GetImage().GetWidth() == progress.fill.GetWidth()")
if os.environ.get("MATERIAL_CUSTOM_LOGO") == "1":
    check("logo.image.GetWidth() == 32 && logo.image.GetHeight() == 32")
for width, height in [(640, 480), (1280, 720), (2560, 1440), (3840, 2160)]:
    run(f"Window.GetWidth = fun() {{ return {width}; }}; Window.GetHeight = fun() {{ return {height}; }};"
        'display_password_callback("Disk passphrase", 3); layout();')
    check(f"box.sprite.GetX() + 216 == {width / 2} && entry.sprite.GetX() + 184 == {width / 2}")
    check(f"box.y >= 0 && box.y + 288 <= {height}")
    if height == 480:
        check("logo.sprite.GetOpacity() == 0")
print("PASS: real Plymouth parser, images, text, alignment, retries, long passwords, messages, progress and 5 resolutions")

# Optional screenshots use the actual sprite images, positions and opacities.
# Plymouth composites the framebuffer; ImageMagick only encodes it as PNG.
if len(sys.argv) > 3:
    output = sys.argv[3]
    os.makedirs(output, exist_ok=True)
    native = bind("script_obj_as_native_of_class_name", ptr, ptr, C.c_char_p)
    new_buffer = bind("ply_pixel_buffer_new", ptr, C.c_ulong, C.c_ulong)
    fill = bind("ply_pixel_buffer_fill_with_hex_color", None, ptr, ptr, C.c_uint32)
    composite = bind("ply_pixel_buffer_fill_with_buffer_at_opacity", None, ptr, ptr, C.c_int, C.c_int, C.c_float)
    pixels = bind("ply_pixel_buffer_get_argb32_data", ptr, ptr)
    run("Window.GetWidth = fun() { return 1280; }; Window.GetHeight = fun() { return 720; };")

    def screenshot(name):
        canvas = new_buffer(1280, 720)
        fill(canvas, None, int(os.environ.get("MATERIAL_BACKGROUND", "#0f1413")[1:], 16))
        sprites = ["logo.sprite", "progress.track_sprite", "progress.fill_sprite", "box.sprite",
                   "lock.sprite", "title.sprite", "prompt.sprite", "entry.sprite", "capslock.sprite", "message.sprite"]
        sprites += [f"bullet.sprites[{i}]" for i in range(20)]
        for sprite in sprites:
            opacity = number(run(f"return {sprite}.GetOpacity();"))
            if opacity <= 0:
                continue
            source = native(run(f"return {sprite}.GetImage();"), b"image")
            if not source:
                continue
            x = int(number(run(f"return {sprite}.GetX();")))
            y = int(number(run(f"return {sprite}.GetY();")))
            composite(canvas, source, x, y, opacity)
        subprocess.run(["magick", "-size", "1280x720", "-depth", "8", "BGRA:-",
                        os.path.join(output, name + ".png")],
                       input=C.string_at(pixels(canvas), 1280 * 720 * 4), check=True)

    run('hide_message_callback(""); display_password_callback("Enter passphrase for encrypted root:", 8);')
    screenshot("unlock")
    run("Plymouth.GetCapslockState = fun() { return 1; }; layout();")
    screenshot("capslock")
    run("Plymouth.GetCapslockState = fun() { return 0; }; layout();")
    run('display_password_callback("Enter passphrase for encrypted root:", 0); display_message_callback("Incorrect passphrase. Please try again.");')
    screenshot("retry")
    run('hide_message_callback(""); display_normal_callback(); progress_callback(1, 0.62);')
    screenshot("boot")
    print("Rendered unlock, capslock, retry and boot screenshots using Plymouth's pixel compositor")
