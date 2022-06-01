local class = require "libs.middleclass"

local Checker = require "libs.Checker"

local utils = require "libs.utils"
--[[
	Conventions:
		All members (other than functions) are considered private.
		Access should always be through getters/setters,
		
		ClassName:someFunc()			-> Public method.
		ClassName:_someFunc()			-> Protected method (visible only to children)
		local function someFunc(self)	-> Private method (NOT attached to the class, just declared locally).
		
		Note: None of those privacy modifiers are enforced in any way.
			This is no more than an 'honour system'.
			
		Class members are full-length and descriptive names.
		However, method args are given 1-2 letters names matching their mathematical representation
			(based on the namings used in Jas's paper)
		When class members are used in a method, they are often abbreviated
			into their mathematical-name at the top of the method.
		
	Important notes on sources:
		1. What is named `add_sources` in Jas's paper is renamed here to `_computeSources`.
			This is an internal method and should only ever be used if you are extending
			this class with your own custom fluid behavior/model.
		
		2. This class exposes a `addSource` method - this is NOT the same as the `add_sources`
			described by Jas's paper (See note #1).
			`addSource` is used to create a source that will constantly modify that cell's
			stats - it persists until it is removed by `removeSource` or `clearSources`.
			
		3. Lastly, `_processSources` is another internal method, one which is responsible for
			iterating over the sources added by the user (via `addSource`, etc...) and generating
			whatever change they impose on the fluid (done once per `update`).
--]]

------------------------------ Helpers ------------------------------
local function alloc(n, default)
	default = default or 0
	local t = {}

	local size = (n+2)^2
	for i = 0, size do
		t[i] = default
	end
	return t
end

------------------------------ Constructor ------------------------------
local StableFluid = class("StableFluid")
function StableFluid:initialize(n, opt)
	--Dimensions
	Checker:isPositive(n, "N must be positive!")
	Checker:isInteger(n, "N must be an integer!")
	self.N = n
	self.SIZE = (self.N + 2) ^ 2

	--Config
	opt = opt or {}
	--self.maxDensity = opt.maxDensity or math.huge
	self.dt = opt.dt or 0.1
	self.diffusionFactor = opt.diffusionFactor or 0.001
	self.viscocity = opt.viscocity or 0.00001
	self.linearSolverSteps = opt.linearSolverSteps or 20
	
	--State
	self.d 			= alloc(self.N)
	self.dPrevious 	= alloc(self.N)
	self.vx 		= alloc(self.N)
	self.vy 		= alloc(self.N)
	self.vxPrevious = alloc(self.N)
	self.vyPrevious = alloc(self.N)	
	--Interactivity
	self.sources = {}
	
	--Syntactic-Sugar wrappers.
	self.IX = function(x, y) return x + (self.N+2) * y end
end

------------------------------ Interactivity Helpers ------------------------------
function StableFluid:_processSources()
	for k, src in ipairs(self.sources) do
		self.dPrevious[src.index] = self.dPrevious[src.index] + src.density
		self.vxPrevious[src.index] = self.dPrevious[src.index] + src.velocity.x
		self.vyPrevious[src.index] = self.dPrevious[src.index] + src.velocity.y
	end
end

------------------------------ Algorithm - Functions ------------------------------
function StableFluid:_computeSources(x, s, dt)
	for i = 0, self.SIZE do
		x[i] = x[i] + s[i] * dt
	end
end

function StableFluid:_setBounds(b, x)
	--Syntactic-sugar
	local IX = self.IX
	local N = self.N

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

function StableFluid:_diffuse(b, x, x0, diff, dt)
	--Syntactic-sugar
	local IX = self.IX
	local K = self.linearSolverSteps
	local N = self.N
	
	--Vars
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
		self:_setBounds(b, x)
	end	
end

function StableFluid:_advect(b, d, d0, u, v, dt)
	--Performance (local-lookup is far faster than global-lookup)
	local floor = math.floor
	
	--Syntactic-sugar
	local IX = self.IX
	local N = self.N
	
	--Vars
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
			local i0 = floor(x)
			local j0 = floor(y)
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
	self:_setBounds(b, d)
end

function StableFluid:_project(u, v, p, div)
	--Syntactic-sugar
	local IX = self.IX
	local K = self.linearSolverSteps
	local N = self.N
	
	--Vars
	local h = 1.0 / N
	
	for i = 1, N do
		for j = 1, N do
			div[IX(i, j)] = -0.5 * h * (u[IX(i + 1, j)] - u[IX(i - 1, j)] +
				v[IX(i, j + 1)] - v[IX(i, j - 1)])
			p[IX(i, j)] = 0
		end
	end
	self:_setBounds(0, div)
	self:_setBounds(0, p)
	
	for _ = 1, K do
		for i = 1, N do
			for j = 1, N do
				p[IX(i, j)] = (div[IX(i, j)] + 
					(p[IX(i - 1, j)] + p[IX(i + 1,j)] +
					p[IX(i, j - 1)] + p[IX(i, j + 1)])) /
					4
			end
		end
		self:_setBounds(0, p)
	end
	
	for i = 1, N do
		for j = 1, N do
			u[IX(i, j)] = u[IX(i, j)] - (0.5 * (p[IX(i + 1, j)] - p[IX(i - 1, j)]) / h)
			v[IX(i, j)] = v[IX(i, j)] - (0.5 * (p[IX(i, j + 1)] - p[IX(i, j - 1)]) / h) 
		end
	end
	self:_setBounds(1, u)
	self:_setBounds(2, v)
end

------------------------------ Algorithm - Loop ------------------------------
function StableFluid:_densityStep(x, x0, u, v, diff, dt)
	self:_computeSources(x, x0, dt)
	x0, x = x, x0
	self:_diffuse(0, x, x0, diff, dt)
	x0, x = x, x0
	self:_advect(0, x, x0, u, v, dt)
end

function StableFluid:_velocityStep(u, v, u0, v0, visc, dt)
	self:_computeSources(u, u0, dt)
	self:_computeSources(v, v0, dt)
	u0, u = u, u0
	self:_diffuse(1, u ,u0, visc, dt)
	v0, v = v, v0
	self:_diffuse(2, v, v0, visc, dt)
	self:_project(u, v, u0, v0)
	u0, u = u, u0
	v0, v = v, v0	
	self:_advect(1, u, u0, u0, v0, dt)
	self:_advect(2, v, v0, u0, v0, dt)
	self:_project(u, v, u0, v0)	
end

------------------------------ Core API ------------------------------
--Would be much better if this was run in a fixed-timestep loop.
--It will still "work" otherwise - but behavior will be unpredictiable due to rounding errors and such.
function StableFluid:update(dt)
	dt = dt or self.dt		--To faciliate slowing down / speeding up the simulation.
	
	utils.fillArray(self.dPrevious, 0)
	utils.fillArray(self.vxPrevious, 0)
	utils.fillArray(self.vyPrevious, 0)
	self:_processSources()
	
	self:_velocityStep(self.vx, self.vy, self.vxPrevious, self.vyPrevious, self.viscocity, dt)
	self:_densityStep(self.d, self.dPrevious, self.vx, self.vy, self.diffusionFactor, dt)
end

function StableFluid:draw(g2d)
	local N = self.N
	local IX = self.IX

	local scale = g2d.getWidth() / N
	g2d.push('all')
	g2d.scale(scale)
	for x = 1, N do
		for y = 1, N do
			local brightness = self.dPrevious[IX(x, y)]
			g2d.setColor(0, 0, brightness, 1)
			g2d.rectangle('fill', x, y, 1, 1)
		end
	end
	g2d.pop()
end

------------------------------ Interaction API ------------------------------
--Important note: This should be called by a game-engine to add a permanent source (or sink),
--	that will constantly update the fluid by whatever density/velocity/other value it adds (or consumes).
--This is NOT the same as the `add_source` function described by Jas's paper!!!
--	That is renamed to `_computeSources`.
--Note: The src is NOT cloned so if it is later modified via its reference those changes WILL be reflected by the fluid.
--	This is expected usage and should function correctly.
function StableFluid:addSource(x, y, src)
	src.density = src.density or 0
	if not src.velocity then src.velocity = {} end
	src.velocity.x = src.velocity.x or 0
	src.velocity.y = src.velocity.y or 0
	src.index = self.IX(x, y)
	table.insert(self.sources, src)
	return src
end

function StableFluid:removeSource(src)
	for k, other in ipairs(self.sources) do
		if src == other then
			return table.remove(self.sources, k)
		end
	end
	return nil
end

------------------------------ Getters / Setters ------------------------------

return StableFluid
