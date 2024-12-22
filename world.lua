local love = require("love")
local config = require("config")
local Entity = require("planets")
local utils = require("utils")

local M = {}

function M.init_world(screen_size, grid_spacing)
	World = {}

	World.screen_size = screen_size
	World.grid_spacing = grid_spacing
	World.screen_centre = {
		x = math.floor(screen_size.width / 2),
		y = math.floor(screen_size.height / 2),
		angle = 0,
	}

	local player = {}
	player.position = {
		x = 0,
		y = 0,
		angle = 0,
	}
	player.onscreen_position = {
		x = math.floor(screen_size.width / 2),
		y = math.floor(screen_size.height / 2),
		angle = 0,
	}
	player.velocity_wrt_universe = {
		x = 0,
		y = 0,
	}
	player.max_force = {
		main = 200 * config.speed_boost,
		reverse = 120 * config.speed_boost,
		port = 150 * config.speed_boost,
		starboard = 150 * config.speed_boost,
		portward = math.pi / 10,
		starboardward = math.pi / 10,
	}
	player.sprite = love.graphics.newImage("gfx/ship.png")
	player.sprite_scale = 0.5
	player.is_thrust_on = {
		main = false,
		reverse = false,
		port = false,
		starboard = false,
	}
	-- TODO : make the mass play a role in gravity force on other entities like planets
	player.rest_mass = 0.5

	function player:experience_gravity(dt)
		-- TODO : make player an instance of Entity to not have to do this separately
		local acc = {
			x = 0,
			y = 0,
		}
		for _, obj in pairs(Entity.massive_objects) do
			local dx = obj.position.x - self.position.x
			local dy = obj.position.y - self.position.y
			local dr = math.sqrt(dx ^ 2 + dy ^ 2)

			if dr ~= 0 then
				acc.x = acc.x + (config.G * obj.mass * dx) / (dr ^ 3)
				acc.y = acc.y + (config.G * obj.mass * dy) / (dr ^ 3)
			end
		end
		local v2 = self.velocity_wrt_universe.x ^ 2 + self.velocity_wrt_universe.y ^ 2
		local gamma_inv = math.sqrt(1 - v2 / config.lightspeed ^ 2)
		local rel_acc = {
			x = acc.x * gamma_inv,
			y = acc.y * gamma_inv,
		}

		local dv = utils.rel_acc(self.velocity_wrt_universe, rel_acc, dt)

		self.velocity_wrt_universe.x = self.velocity_wrt_universe.x + dv.x
		self.velocity_wrt_universe.y = self.velocity_wrt_universe.y + dv.y

		self.position.x = self.position.x + self.velocity_wrt_universe.x * dt
		self.position.y = self.position.y + self.velocity_wrt_universe.y * dt

		local a2 = acc.x ^ 2 + acc.y ^ 2
		if a2 > 1000 then
			local angle = utils.atan(acc.y, acc.x)
			player.position.angle = angle + math.pi / 2
		end
	end

	function player:collision_check()
		-- TODO : make player an instance of Entity to not have to do this separately
		local my_radius = math.sqrt(self.sprite:getWidth() * self.sprite:getHeight()) / 2 * self.sprite_scale
		for j = 1, #Entity.massive_objects do
			local b = Entity.massive_objects[j]

			local dr = {
				x = b.position.x - self.position.x,
				y = b.position.y - self.position.y,
			}
			local dist = math.sqrt(dr.x ^ 2 + dr.y ^ 2)

			if dist ~= 0 then
				local dr_cap = {
					x = dr.x / dist,
					y = dr.y / dist,
				}

				local vel_along_colaxis = dr_cap.x * self.velocity_wrt_universe.x
					+ dr_cap.y * self.velocity_wrt_universe.y
				local vel_affected = {
					x = dr_cap.x * vel_along_colaxis,
					y = dr_cap.y * vel_along_colaxis,
				}

				if dist <= my_radius + b.radius and vel_along_colaxis > 0 then
					-- collision!!
					local factor = 1 + config.bounceback_constant
					self.velocity_wrt_universe = {
						x = self.velocity_wrt_universe.x - factor * vel_affected.x,
						y = self.velocity_wrt_universe.y - factor * vel_affected.y,
					}
				end
			end
		end
	end

	World.player = player

	return World
end

return M
