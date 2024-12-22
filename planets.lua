local love = require("love")
local utils = require("utils")
local config = require("config")

local Entity = {}

Entity.massive_objects = {}
Entity.sprites = {
	love.graphics.newImage("gfx/planet.png"),
}

function Entity:init(mass, position, velocity, size_factor)
	self.mass = mass
	self.position = position
	self.velocity = velocity
	self.size_factor = size_factor
	self.sprite = Entity.sprites[math.random(#Entity.sprites)]
	self.radius = math.sqrt(self.sprite:getWidth() * self.sprite:getHeight()) / 2 * size_factor

	table.insert(Entity.massive_objects, self)
end

function Entity:draw(ship_pos_uni_frame, ship_pos_screen_frame)
	local onscreen_position = utils.transform_uni2ship(ship_pos_uni_frame, ship_pos_screen_frame, self.position)
	love.graphics.draw(
		self.sprite,
		onscreen_position.x - math.floor(self.sprite:getWidth() * self.size_factor / 2),
		onscreen_position.y - math.floor(self.sprite:getHeight() * self.size_factor / 2),
		0,
		self.size_factor
	)
end

function Entity:update_vel(dt)
	-- print("planet vel", self.velocity.x, self.velocity.y)
	local v2 = self.velocity.x ^ 2 + self.velocity.y ^ 2
	local gamma_inv = math.sqrt(1 - v2 / config.lightspeed ^ 2)
	assert(0 < gamma_inv and gamma_inv <= 1)

	local acc = {
		x = 0,
		y = 0,
	}
	for _, obj in pairs(Entity.massive_objects) do
		local dx = obj.position.x - self.position.x
		local dy = obj.position.y - self.position.y
		local dr = math.sqrt(dx ^ 2 + dy ^ 2)

		local mass = obj.mass / gamma_inv

		if dr ~= 0 then
			acc.x = acc.x + (config.G * mass * dx) / (dr ^ 3)
			acc.y = acc.y + (config.G * mass * dy) / (dr ^ 3)
		end

		-- NB : if dr is 0, then ignore that obj.
		-- so, self does not contribute at all.
	end

	acc = {
		x = acc.x * gamma_inv,
		y = acc.y * gamma_inv,
	}

	local dv = utils.rel_acc(self.velocity, acc, dt)

	self.velocity.x = self.velocity.x + dv.x
	self.velocity.y = self.velocity.y + dv.y
end

function Entity:update_position(dt)
	self.position.x = self.position.x + self.velocity.x * dt
	self.position.y = self.position.y + self.velocity.y * dt
end

function Entity.make_entity(mass, position, velocity, size_factor)
	local e = {}
	setmetatable(e, { __index = Entity })
	e:init(mass, position, velocity, size_factor)
	return e
end

function Entity.draw_all(ship_pos_uni_frame, ship_pos_screen_frame)
	for _, e in pairs(Entity.massive_objects) do
		e:draw(ship_pos_uni_frame, ship_pos_screen_frame)
	end
end

function Entity.update_all(dt)
	for _, e in pairs(Entity.massive_objects) do
		e:update_vel(dt)
	end
	Entity.collision_check()
	for _, e in pairs(Entity.massive_objects) do
		e:update_position(dt)
	end
end

function Entity.collision_check()
	for i = 1, #Entity.massive_objects do
		local a = Entity.massive_objects[i]
		for j = 1, #Entity.massive_objects do
			local b = Entity.massive_objects[j]

			if i ~= j then
				local dr = {
					x = b.position.x - a.position.x,
					y = b.position.y - a.position.y,
				}
				local dist = math.sqrt(dr.x ^ 2 + dr.y ^ 2)

				if dist ~= 0 then
					local dr_cap = {
						x = dr.x / dist,
						y = dr.y / dist,
					}

					local vel_along_colaxis = dr_cap.x * a.velocity.x + dr_cap.y * a.velocity.y
					local vel_affected = {
						x = dr_cap.x * vel_along_colaxis,
						y = dr_cap.y * vel_along_colaxis,
					}

					if dist <= a.radius + b.radius and vel_along_colaxis > 0 then
						-- collision!!
						local factor = 1 + config.bounceback_constant
						a.velocity = {
							x = a.velocity.x - factor * vel_affected.x,
							y = a.velocity.y - factor * vel_affected.y,
						}
					end
				end
			end
		end
	end
end

return Entity
