local wezterm = require("wezterm")
local config = wezterm.config_builder()
local config1 = {
	enable_tab_bar = false,
	enable_scroll_bar = false,
	window_close_confirmation = "NeverPrompt",
	exit_behavior = "Close",
	exit_behavior_messaging = "None",
	window_decorations = "NONE",
	enable_kitty_keyboard = true, -- FIXES: https://github.com/wezterm/wezterm/issues/6846
	window_padding = {
		left = 0,
		right = 0,
		top = 0,
		bottom = 0,
	},

	font_size = 24,
	color_scheme = "thwump (terminal.sexy)",
	-- colors = {},
	window_background_opacity = 0,
	text_background_opacity = 1,
	default_prog = { "/home/bloodwolfe/.nix-profile/bin/zsh" },
	launch_menu = {
		{
			label = "Bash",
			args = { "bash", "-l" },
		},
	},

	font = wezterm.font_with_fallback({ "helloworld", "Migu 2M", "Symbols Nerd Font Mono" }),
	--"Ark Pixel 16px P ja"
}
for key, val in pairs(config1) do
	config[key] = val
end

return config
