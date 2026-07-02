---@diagnostic disable: undefined-global
hl.window_rule({
	match = {
		class = "^(ueberzugpp.*)$",
	},
	float = true,
	no_anim = true,
	border_size = 0,
	no_focus = true,
	no_follow_mouse = true,
	no_blur = true,
})

hl.window_rule({
	match = {
		class = "wezterm-drop",
	},
	border_size = 0,
	border_color = "rgba(00000000)",
	float = true,
	move = { "window_w * 0.4", "(monitor_h / 2) + 17" },
	size = { "monitor_w * 0.5", "monitor_h * 0.5" },
})

hl.window_rule({
	match = {
		class = "src-wezterm",
	},
	workspace = 4,
})

hl.window_rule({
	match = {
		initial_class = "^([Ss]potify)$",
	},
	workspace = "2 silent",
})

hl.window_rule({
	match = {
		initial_class = "^([Vv]esktop)$",
	},
	workspace = "3 silent",
})

hl.window_rule({
	match = {
		initial_class = "^([Ll]egcord)$",
	},
	workspace = "3 silent",
})

hl.window_rule({
	match = {
		initial_class = "^([Ss]team)$",
	},
	workspace = "6 silent",
	border_color = "rgb(ff00ff)",
})
hl.window_rule({
	match = {
		initial_class = "^([Ff]riends [Ll]ist)$",
	},
	workspace = "6 silent",
})

hl.window_rule({
	match = {
		initial_class = "^steam_app_[0-9]+$",
	},
	workspace = "5 silent",
	immediate = true,
})
hl.window_rule({
	match = {
		initial_class = "gamescope",
	},
	workspace = "5 silent",
	immediate = true,
})
hl.window_rule({
	match = {
		initial_class = "tf_linux64",
	},
	workspace = "5 silent",
	immediate = true,
})
hl.window_rule({
	match = {
		initial_class = "^([Cc]s2)$",
	},
	workspace = "5 silent",
	immediate = true,
})
hl.window_rule({
	match = {
		initial_class = "org.vinegarhq.Sober",
	},
	workspace = "5 silent",
	immediate = true,
})

-- FIXES: Draggables in ardour
hl.window_rule({
	match = {
		xwayland = 1,
	},
	no_initial_focus = true,
})
