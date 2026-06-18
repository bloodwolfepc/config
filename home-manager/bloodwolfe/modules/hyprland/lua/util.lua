---@diagnostic disable: undefined-global
M = {}

M.mkNormalSubmap = function(name, binds, opts)
	if opts == nil then
		opts = { drop_submap = true }
	end
	return hl.define_submap(name, function()
		hl.bind("i", hl.dsp.submap("INSERT"))
		hl.bind("super_l", hl.dsp.submap("NORMAL"))
		binds()
		if opts.drop_submap == true then
			hl.bind("catchall", hl.dsp.submap("INSERT"))
		end
	end)
end

M.mkNormalBinds = function(key, binds)
	return hl.bind(key, function()
		binds()
		hl.dispatch(hl.dsp.submap("INSERT"))
	end)
end

M.mkNavigationKeymap = function(key, direction, opts)
	opts = {
		break_submap = true,
		flash = true,
	} or opts
	return hl.bind(key, function()
		hl.dispatch(hl.dsp.focus({ direction = direction }))
		if opts.flash then
			hl.dispatch(hl.dsp.window.set_prop({
				prop = "active_border_color",
				value = "0xff00ffff",
				window = activewindow,
			}))
			hl.timer(function()
				hl.dispatch(hl.dsp.window.set_prop({
					prop = "active_border_color",
					value = "0xffffffff",
					window = activewindow,
				}))
			end, { timeout = 450, type = "oneshot" })
		end
		if opts.break_submap then
			hl.dispatch(hl.dsp.submap("INSERT"))
		end
	end)
end

M.flash = function(p, opts)
	opts = {
		ammount = "1",
	}
	if opts.timeout & opts.type then
		hl.timer(p, { timeout = opts.timeout, type = opts.type })
	end
end

return M
