local love = require("love")
local utils = require("utils")

ParticleSystem = {}

function ParticleSystem:new(sprite, lifetime, max_number_of_particles, direction, speed, location_from_ship, color)
	self.sprite = sprite
	self.num_particles = max_number_of_particles
	self.lifetime = lifetime

	self.particles = {}

	self.start_idx = 1
	self.size = 0

	self.direction_wrt_ship = direction
	self.speed_wrt_ship = speed
	self.position_offset_wrt_ship = location_from_ship
	self.color_start = { color[1], color[2], color[3], color[4] }
	self.color_end = { color[5], color[6], color[7], color[8] }

	self.position_entropy = math.sqrt(sprite:getHeight() * sprite:getWidth()) * 1.5
	self.direction_entropy = math.pi / 3
end

function ParticleSystem:draw(player_position, player_onscreen_position)
	local og_color = { love.graphics.getColor() }

	for _idx = self.start_idx, self.start_idx + self.size - 1 do
		local idx = 1 + ((_idx - 1) % self.num_particles)

		local position_wrt_ship =
			utils.transform_uni2ship(player_position, player_onscreen_position, self.particles[idx].pos)

		local lifeleft = self.particles[idx].timeleft / self.lifetime

		local color = {
			self.color_end[1] + (self.color_start[1] - self.color_end[1]) * lifeleft,
			self.color_end[2] + (self.color_start[2] - self.color_end[2]) * lifeleft,
			self.color_end[3] + (self.color_start[3] - self.color_end[3]) * lifeleft,
			self.color_end[4] + (self.color_start[4] - self.color_end[4]) * lifeleft,
		}
		love.graphics.setColor(color)

		love.graphics.draw(self.sprite, position_wrt_ship.x, position_wrt_ship.y)
	end

	love.graphics.setColor(og_color)
end

function ParticleSystem:update(dt)
	for _idx = self.start_idx, self.start_idx + self.size - 1 do
		local idx = 1 + ((_idx - 1) % self.num_particles)
		self.particles[idx].timeleft = self.particles[idx].timeleft - dt
		if self.particles[idx].timeleft <= 0 then
			self.particles[idx] = nil
			self.start_idx = 1 + (idx % self.num_particles)
			self.size = self.size - 1
		else
			self.particles[idx].pos.x = self.particles[idx].pos.x + self.particles[idx].speed.x * dt
			self.particles[idx].pos.y = self.particles[idx].pos.y + self.particles[idx].speed.y * dt
		end
	end
end

function ParticleSystem:release(player_position, num_particles)
	num_particles = math.min(num_particles, self.num_particles)

	local old_end_idx = 1 + ((self.start_idx + self.size - 1) % self.num_particles)
	for _idx = old_end_idx, old_end_idx + num_particles - 1 do
		local idx = 1 + ((_idx - 1) % self.num_particles)
		if self.size == self.num_particles then
			self.particles[self.start_idx] = nil
			self.start_idx = 1 + (self.start_idx % self.num_particles)
			self.size = self.size - 1
		end

		local cst_projection =
			math.cos(player_position.angle + self.direction_wrt_ship + (math.random() - 0.5) * self.direction_entropy)
		local snt_projection =
			math.sin(player_position.angle + self.direction_wrt_ship + (math.random() - 0.5) * self.direction_entropy)

		self.particles[idx] = {}

		self.particles[idx].timeleft = self.lifetime

		self.particles[idx].pos = utils.transform_ship2uni(player_position, self.position_offset_wrt_ship)
		self.particles[idx].pos.x = self.particles[idx].pos.x + (math.random() - 0.5) * self.position_entropy
		self.particles[idx].pos.y = self.particles[idx].pos.y + (math.random() - 0.5) * self.position_entropy
		self.particles[idx].speed = {
			x = -self.speed_wrt_ship * snt_projection,
			y = self.speed_wrt_ship * cst_projection,
		}

		self.size = self.size + 1
	end
end

local M = {}

function M.init_particle_system(sprite, lifetime, max_number_of_particles, direction, speed, location_from_ship, color)
	local obj = {}
	setmetatable(obj, { __index = ParticleSystem })
	obj:new(sprite, lifetime, max_number_of_particles, direction, speed, location_from_ship, color)
	return obj
end

return M
