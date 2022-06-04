io.stdout:setvbuf('line')

--require "rawFluid"
---[[
local utils = require "libs.utils"

local StableFluid = require "StableFluid"

local N = 100

local fluid;
function love.load()
	math.randomseed(os.time())
	fluid = StableFluid(N)
end

function love.update(dt)
	fluid:update(0.1)
end

function love.draw()
	local g2d = love.graphics
	fluid:draw(g2d)
end

function love.mousepressed(x, y, button)
	x = math.floor(utils.map(x, 0, love.graphics.getWidth(), 0, N))
	y = math.floor(utils.map(y, 0, love.graphics.getHeight(), 0, N))
	fluid:addSource(x, y, {
		density = 10,
		velocity = {
			x = math.random(0, 10),
			y = math.random(0, 10),
		},
	})
end

function love.keypressed(key, scancode)
	if key == 'escape' then
		love.event.quit()
	end
end
--]]
