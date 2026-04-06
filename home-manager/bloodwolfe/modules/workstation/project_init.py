from gi.repository import Gimp, Gegl

def create_project(xcf_path):
    image = Gimp.Image.new(1920, 1080, Gimp.ImageBaseType.RGB)

    bg = Gimp.Layer.new(
        image,
        "Background",
        1920,
        1080,
        Gimp.ImageType.RGB_IMAGE,
        100,
        Gimp.LayerMode.NORMAL
    )
    image.insert_layer(bg, None, 0)

    Gimp.context_set_background(Gegl.Color.new("rgb(0.5,0.5,0.5)"))
    bg.fill(Gimp.FillType.BACKGROUND)

    fg = Gimp.Layer.new(
        image,
        "Layer 1",
        1920,
        1080,
        Gimp.ImageType.RGBA_IMAGE,
        100,
        Gimp.LayerMode.NORMAL
    )
    image.insert_layer(fg, None, -1)

    Gimp.context_set_foreground(Gegl.Color.new("white"))

    brush = Gimp.Brush.get_by_name("Circle (05)")
    if brush:
        Gimp.context_set_brush(brush)

    Gimp.context_set_paint_method("gimp-pencil")

    Gimp.file_save(
        Gimp.RunMode.NONINTERACTIVE,
        image,
        fg,
        xcf_path,
        xcf_path
    )

    image.delete()
