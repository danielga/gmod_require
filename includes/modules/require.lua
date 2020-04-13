local no_errors, returned_value = pcall(require, "string")
if no_errors and returned_value == string then
	print("Default require() function seems to be working")
	return
else
	ErrorNoHalt("Ignore the above error about being unable to include string.lua, it means Garry is being an ass\n")
end

assert(type(package.preload) == "table", "package.preload is not a table?")

local io = {}
package.preload.io = function() return io end
package.preload.bit = function() return bit end
package.preload.timer = function() return timer end
package.preload.string = function() return string end
package.preload.math = function() return math end
package.preload.table = function() return table end
package.preload.jit = function() return jit end
package.preload["jit.opt"] = function() return jit.opt end
package.preload["jit.util"] = function() return jit.util end
package.preload.os = function() return os end
package.preload.package = function() return package end

require("require.core")

local loadlib = loadlib
local loadfile = loadfile

local is_windows = system.IsWindows()
local is_linux = system.IsLinux()
local is_osx = system.IsOSX()
local is_x64 = jit.arch == "x64"
local separator = is_windows and "\\" or "/"

local dll_prefix = CLIENT and "gmcl" or "gmsv"
local dll_suffix = assert(
	(is_windows and (is_x64 and "win64" or "win32")) or
	(is_linux and (is_x64 and "linux64" or "linux")) or
	(is_osx and (is_x64 and "osx64" or "osx"))
)
local libraries_extension = is_windows and "dll" or (is_linux and "so" or "dylib")

local function loadfilemodule(name, file_path)
	local value, errstr, reason = loadfile(file_path)
	if not value then
		if reason == "open_fail" then
			return "\n\tno file '" .. file_path .. "'"
		elseif reason == "load_fail" then
			error("error loading module '" .. name .. "' from file '" .. file_path .. "':\n\t" .. errstr, 4)
		end
	end

	return value, errstr
end

local function loadlibmodule(name, file_path, entrypoint_name, isgmodmodule)
	if not file.Exists("lua/" .. (isgmodmodule and "bin" or "libraries") .. "/" .. file_path, "MOD") then
		return "\n\tno file '" .. file_path .. "'"
	end

	local result, msg, reason = loadlib(is_windows and string.gsub(file_path, "/", separator) or file_path, entrypoint_name, isgmodmodule)
	if not result then
		assert(reason == "load_fail" or reason == "no_func", reason .. " (" .. #reason .. ")")
		if reason == "load_fail" then
			error("error loading module '" .. name .. "' from file '" .. file_path .. "':\n\t" .. msg, 4)
		elseif reason == "no_func" then
			return "\n\tno module '" .. name .. "' in file '" .. file_path .. "'"
		end
	end

	return result
end

-- Garry's Mod modules always have priority to Lua ones
package.loaders = {
	-- try to fetch the module from package.preload
	function(name)
		return package.preload[name] or "\n\tno field package.preload['" .. name .. "']"
	end,

	-- try to fetch the pure Lua module from lua/includes/modules ("à la" Garry's Mod)
	function(name)
		return loadfilemodule(name, "includes/modules/" .. name .. ".lua")
	end,

	-- try to fetch the pure Lua module from lua/libraries ("à la" Lua 5.1)
	function(name)
		return loadfilemodule(name, "libraries/" .. string.gsub(name, "%.", "/") .. ".lua")
	end,

	-- try to fetch the pure Lua module from lua/libraries/<name>/init.lua ("à la" Lua 5.1)
	function(name)
		return loadfilemodule(name, "libraries/" .. string.gsub(name, "%.", "/") .. "/init.lua")
	end,

	-- try to fetch the binary module from lua/bin ("à la" Garry's Mod)
	function(name)
		local file_path = dll_prefix .. "_" .. name .. "_" .. dll_suffix .. ".dll"
		local entrypoint_name = "gmod13_open"
		return loadlibmodule(name, file_path, entrypoint_name, true)
	end,

	-- try to fetch the binary module from lua/libraries ("à la" Lua 5.1)
	function(name)
		local file_path = string.gsub(name, "%.", "/") .. "." .. libraries_extension
		local entrypoint_name = "luaopen_" .. string.gsub(name, "%.", "_")
		return loadlibmodule(name, file_path, entrypoint_name, false)
	end,

	-- try to fetch the binary module from lua/libraries ("à la" Lua 5.1)
	function(name)
		local file_path = string.match(name, "^([^%.]*)") .. "." .. libraries_extension
		local entrypoint_name = "luaopen_" .. string.gsub(name, "%.", "_")
		return loadlibmodule(name, file_path, entrypoint_name, false)
	end
}

local sentinel
do
	local function errorHandler()
		error("require() sentinel can't be indexed or updated", 2)
	end

	sentinel = newproxy and newproxy() or setmetatable({}, {
		__index = errorHandler,
		__newindex = errorHandler,
		__metatable = false
	})
end

function require(name)
	assert(type(name) == "string", type(name))

	local loaded_val = package.loaded[name]
	if loaded_val == sentinel then
		error("loop or previous error loading module '" .. name .. "'", 2)
	elseif loaded_val ~= nil then
		return loaded_val
	elseif _MODULES[name] then
		return _G[name]
	end

	local messages = {""}
	local loader = nil
	local luapath = nil

	for _, searcher in ipairs(package.loaders) do
		local result, path = searcher(name)
		if type(result) == "function" then
			loader = result
			luapath = path
			break
		elseif type(result) == "string" then
			messages[#messages + 1] = result
		end
	end

	if not loader then
		error("module '" .. name .. "' not found: " .. table.concat(messages), 2)
	else
		package.loaded[name] = sentinel

		if luapath ~= nil then
			PushLuaPath(luapath)
		end

		local result = loader(name)

		if luapath ~= nil then
			PopLuaPath()
		end

		if result ~= nil then
			package.loaded[name] = result
		end

		if package.loaded[name] == sentinel then
			package.loaded[name] = true
		end

		return package.loaded[name]
	end
end
