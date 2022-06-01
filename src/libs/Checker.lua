local Checker = {
  _VERSION_STRING = "Checker 1.0-beta",
  _VERSION = {
  	MAJOR = 1,
  	MINOR = 0,
  	HOTFIX = 0,
  	
  	BRANCH = "beta",
  },
  
  _DESCRIPTION = "A small assertion library made for Lua 5.1.\nShould work with most Lua 5.x versions.",
  
  _URL = "https://github.com/ActivexDiamond \tTODO: Push this to my github.",
  
  _LICENSE = [[
MIT LICENSE
Copyright (c) 2011 Enrique GarcÃ­a Cota
Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ]],  
  
  _README = [[
The assertion messages have a few bits of format (just to ease reading.)
	{x}		->		x is hard-coded-checked by the function.
	[x]		->		x is a passed in arg.
	<x>		->		x is the name of the arg.
Example:
	Checker:isFalse(42)				->	[42] is not {false}.
	Checker:isValue(42, false)		->	[42] is not [false].
	

  
Usage is pretty straightforward.
Here's an example.

--TODO: Example.
  
]]
}

------------------------------ Helpers ------------------------------
--Can't use varargs because that complicates allowing nil-values.
--Since this is only ever used internally in this one module,
--	this alternative works just fine.
--string.format will just discard any extra params, anyways. Even if they are not nil.
local ft

local function formatArgCleaner(obj)
	local typ = type(obj)
	if typ == 'string' then
		return string.format("\"%s\"", obj)
	elseif typ == 'table' then
		return ft(obj)
	end
	return tostring(obj)	
end

local function f(template, a, b, c, d, e)
	local fac = formatArgCleaner
	return template:format(fac(a), fac(b), fac(c), fac(d), fac(e))
end

function ft(t)
	if tableIsEmpty(t) then
		return "{}"
	end
	
	local str = "{"
	for k, v in ipairs(t) do
		str = str .. formatArgCleaner(v) .. ", "
	end
	
	for k, v in pairs(t) do
		if type(k) ~= 'number' then
			str = str .. formatArgCleaner(v) .. ", "
		end
	end
	str = str:sub(1, -3) .. "}"
	return str
end

local function tableIsEmpty(t)
	return next(t) == nil
end

------------------------------ Module Functions ------------------------------
local Checker = {}

function Checker:setActive(active)
	self.active = active
end

function Checker:setVerbose(verbose)
	self.verbose = verbose
end

function Checker:_err(msg, check)
	self:_log(msg, check, true)
	if self.active then
		local str = "ASSERTION FAILED  : |%s|\t%s"
		error(str:format(check, msg or ""))
	end
end

function Checker:_log(msg, check, failed)
	if failed then
		local str = "ASSERTION FAILED  : |%s|\t%s"
		print(str:format(check, msg or ""))
	elseif self.verbose then
		local str = "ASSERTION SUCCEDED: |%s|\t%s"
		print(str:format(check, msg or ""))
	end
	--TODO: Add logging here.
end

------------------------------ Module Init ------------------------------
Checker:setActive(true)
Checker:setVerbose(false)

------------------------------ Assertion - Inversion ------------------------------
Checker.n = setmetatable({}, {
	__index = function(k, v)
		local f = Checker[k]
		return function(...)
			local args = {...}
			local succ, _ = pcall(f, ...)
			if succ then
				local msg = args[#args]
				Checker:_err(msg)
			end
		end
	end

})

------------------------------ Assertion - Type - Common ------------------------------
function Checker:isNil(obj, msg)
	if obj == nil then
		self:_log(nil, f("[%s] is {nil}.", obj))
		return true
	end
	return self:_err(msg, f("[%s] is NOT {nil}.", obj))
end

function Checker:isBoolean(obj, msg)
	if type(obj) == "boolean" then
		self:_log(nil, f("[%s] is a {boolean}.", obj))
		return true
	end
	return self:_err(msg, f("[%s] is NOT a {boolean}.", obj))
end

function Checker:isNumber(obj, msg)
	if type(obj) == "number" then
		self:_log(nil, f("[%s] is a {number}.", obj))
		return true
	end
	return self:_err(msg, f("[%s] is NOT a {number}.", obj))
end

function Checker:isString(obj, msg)
	if type(obj) == "string" then
		self:_log(nil, f("[%s] is a {string}.", obj))
		return true
	end
	return self:_err(msg, f("[%s] is NOT a {string}.", obj))
end

function Checker:isTable(obj, msg)
	if type(obj) == "table" then
		self:_log(nil, f("[%s] is a {table}.", obj))
		return true
	end
	return self:_err(msg, f("[%s] is NOT a {table}.", obj))
end

function Checker:isFunction(obj, msg)
	if type(obj) == "function" then
		self:_log(nil, f("[%s] is a {function}.", obj))
		return true
	end
	return self:_err(msg, f("[%s] is NOT a {function}.", obj))
end

------------------------------ Assertion - Type - Technical ------------------------------
function Checker:isThread(obj, msg)
	print("[WARN]: WIP, this method is untested.")
	if type(obj) == "thread" then
		self:_log(nil, f("[%s] is a {thread}.", obj))
		return true
	end
	return self:_err(msg, f("[%s] is NOT a {thread}.", obj))
end

function Checker:isUserdata(obj, msg)
	print("[WARN]: WIP, this method is untested.")
	if type(obj) == "userdata" then
		self:_log(nil, f("[%s] is {userdata}.", obj))
		return true
	end
	return self:_err(msg, f("[%s] is NOT {userdata}.", obj))
end

------------------------------ Assertion - Type & Value ------------------------------
---If for whatever reason the above "type" accessors are not enough for you.
function Checker:isType(obj, typ, msg)
	if type(obj) == typ then
		self:_log(nil, f("[%s] is of type [%s].", obj, typ))
		return true
	end
	return self:_err(msg, f("[%s] is NOT of type [%s].", obj, typ))
end

function Checker:isTypeOf(obj, types, msg)
	for k, v in pairs(types) do
		if type(obj) == v then
			self:_log(nil, f("[%s] is one of types [%s].", obj, types))
			return true
		end
	end
	return self:_err(msg, f("[%s] is NOT any of types [%s].", obj, types))
end

function Checker:isValue(obj, val, msg)
	if type(obj) == type(val) and obj == val then
		self:_log(nil, f("[%s] == [%s].", obj, val))
		return true
	end
	return self:_err(msg, f("[%s] ~= [%s].", obj, val))
end

function Checker:isValueOf(obj, vals, msg)
	for k, v in pairs(vals) do
		if type(obj) == type(v) and obj == v then
			self:_log(nil, f("[%s] equals one of [%s].", obj, vals))
			return true
		end
	end
	return self:_err(msg, f("[%s] equals none of [%s].", obj, vals))
end

------------------------------ Assertion - Nil-esc ------------------------------

------------------------------ Assertion - Bool-esc ------------------------------
--- False / True
function Checker:isFalse(obj, msg)
	if obj == false then
		self:_log(nil, f("[%s] == {false}.", obj))
		return true
	end
	return self:_err(msg, f("[%s] ~= {false}.", obj))
end

function Checker:isTrue(obj, msg)
	if obj == true then
		self:_log(nil, f("[%s] == {true}.", obj))
		return true
	end
	return self:_err(msg, f("[%s] ~= {true}.", obj))
end

--- Falsey / Truthy
function Checker:isFalsey(obj, msg)
	if not obj then
		self:_log(nil, f("[%s] is {falsey}.", obj))
		return true
	end
	return self:_err(msg, f("[%s] is NOT {falsey}.", obj))
end

function Checker:isTruthy(obj, msg)
	if obj then
		self:_log(nil, f("[%s] is {truthy}.", obj))
		return true
	end
	return self:_err(msg, f("[%s] is NOT {truthy}.", obj))
end

------------------------------ Assertion - Number-esc ------------------------------
function Checker:isGreater(obj, val, msg)
	if type(obj) ~= 'number' or type(val) ~= 'number' then 
		return self:err(msg, f("[%s] is NOT a number. Can't compare to [%s].", obj, val))
	end
	
	if obj > val then
		self:_log(nil, f("[%s] > [%s].", obj, val))
		return true
	end
	return self:err(msg, f("[%s] !> [%s].", obj, val))
end

function Checker:isLesser(obj, val, msg)
	if type(obj) ~= 'number' or type(val) ~= 'number' then
		return self:err(msg, f("[%s] is NOT a number. Can't compare to [%s].", obj, val))
	end
	
	if obj < val then
		self:_log(nil, f("[%s] < [%s].", obj, val))
		return true
	end
	return self:err(msg, f("[%s] !< [%s].", obj, val))
end

-- Checker:isPositive(0) -> Fails!
function Checker:isPositive(obj, msg)
	if type(obj) ~= 'number' then
		return self:err(msg, f("[%s] is NOT a number. Can't check for sign.", obj))
	end
	
	if obj > 0 then
		self:_log(nil, f("[%s] is positive.", obj))
		return true
	end
	return self:err(msg, f("[%s] is NOT positive.", obj))
end

-- Checker:isNegative(0) -> Fails!
function Checker:isNegative(obj, msg)
	if type(obj) ~= 'number' then
		return self:err(msg, f("[%s] is NOT a number. Can't check for sign.", obj))
	end
	
	if obj < 0 then
		self:_log(nil, f("[%s] is negative.", obj))
		return true
	end
	return self:err(msg, f("[%s] is NOT negative.", obj))
end

function Checker:isInteger(obj, msg)
	if type(obj) ~= 'number' then
		return self:err(msg, f("[%s] is NOT a number. Can't check for decimal-part.", obj))
	end
	
	if math.floor(obj) == obj then
		self:_log(nil, f("[%s] is an integer.", obj))
		return true
	end
	return self:err(msg, f("[%s] is NOT an integer.", obj))
end

------------------------------ Assertion - String-esc ------------------------------

------------------------------ Assertion - Table-esc ------------------------------
function Checker:isHashmap(t, msg)
	if type(t) ~= 'table' then
		return self:err(msg, f("[%s] is NOT a table, thus, NOT a {hashmap}.", t))			
	end
	if tableIsEmpty(t) then
		return self:err(msg, f("[%s] is empty, thus, does NOT qualify as a {hashmap}.", t))			
	end
	
	for k, v in pairs(t) do
		if type(k) == 'number' then
			return self:err(msg, f("[%s] is NOT a {hashmap}.", t))			
		end
	end
	self:_log(nil, f("[%s] is a {hashmap}.", t))
	return true	
end

function Checker:isArray(t, msg)
	if type(t) ~= 'table' then
		return self:err(msg, f("[%s] is NOT a table, thus, NOT an {array}.", t))			
	end
	if tableIsEmpty(t) then
		return self:err(msg, f("[%s] is empty, thus, does NOT qualify as an {array}.", t))			
	end
		
	for k, v in pairs(t) do
		if type(k) ~= 'number' then
			return self:err(msg, f("[%s] is NOT an {array}.", t))			
		end
	end
	self:_log(nil, f("[%s] is an {array}.", t))
	return true
end

function Checker:hasHashmap(t, msg)
	if type(t) ~= 'table' then
		return self:err(msg, f("[%s] is NOT a table, thus, does NOT contain a {hashmap}.", t))			
	end
	if tableIsEmpty(t) then
		return self:err(msg, f("[%s] is empty, thus, does NOT contain a {hashmap}.", t))			
	end
	
	local found = false
	for k, v in pairs(t) do
		if type(k) ~= 'number' then
			found = true			
			break
		end
	end
	self:_log(nil, f("[%s] contains a {hashmap}.", t))
	return true	
end

function Checker:hasArray(t, msg)
	if type(t) ~= 'table' then
		return self:err(msg, f("[%s] is NOT a table, thus, does NOT contain an {array}.", t))			
	end
	if tableIsEmpty(t) then
		return self:err(msg, f("[%s] is empty, thus does NOT contain an {array}.", t))			
	end
	
	local found = false
	for k, v in pairs(t) do
		if type(k) == 'number' then
			found = true			
			break
		end
	end
	self:_log(nil, f("[%s] contains an {array}.", t))
	return true	
end

------------------------------ Assertion - Function-esc ------------------------------

------------------------------ Assertion - Thread-esc ------------------------------

------------------------------ Assertion - Userdata-esc ------------------------------


return Checker
-- nil, bool, num, string, table, func, thread, userdata,

