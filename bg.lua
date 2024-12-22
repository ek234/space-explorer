local utils = require("utils")

local M = {}

function M.get_gridlines(pos)
	local dx_screen = World.screen_size.width / 2
	local dy_screen = World.screen_size.height / 2

	local corners = {
		utils.transform_ship2uni(pos, { x = dx_screen, y = dy_screen }),
		utils.transform_ship2uni(pos, { x = dx_screen, y = -dy_screen }),
		utils.transform_ship2uni(pos, { x = -dx_screen, y = -dy_screen }),
		utils.transform_ship2uni(pos, { x = -dx_screen, y = dy_screen }),
	}

	local set_x = {}
	local set_y = {}
	for idx = 1, 4 do
		local c1 = corners[idx]
		local c2 = corners[(idx % 4) + 1]

		local x_min = math.min(c1.x, c2.x)
		local x_max = math.max(c1.x, c2.x)

		if x_min ~= x_max then
			for x = math.floor(x_min / World.grid_spacing.x) * World.grid_spacing.x, x_max, World.grid_spacing.x do
				if set_x[x] == nil then
					set_x[x] = {}
				end
				local y = (c2.y - c1.y) / (c2.x - c1.x) * (x - c1.x) + c1.y
				table.insert(set_x[x], y)
			end
		end

		local y_min = math.min(c1.y, c2.y)
		local y_max = math.max(c1.y, c2.y)

		if y_min ~= y_max then
			for y = math.floor(y_min / World.grid_spacing.y) * World.grid_spacing.y, y_max, World.grid_spacing.y do
				if set_y[y] == nil then
					set_y[y] = {}
				end
				local x = (c2.x - c1.x) / (c2.y - c1.y) * (y - c1.y) + c1.x
				table.insert(set_y[y], x)
			end
		end
	end

	local lines = {}
	for x, points in pairs(set_x) do
		table.insert(lines, {
			{ x = x, y = math.min(utils.unpack(points)) },
			{ x = x, y = math.max(utils.unpack(points)) },
		})
	end
	for y, points in pairs(set_y) do
		table.insert(lines, {
			{ x = math.min(utils.unpack(points)), y = y },
			{ x = math.max(utils.unpack(points)), y = y },
		})
	end

	local lines_wrt_ship = {}
	for _, ln in pairs(lines) do
		local ln_wrt_ship = {}
		for _, pt in pairs(ln) do
			table.insert(ln_wrt_ship, utils.transform_uni2ship(pos, World.player.onscreen_position, pt))
		end
		table.insert(lines_wrt_ship, ln_wrt_ship)
	end

	return lines_wrt_ship
end

return M
