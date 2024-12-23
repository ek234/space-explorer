local config = require("config")
local M = {}

M.unpack = table.unpack or unpack -- 5.1 compatibility
M.atan = math.atan2 or math.atan -- 5.1 compatibility
print(math.atan(1, 0) / math.pi)

function M.safe_div(a, b)
	if b == 0 then
		return 0
	end
	return a / b
end

function M.transform_ship2uni(ship_pos_uni_frame, pos_offset_wrt_ship)
	local cst = math.cos(ship_pos_uni_frame.angle)
	local snt = math.sin(ship_pos_uni_frame.angle)

	local x = ship_pos_uni_frame.x + pos_offset_wrt_ship.x * cst - pos_offset_wrt_ship.y * snt
	local y = ship_pos_uni_frame.y + pos_offset_wrt_ship.x * snt + pos_offset_wrt_ship.y * cst

	return { x = x, y = y }
end

function M.transform_uni2ship(ship_pos_uni_frame, ship_pos_screen_frame, pos_universe)
	-- TODO : encorporate length contraction
	-- TODO : check if i dont need to draw it is it is outside the screen
	local cst = math.cos(ship_pos_uni_frame.angle)
	local snt = math.sin(ship_pos_uni_frame.angle)

	local dx = pos_universe.x - ship_pos_uni_frame.x
	local dy = pos_universe.y - ship_pos_uni_frame.y

	local x = ship_pos_screen_frame.x + dx * cst + dy * snt
	local y = ship_pos_screen_frame.y + dx * snt - dy * cst

	return { x = x, y = y }
end

function M.rel_acc(u, acc, dt)
	local u2 = u.x ^ 2 + u.y ^ 2
	local c2 = config.lightspeed ^ 2
	local gi2 = 1 - u2 / c2
	assert(0 < gi2 and gi2 <= 1)

	local maxvel2 = 0.999999999999 * c2

	local dv = {
		x = (gi2 * (acc.x * (c2 * gi2 + u.y ^ 2) - acc.y * (u.y * u.x)) * dt) / (c2 * gi2 + u2),
		y = (gi2 * (acc.y * (c2 * gi2 + u.x ^ 2) - acc.x * (u.x * u.y)) * dt) / (c2 * gi2 + u2),
	}

	local v = {
		x = u.x + dv.x,
		y = u.y + dv.y,
	}

	local v2 = v.x ^ 2 + v.y ^ 2

	if v2 > maxvel2 then
		v = {
			x = v.x / v2 * c2,
			y = v.y / v2 * c2,
		}
	end

	dv = {
		x = v.x - u.x,
		y = v.y - u.y,
	}

	return dv
end
--
return M
