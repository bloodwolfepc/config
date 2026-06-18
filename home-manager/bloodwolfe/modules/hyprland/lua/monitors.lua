---@diagnostic disable: undefined-global
local util = require("util")
local mon0 = "desc:LG Electronics LG ULTRAGEAR 510RMLM9B112"
local monl1 = "desc:BOE 0x0A1D"
hl.monitor({
	output = mon0,
	mode = "2560x1440@240",
	position = "0x0",
	scale = 1,
})

hl.monitor({
	output = monl1,
	mode = "2560x1600@120",
	position = "-2560x0",
	scale = 1,
})

hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = 1,
})

hl.device({
	name = "wacom-intuous-pro",
	transform = 6,
	region_size = "2194 1440", -- For 1080p: region_size = "1920 1268",
	output = "current",
})

-- TODO: add xrandr
util.mkNormalSubmap("FOCUS_MONITOR", function()
	hl.bind("f", hl.dsp.focus({ monitor = mon0 }))
	hl.bind("d", hl.dsp.focus({ monitor = monl1 }))
end)

util.mkNormalSubmap("MOVE_WORKSPACE_TO_MONITOR", function()
	hl.bind("f", hl.dsp.workspace.move({ workspace = activeworkspace, monitor = mon0 }))
	hl.bind("d", hl.dsp.workspace.move({ workspace = activeworkspace, monitor = monl1 }))
end)
