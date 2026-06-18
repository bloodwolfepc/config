---@diagnostic disable: undefined-global
local util = require("util")
local key_workspace_maps = {
	["a"] = 1,
	["s"] = 2,
	["d"] = 3,
	["f"] = 4,
	["g"] = 5,
	["h"] = 6,
	["j"] = 7,
	["k"] = 8,
	["l"] = 9,
	["semicolon"] = 10,
}

hl.bind("ALT + SHIFT + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("ALT + SHIFT + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.define_submap("INSERT", function()
	hl.bind("super_l", hl.dsp.submap("NORMAL"))
end)

hl.define_submap("NORMAL", function()
	util.mkNavigationKeymap("h", "l")
	util.mkNavigationKeymap("j", "d")
	util.mkNavigationKeymap("k", "u")
	util.mkNavigationKeymap("l", "r")

	hl.bind("i", hl.dsp.submap("INSERT"))
	hl.bind("f", hl.dsp.submap("FOCUS_WORKSPACE"))
	hl.bind("g", hl.dsp.submap("MOVE_ACTIVE_WINDOW_TO_WORKSPACE"))
	hl.bind("r", hl.dsp.submap("RESIZE_ACTIVE_WINDOW"))
	hl.bind("t", hl.dsp.submap("SWAP_ACTIVE_WINDOW"))
	hl.bind("period", hl.dsp.submap("MOVE_ACTIVE_WINDOW"))

	hl.bind("m", hl.dsp.submap("FOCUS_MONITOR"))
	hl.bind("comma", hl.dsp.submap("MOVE_WORKSPACE_TO_MONITOR"))

	hl.bind("s", hl.dsp.submap("SCREENSHOT"))
	hl.bind("space", hl.dsp.submap("MENU"))
	hl.bind("u", hl.dsp.submap("UTIL"))

	util.mkNormalBinds("v", function()
		hl.dispatch(hl.dsp.window.fullscreen({ window = activewindow }))
	end)
	util.mkNormalBinds("backslash", function()
		hl.dispatch(hl.dsp.window.float({ window = activewindow }))
	end)
	util.mkNormalBinds("x", function()
		hl.dispatch(hl.dsp.window.kill({ window = activewindow }))
	end)
	util.mkNormalBinds("c", function()
		hl.dispatch(hl.dsp.window.center({ window = activewindow }))
	end)

	-- Not working:
	-- hl.bind("mouse:272", hl.dsp.window.drag(), { mouse = true })
	-- hl.bind("mouse:273", hl.dsp.window.resize(), { mouse = true })
end)

util.mkNormalSubmap("FOCUS_WORKSPACE", function()
	for key, val in pairs(key_workspace_maps) do
		hl.bind(key, hl.dsp.focus({ workspace = val }))
	end
end)

util.mkNormalSubmap("MOVE_ACTIVE_WINDOW_TO_WORKSPACE", function()
	for key, val in pairs(key_workspace_maps) do
		hl.bind(key, hl.dsp.window.move({ workspace = val .. " silent", window = activewindow }))
	end
end)

util.mkNormalSubmap("RESIZE_ACTIVE_WINDOW", function()
	hl.bind("h", hl.dsp.window.resize({ x = -100, y = 0, relative = true }), { repeating = true })
	hl.bind("j", hl.dsp.window.resize({ x = 0, y = -100, relative = true }), { repeating = true })
	hl.bind("k", hl.dsp.window.resize({ x = 0, y = 100, relative = true }), { repeating = true })
	hl.bind("l", hl.dsp.window.resize({ x = 100, y = 0, relative = true }), { repeating = true })
end, { drop_submap = false })

util.mkNormalSubmap("SWAP_ACTIVE_WINDOW", function()
	hl.bind("h", hl.dsp.window.swap({ direction = "l" }))
	hl.bind("j", hl.dsp.window.swap({ direction = "d" }))
	hl.bind("k", hl.dsp.window.swap({ direction = "u" }))
	hl.bind("l", hl.dsp.window.swap({ direction = "r" }))
end)

util.mkNormalSubmap("MOVE_ACTIVE_WINDOW", function()
	hl.bind("h", hl.dsp.window.move({ direction = "l" }))
	hl.bind("j", hl.dsp.window.move({ direction = "d" }))
	hl.bind("k", hl.dsp.window.move({ direction = "u" }))
	hl.bind("l", hl.dsp.window.move({ direction = "r" }))
end)

util.mkNormalSubmap("SCREENSHOT", function()
	hl.bind("s", hl.dsp.exec_cmd("grimblast copy area"))
end)

util.mkNormalSubmap("MENU", function()
	hl.bind("space", hl.dsp.exec_cmd("rofi -show run"))
	hl.bind("f", hl.dsp.exec_cmd("cliphist list | rofi -dmenu | cliphist decode | wl-copy"))
	hl.bind("c", hl.dsp.exec_cmd("rofi -modi calc -show calc -no-show-match -no-sort"))
	hl.bind("e", hl.dsp.exec_cmd("rofi -modi emoji -show emoji"))
	hl.bind("t", hl.dsp.exec_cmd("rofi -modi top -show -top"))
	hl.bind("w", hl.dsp.exec_cmd("rofi -modi window -show window"))
	hl.bind("g", hl.dsp.exec_cmd("rofi -modi games -show games"))
	hl.bind("x", hl.dsp.exec_cmd("rofi -modi power-menu:rofi-power-menu -show power-menu"))
	hl.bind("n", hl.dsp.exec_cmd("rofi-network-maager"))
	hl.bind("b", hl.dsp.exec_cmd("rofi-bluetooth"))
	hl.bind("s", hl.dsp.exec_cmd("rofi-systemd"))
	hl.bind("p", hl.dsp.exec_cmd("rofi-pass"))
	hl.bind("bracketright", hl.dsp.exec_cmd("rofi-pulse-select sink"))
	hl.bind("bracketleft", hl.dsp.exec_cmd("rofi-pulse-select source"))
end)

util.mkNormalSubmap("UTIL", function()
	hl.bind("m", hl.dsp.exec_cmd("wayscriber --daemon-toggle"))
	hl.bind("t", hl.dsp.exec_cmd("toggle-touchpad"))
	hl.bind("f", hl.dsp.exec_cmd("wl-freeze -c \"hyprctl activewindow -j | jq '.pid'\""))
	hl.bind("d", hl.dsp.exec_cmd("pypr toggle wezterm-drop"))
	hl.bind("e", hl.dsp.exec_cmd("pypr expose"))
	hl.bind("z", hl.dsp.exec_cmd("pypr zoom"))
	hl.bind("g", hl.dsp.exec_cmd("pypr fetch_client_menu"))
	hl.bind(
		"w",
		hl.dsp.exec_cmd(
			"systemctl --user is-active --quiet waybar.service && systemctl --user stop waybar.service || systemctl --user start waybar.service"
		)
	)
	--color, waybar toggle, dpms toggle, crosshair toggle
end)
