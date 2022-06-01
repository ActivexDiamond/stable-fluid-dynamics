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
--]]

------------------------------ Constructor ------------------------------
local StableFluid = class("StableFluid")
function StableFluid:initialize(n, opt)
	--Dimensions
	Checker:isPositive(n, "N must be positive!")
	Checker:isInteger(n, "N must be an integer!")
	self.N = N
	self.SIZE = (self.N + 2) ^ 2

	--Config
	opt = opt or {}
	self.maxDensity = opt.maxDensity or math.huge
	self.dt = opt.dt or 0.1
	self.diffusionFactor = opt.diffusionFactor or 0.001
	self.viscocity = opt.viscocity or 0.000001
	self.linearSolverSteps = opt.linearSolverSteps or 20
	
	--State
	self.d 			= utils.createDimensionalArray(self.SIZE)
	self.dPrevious 	= utils.createDimensionalArray(self.SIZE)
	self.vx 		= utils.createDimensionalArray(self.SIZE)
	self.vy 		= utils.createDimensionalArray(self.SIZE)
	self.vxPrevious = utils.createDimensionalArray(self.SIZE)
	self.vyPrevious = utils.createDimensionalArray(self.SIZE)
	
	--Interactivity
	self.sources = {}
	
	--Syntactic-Sugar wrappers.
	self.IX = function(x, y) return utils.computeIndexFromPoint(x, y, self.N - 2) end
end

------------------------------ Algorithm - Mathematical Helpers ------------------------------
function StableFluid:_linearSolver()

end

------------------------------ Algorithm - Functions ------------------------------
function StableFluid:_setBounds(b, x)

end

------------------------------ Algorithm - Loop ------------------------------
function StableFluid:diffuse(b, x, x0, diff, dt)
	--Helpers

	--Vars
	local L = self.N
	local a = L * L * diff * dt
	for _ = 1, K do
		for i = 1, L do
			for j = 1, L do
				x[IX(i, j)] = (x0[IX(i, j)] + a * 
					(x[IX(i - 1, j)] + x[IX(i + 1,j)] +
					x[IX(i, j - 1)] + x[IX(i, j + 1)])) /
					(1 + 4 * a)
			end
		end
		setBounds(b, x)
	end	

end

------------------------------ Interaction API ------------------------------
--Important note: This should be called by a game-engine to add a permanent source (or sink),
--	that will constantly update the fluid by whatever density/velocity/other value it adds (or consumes).
--This is NOT the same as the `add_source` function described by Jas's paper!!!
--	That is renamed to `_computeSources`.
function StableFluid:addSource()

end

------------------------------ Getters / Setters ------------------------------

return StableFluid
