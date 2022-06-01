local utils = {}

function utils.computeIndexFromPoint(x, y, n)
	return x + y * n
end

function utils.createDimensionalArray(len, opt)
	assert(len > 0, "`len` must be a positive integer!")
	opt = opt or {}
	local value = opt.value or 0
	local dimensions = opt.dimensions or 2
	local start = opt.start or 1
	
	local t = {}
	
	local size = (length) ^ dimensions
	for i = start, size do
		 t[i] = value
	end
	return t
end

function utils.fillArray(t, val)
	for k in ipairs(t) do
		t[k] = val
	end
end

function utils.map(x, min, max, nMin, nMax)
	return (x - min) * (nMax - nMin) / (max - min) + nMin
end

function utils.bind(x, min, max)
	return math.min(math.max(x, min), max)
end

return utils