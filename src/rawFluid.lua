--[[
This was the initial implementation I first did of Jos Stam's algorithm.
It is a minimal and completely self-contained implementation.
Single file, no dependencies, etc...

I have since refactored it into a much more usable format. See the github/docs for information.

Repo: https://github.com/ActivexDiamond/stable-fluid-dynamics
 
--]]

------------------------------ Controls ------------------------------
io.stdout:setvbuf("no")

------------------------------ Config ------------------------------
local N = 100

local CHAOS_FACTOR = 0.01

local MAX_DENSITY = 5
local FADE = 0.2

local ADD_DENSITY = 100
local ADD_VELOCITY_X = 10
local ADD_VELOCITY_Y = 10

local REMOVE_DENSITY_RADIUS = 10
local REMOVE_VELOCITY_RADIUS = 100

local DT = 0.1
local DIFFUSION = 0.001
local VISCOCITY = 0.00001

--Linear solver's number of steps - relates to its precision.
local K = 20

------------------------------ Helpers ------------------------------
local function IX(x, y) return x + (N+2) * y end

local function alloc(n, default)
	default = default or 0
	local t = {}

	local size = (n+2)^2
	for i = 0, size do
		t[i] = default
	end
	return t
end

local function fill(t, val)
	val = val or 0
	for k in ipairs(t) do
		t[k] = val
	end
end

local function map(x, min, max, nmin, nmax)
	return (x - min) * (nmax - nmin) / (max - min) + nmin
end

------------------------------ Data Arrays ------------------------------
--vx, vy
local u0, v0 = alloc(N), alloc(N)	--Current
local u, v = alloc(N), alloc(N)		--Next

--density
local d0 = alloc(N)			--Current
local d = alloc(N)			--Next

--for i = 1, N do
--	for j = 1, N do
--		d0[IX(i, j)] = love.math.noise(i / CHAOS_FACTOR, j / CHAOS_FACTOR)
--	end
--end

------------------------------ Algorithm - Helpers ------------------------------
local function addSource(x, s, dt)
	local size = (N+2)^2
	for i = 0, size do
		x[i] = x[i] + s[i] * dt
	end
end

local function setBounds(b, x)
	for i = 1, N do
		x[IX(0,		i)] = b == 1 and -x[IX(1, i)] or x[IX(1, i)]
		x[IX(N + 1,	i)] = b == 1 and -x[IX(N, i)] or x[IX(N, i)]
		x[IX(i,		0)] = b == 2 and -x[IX(i, 1)] or x[IX(i, 1)]
		x[IX(i, N + 1)] = b == 2 and -x[IX(i, N)] or x[IX(i, N)]
	end
	x[IX(0,		0)] 	= 0.5 * (x[IX(1, 0)] 	 + x[IX(0, 1)])
	x[IX(0,		N + 1)] = 0.5 * (x[IX(1, N + 1)] + x[IX(0, N)])
	x[IX(N + 1, 0)] 	= 0.5 * (x[IX(N, 0)] 	 + x[IX(N + 1, 1)])
	x[IX(N + 1, N + 1)] = 0.5 * (x[IX(N, N + 1)] + x[IX(N + 1, N)])
end

------------------------------ Algorithm - Core ------------------------------
local function diffuse(b, x, x0, diff, dt)
	local a = N * N * diff * dt
	for _ = 1, K do
		for i = 1, N do
			for j = 1, N do
				x[IX(i, j)] = (x0[IX(i, j)] + a *
					(x[IX(i - 1, j)] + x[IX(i + 1,j)] +
					x[IX(i, j - 1)] + x[IX(i, j + 1)])) /
					(1 + 4 * a)
			end
		end
		setBounds(b, x)
	end
end

local function advect(b, d, d0, u, v, dt)
	local dt0 = dt * N
	for i = 1, N do
		for j = 1, N do
			--Initial value
			local x = i - dt0 * u[IX(i, j)]
			local y = j - dt0 * v[IX(i, j)]
			--Upper bound
			if x < 0.5 then x = 0.5 end
			if y < 0.5 then y = 0.5 end
			--Lower bound
			if x > N + 0.5 then x = N + 0.5 end
			if y > N + 0.5 then y = N + 0.5 end
			--Position intensities
			local i0 = math.floor(x)
			local j0 = math.floor(y)
			local i1 = i0 + 1
			local j1 = j0 + 1
			--
			local s1 = x - i0
			local s0 = 1 - s1
			local t1 = y - j0
			local t0 = 1 - t1

			--
			d[IX(i, j)] = s0 * (t0 * d0[IX(i0, j0)] + t1 * d0[IX(i0, j1)]) +
				s1 * (t0 * d0[IX(i1, j0)] + t1 * d0[IX(i1, j1)])
		end
	end
	setBounds(b, d)
end

local function project(u, v, p, div)
	local h = 1.0 / N
	for i = 1, N do
		for j = 1, N do
			div[IX(i, j)] = -0.5 * h * (u[IX(i + 1, j)] - u[IX(i - 1, j)] +
				v[IX(i, j + 1)] - v[IX(i, j - 1)])
			p[IX(i, j)] = 0
		end
	end
	setBounds(0, div)
	setBounds(0, p)

	for _ = 1, K do
		for i = 1, N do
			for j = 1, N do
				p[IX(i, j)] = (div[IX(i, j)] +
					(p[IX(i - 1, j)] + p[IX(i + 1,j)] +
					p[IX(i, j - 1)] + p[IX(i, j + 1)])) /
					4
			end
		end
		setBounds(0, p)
	end

	for i = 1, N do
		for j = 1, N do
			u[IX(i, j)] = u[IX(i, j)] - (0.5 * (p[IX(i + 1, j)] - p[IX(i - 1, j)]) / h)
			v[IX(i, j)] = v[IX(i, j)] - (0.5 * (p[IX(i, j + 1)] - p[IX(i, j - 1)]) / h)
		end
	end
	setBounds(1, u)
	setBounds(2, v)
end

------------------------------ Algorithm - Loop ------------------------------
local function densityStep(x, x0, u, v, diff, dt)
	addSource(x, x0, dt)
	x0, x = x, x0
	diffuse(0, x, x0, diff, dt)
	x0, x = x, x0
	advect(0, x, x0, u, v, dt)
end

local function velocityStep(u, v, u0, v0, visc, dt)
	addSource(u, u0, dt)
	addSource(v, v0, dt)
	u0, u = u, u0
	diffuse(1, u ,u0, visc, dt)
	v0, v = v, v0
	diffuse(2, v, v0, visc, dt)
	project(u, v, u0, v0)
	u0, u = u, u0
	v0, v = v, v0
	advect(1, u, u0, u0, v0, dt)
	advect(2, v, v0, u0, v0, dt)
	project(u, v, u0, v0)
end

--Extra
local function fadeDensity(t)
	local size = (N+2)^2
	for i = 1, size do
		t[i] = math.max(0, t[i] - FADE)
	end
end

local function bindDensity(t)
	local size = (N+2)^2
	for i = 1, size do
		t[i] = math.min(t[i], MAX_DENSITY)
	end
end

local function removeDensity(x, y, r)
	for i = x - r, x + r do
		for j = y - r, y + r do
			d[IX(i, j)] = 0
		end
	end
end

local function removeVelocity(x, y, r)
	for i = x - r, x + r do
		for j = y - r, y + r do
			u[IX(i, j)] = 0
			v[IX(i, j)] = 0
		end
	end
end

------------------------------ Interactivity ------------------------------
local input = {}
function love.mousepressed(x, y, button)
	table.insert(input, {
		type = "mousePressed",
		x = x,
		y = y,
		button = button,
		shift = love.keyboard.isDown("lshift"),
	})
end

local sources = {}
local function processUserInput()
	fill(d0, 0)
	fill(u0, 0)
	fill(v0, 0)

	for i = #input, 1, -1 do
		local ev = table.remove(input, i)
		if ev.type == "mousePressed" then
			local x = math.floor(map(ev.x, 0, love.graphics.getWidth(), 0, N))
			local y = math.floor(map(ev.y, 0, love.graphics.getHeight(), 0, N))

			if ev.button == 1 and ev.shift then
				removeDensity(x, y, REMOVE_DENSITY_RADIUS)
			elseif ev.button == 2 and ev.shift then
				removeVelocity(x, y, REMOVE_VELOCITY_RADIUS)
			elseif ev.button == 1 then
				table.insert(sources, {
					index = IX(x, y),
					d0 = ADD_DENSITY,
				})
			elseif ev.button == 2 then
				table.insert(sources, {
					index = IX(x, y),
					d0 = ADD_DENSITY,
					u0 = math.random(0, ADD_VELOCITY_X),
					v0 = math.random(0, ADD_VELOCITY_Y),
				})
			end
		end
	end

	for k, src in ipairs(sources) do
		d0[src.index] = d0[src.index] + src.d0
		if src.u0 then
			u0[src.index] = u0[src.index] + src.u0
			v0[src.index] = v0[src.index] + src.v0
		end
	end


	--	if love.mouse.isDown(1) then
	--		local mx, my = love.mouse.getPosition()
	--		local x = math.floor(map(mx, 0, love.graphics.getWidth(), 0, N))
	--		local y = math.floor(map(my, 0, love.graphics.getHeight(), 0, N))
	--		d0[IX(x, y)] = d0[IX(x, y)] + ADD_DENSITY
	--	end
	--
	--	if love.mouse.isDown(2) then
	--		local mx, my = love.mouse.getPosition()
	--		local x = math.floor(map(mx, 0, love.graphics.getWidth(), 0, N))
	--		local y = math.floor(map(my, 0, love.graphics.getHeight(), 0, N))
	--		u0[IX(x, y)] = u0[IX(x, y)] + ADD_VEL_X
	--		v0[IX(x, y)] = v0[IX(x, y)] + ADD_VEL_Y
	--	end
end

------------------------------ Gameplay Loop ------------------------------
function love.update(dt)
	dt = DT

	processUserInput()
	velocityStep(u, v, u0, v0, VISCOCITY, dt)
	densityStep(d, d0, u, v, DIFFUSION, dt)
	bindDensity(d0)
	fadeDensity(d0)

	local td = 0
	for i = 1, (N+2)^2 do
		td = td + d0[i]
	end
	print("Total density:", td)
end

function love.draw()
	local g2d = love.graphics
	local scale = love.graphics.getWidth() / N
	g2d.push('all')
	g2d.scale(scale)
	for i = 1, N do
		for j = 1, N do
			local brightness = d0[IX(i, j)]
			g2d.setColor(0, 0, brightness, 1)
			g2d.rectangle('fill', i, j, 1, 1)
		end
	end
	g2d.pop()
end


function love.keypressed(key, scancode, isrepeat)
	if key == 'escape' then
		love.event.quit()
	end
end
