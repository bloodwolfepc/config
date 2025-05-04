local wezterm = require("wezterm")
wezterm.add_to_config_reload_watch_list(wezterm.config_dir)
local function stylix_wrapped_config()
    return {}

end
local stylix_base_config = wezterm.config_builder()
local stylix_user_config = stylix_wrapped_config()
stylix_base_config = {
    color_scheme = "stylix",
    font = wezterm.font_with_fallback {
        "Unscii",
        "Noto Monochrome Emoji",
    },
    font_size = 12,
    window_background_opacity = 1.000000,
    window_frame = {
        active_titlebar_bg = "#545454",
        active_titlebar_fg = "#a8a8a8",
        active_titlebar_border_bottom = "#545454",
        border_left_color = "#1c1c1c",
        border_right_color = "#1c1c1c",
        border_bottom_color = "#1c1c1c",
        border_top_color = "#1c1c1c",
        button_bg = "#1c1c1c",
        button_fg = "#a8a8a8",
        button_hover_bg = "#a8a8a8",
        button_hover_fg = "#545454",
        inactive_titlebar_bg = "#1c1c1c",
        inactive_titlebar_fg = "#a8a8a8",
        inactive_titlebar_border_bottom = "#545454",
    },
    colors = {
      tab_bar = {
        background = "#1c1c1c",
        inactive_tab_edge = "#1c1c1c",
        active_tab = {
          bg_color = "#000000",
          fg_color = "#a8a8a8",
        },
        inactive_tab = {
          bg_color = "#545454",
          fg_color = "#a8a8a8",
        },
        inactive_tab_hover = {
          bg_color = "#a8a8a8",
          fg_color = "#000000",
        },
        new_tab = {
          bg_color = "#545454",
          fg_color = "#a8a8a8",
        },
        new_tab_hover = {
          bg_color = "#a8a8a8",
          fg_color = "#000000",
        },
      },
    },
    command_palette_bg_color = "#1c1c1c",
    command_palette_fg_color = "#a8a8a8",
    command_palette_font_size = 12,
}
for key, value in pairs(stylix_user_config) do
    stylix_base_config[key] = value
end
return stylix_base_config
