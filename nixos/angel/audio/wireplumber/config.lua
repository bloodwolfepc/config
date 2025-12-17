alsa_monitor.rules = {
	{
		matches = { { { "node.name", "matches", "alsa_output.*" } } },
		apply_properties = {
			["audio.format"] = "S32LE",
			["audio.rate"] = "96000",
			["api.alsa.period-size"] = 2,
		},
	},
}
