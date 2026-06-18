---@diagnostic disable: undefined-global
local config = {
	general = {
		gaps_in = 5,
		gaps_out = 20,
		border_size = 1,
		allow_tearing = true,
		layout = "dwindle",
	},
	decoration = {
		rounding = 0,
		fullscreen_opacity = 1.0,
		inactive_opacity = 1.0,
		dim_modal = false,
		shadow = {
			enabled = false,
		},
		blur = {
			enabled = false,
		},
	},
	animations = {
		enabled = false,
	},
	dwindle = {
		preserve_split = true,
		permanent_direction_override = true,
		smart_split = false,
		smart_resizing = false,
	},
	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		force_default_wallpaper = 0,
		render_unfocused_fps = 60,
	},
	input = {
		sensitivity = 0,
		accel_profile = "flat",
		follow_mouse = 1,
		touchpad = {
			natural_scroll = false,
			disable_while_typing = false,
		},
	},
	cursor = {
		inactive_timeout = 0.5,
		hide_on_key_press = true,
		hide_on_touch = true,
		hide_on_tablet = true,
	},
	binds = {
		allow_workspace_cycles = true,
	},
	xwayland = {
		enabled = true,
		force_zero_scaling = true,
	},
	render = {
		direct_scanout = 1,
	},
}
hl.config(config)
Opts = {
	power = {
		power_based_config = true,
		threshold = 35,
	},
	flash = {
		cols = {
			window_destroy = "#ff0000",
			monitor_added = "#ff6688",
		},
	},
}

--https://github.com/micha4w/Hypr-DarkWindow
--https://github.com/overlayeddev/overlayed
local min_startup = function()
	hl.exec_cmd("wezterm", { workspace = 4 })
	hl.exec_cmd("firefox", { workspace = 4 })
	-- ac is not in and startup then run
	-- if rerun after startup close all max apps and keep these
end
local max_startup = function()
	hl.exec_cmd("vesktop")
	hl.exec_cmd("steam > /home/bloodwolfe/.steam.out 2>&1")
	hl.exec_cmd("spotify")
	-- ac is in and startup then run
	-- if rerun after startup start these apps
end

hl.on("hyprland.start", function()
	hl.dsp(hl.dsp.submap("INSERT"))
	hl.dsp.focus({ workspace = "4" })
	hl.exec_cmd("systemctl restart --user awww.service")
	hl.exec_cmd("systemctl restart --user waybar.service")
	hl.exec_cmd("systemctl restart --user hyprpolkitagent.service")
	hl.exec_cmd("awww img /home/bloodwolfe/src/config/assets/wallpapers/black.png -t none")
	hl.exec_cmd("hyprctl setcursor Plasma-Overdose 12")
	hl.exec_cmd("xrandr --output DP-1 --primary")
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	-- hl.exec_cmd("${pkgs.libcanberra-gtk3}/bin/canberra-gtk-play -i desktop-login")
	hl.exec_cmd("wl-paste -t text -w xclip -selection clipboard") -- FIXES: Clipboard in Wine
	hl.exec_cmd("fcitx5 -d -r")
	hl.exec_cmd("fcitx5-remote -r")
	min_startup()
	max_startup()
end)
require("keymaps")
require("monitors")
require("rules")
