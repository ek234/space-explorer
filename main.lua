local love = require("love")
local world_code = require("world")
local utils = require("utils")
local bg_code = require("bg")
local particles_code = require("particles")
local Entity = require("planets")

local config = require("config")

function love.load()
	if not love.window.setMode(config.screen_size.width, config.screen_size.height) then
		love.event.quit()
	end

	World = world_code.init_world(config.screen_size, config.grid_spacing)
	Statusbar = love.graphics.newText(love.graphics.getFont())
	local particle_sprite = love.graphics.newImage("gfx/particle.png")
	PS = {}
	PS["main"] = particles_code.init_particle_system(particle_sprite, 3, 1000, math.pi, 50, {
		x = -particle_sprite:getWidth() / 2,
		y = -World.player.sprite:getHeight() * World.player.sprite_scale / 2 + particle_sprite:getHeight() / 2,
	}, { 0.9, 0.9, 0.9, 1, 0.1, 0.1, 0.1, 0 })
	PS["reverse"] = particles_code.init_particle_system(particle_sprite, 3, 1000, 0, 50, {
		x = -particle_sprite:getWidth() / 2,
		y = World.player.sprite:getHeight() * World.player.sprite_scale / 2 + particle_sprite:getHeight() / 2,
	}, { 0.9, 0.9, 0.9, 1, 0.1, 0.1, 0.1, 0 })
	PS["port"] = particles_code.init_particle_system(particle_sprite, 3, 1000, -math.pi / 2, 50, {
		x = World.player.sprite:getWidth() * World.player.sprite_scale / 2 - particle_sprite:getWidth() / 2,
		y = particle_sprite:getHeight() / 2,
	}, { 0.9, 0.9, 0.9, 1, 0.1, 0.1, 0.1, 0 })
	PS["starboard"] = particles_code.init_particle_system(particle_sprite, 3, 1000, math.pi / 2, 50, {
		x = -World.player.sprite:getWidth() * World.player.sprite_scale / 2 - particle_sprite:getWidth() / 2,
		y = particle_sprite:getHeight() / 2,
	}, { 0.9, 0.9, 0.9, 1, 0.1, 0.1, 0.1, 0 })

	Entity.make_entity(300, { x = 500, y = 0 }, { x = 0, y = 50 }, 1)
	Entity.make_entity(300, { x = -500, y = 0 }, { x = 0, y = -50 }, 1)
end

function love.draw()
	local player = World.player

	love.graphics.setColor(0.3, 0.4, 0.7, 0.6)

	local lines = bg_code.get_gridlines(player.position)
	for _, ln in pairs(lines) do
		love.graphics.line(ln[1].x, ln[1].y, ln[2].x, ln[2].y)
	end

	love.graphics.setColor(0.3, 0.4, 0.7, 0.1)

	local x_min = player.position.x - math.floor(World.screen_size.width / 2)
	local x_max = player.position.x + math.ceil(World.screen_size.width / 2)
	for x = math.floor(x_min / World.grid_spacing.x) * World.grid_spacing.x, x_max, World.grid_spacing.x do
		local x_screen = x - player.position.x + player.onscreen_position.x
		love.graphics.line(x_screen, 0, x_screen, World.screen_size.height)
	end

	local y_min = player.position.y - math.floor(World.screen_size.height / 2)
	local y_max = player.position.y + math.ceil(World.screen_size.height / 2)
	for y = math.floor(y_min / World.grid_spacing.y) * World.grid_spacing.y, y_max, World.grid_spacing.y do
		local y_screen = y - player.position.y + player.onscreen_position.y
		love.graphics.line(0, y_screen, World.screen_size.width, y_screen)
	end

	love.graphics.setColor(1, 1, 1, 1)

	love.graphics.draw(Statusbar, 10, World.screen_size.height - Statusbar:getHeight() - 10)

	love.graphics.setColor(0.3, 0.4, 0.6, 0.7)

	for _, ps in pairs(PS) do
		ps:draw(player.position, World.player.onscreen_position)
	end

	love.graphics.setColor(0.7, 0.7, 0.7, 1)
	local entropic_onscreen_position = World.player.onscreen_position
	-- local entropic_onscreen_position = {
	-- 	x = math.floor(World.screen_size.width / 2 + World.player.sprite:getWidth() * (2 * math.random() - 1) * 0.02),
	-- 	y = math.floor(World.screen_size.height / 2 + World.player.sprite:getHeight() * (2 * math.random() - 1) * 0.02),
	-- 	angle = 0,
	-- }

	love.graphics.draw(
		player.sprite,
		entropic_onscreen_position.x - math.floor(player.sprite:getWidth() * World.player.sprite_scale / 2),
		entropic_onscreen_position.y - math.floor(player.sprite:getHeight() * World.player.sprite_scale / 2),
		0,
		World.player.sprite_scale
	)

	Entity.draw_all(World.player.position, World.player.onscreen_position)
end

function love.update(dt)
	local player = World.player

	local thrust_wrt_ship = {
		x = 0,
		y = 0,
	}

	if love.keyboard.isDown("escape") then
		love.event.quit()
	end
	if love.keyboard.isDown("w") then
		thrust_wrt_ship.y = thrust_wrt_ship.y + player.max_force.main
		PS["main"]:release(player.position, 1)
	end
	if love.keyboard.isDown("s") then
		thrust_wrt_ship.y = thrust_wrt_ship.y - player.max_force.reverse
		PS["reverse"]:release(player.position, 1)
	end
	if love.keyboard.isDown("d") then
		thrust_wrt_ship.x = thrust_wrt_ship.x + player.max_force.starboard
		PS["starboard"]:release(player.position, 1)
	end
	if love.keyboard.isDown("a") then
		thrust_wrt_ship.x = thrust_wrt_ship.x - player.max_force.port
		PS["port"]:release(player.position, 1)
	end
	if love.keyboard.isDown("q") then
		player.position.angle = (player.position.angle + player.max_force.portward * dt) % (2 * math.pi)
	end
	if love.keyboard.isDown("e") then
		player.position.angle = (player.position.angle - player.max_force.starboardward * dt) % (2 * math.pi)
	end

	local force_wrt_universe = utils.transform_ship2uni({
		x = 0,
		y = 0,
		angle = player.position.angle,
	}, thrust_wrt_ship)

	local speed = math.sqrt(player.velocity_wrt_universe.x ^ 2 + player.velocity_wrt_universe.y ^ 2)
	local gamma_inv = math.sqrt(1 - speed ^ 2 / config.lightspeed ^ 2)

	local acceleration_wrt_universe = {
		x = gamma_inv * force_wrt_universe.x / World.player.rest_mass,
		y = gamma_inv * force_wrt_universe.y / World.player.rest_mass,
	}

	local dv = utils.rel_acc(player.velocity_wrt_universe, acceleration_wrt_universe, dt)

	player.velocity_wrt_universe = {
		x = player.velocity_wrt_universe.x + dv.x,
		y = player.velocity_wrt_universe.y + dv.y,
	}

	for _, ps in pairs(PS) do
		ps:update(dt)
	end

	Entity.update_all(dt)

	World.player:experience_gravity(dt)
	World.player:collision_check()

	player.position = {
		x = player.position.x + player.velocity_wrt_universe.x * dt,
		y = player.position.y + player.velocity_wrt_universe.y * dt,
		angle = player.position.angle,
	}

	Statusbar:set(
		string.format(
			"(%5.1f, %5.1f)\n(%5.1f, %5.1f) - %5.1f",
			player.position.x,
			player.position.y,
			player.velocity_wrt_universe.x,
			player.velocity_wrt_universe.y,
			(math.sqrt(player.velocity_wrt_universe.x ^ 2 + player.velocity_wrt_universe.y ^ 2))
		)
	)
end
