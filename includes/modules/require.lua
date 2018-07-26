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

local iswindows = system.IsWindows()
local islinux = system.IsLinux()
local dll_prefix = CLIENT and "gmcl" or "gmsv"
local dll_suffix = iswindows and "win32" or (islinux and "linux" or "osx")
local dll_extension = iswindows and "dll" or (islinux and "so" or "dylib")

local function loadfilemodule(name, file_path)
	local success, value = loadfile(file_path)
	if success then
		return value
	end

	if value then
		error("error loading module '" .. name .. "' from file '" .. file_path .. "':\n\t" .. errstr, 4)
	end

	return "\n\tno file '" .. file_path .. "'"
end

local function loadlibmodule(name, file_path, entrypoint_name, isgmodmodule)
	local separator = iswindows and "\\" or "/"
	if not file.Exists("lua/" .. (isgmodmodule and "bin" or "libraries") .. "/" .. file_path, "MOD") then
		return "\n\tno file '" .. file_path .. "'"
	end

	local result, msg, reason = loadlib(iswindows and string.gsub(file_path, "/", separator) or file_path, entrypoint_name, isgmodmodule)
	if not result then
		assert(reason == "load_fail" or reason == "no_func", reason .. " (" .. #reason .. ")")
		if reason == "load_fail" then
			error("error loading module '" .. name .. "' from file '" .. file_path .. "':\n\t" .. msg, 4)
		elseif reason == "no_func" then
			return "\n\tno module '" .. name .. "' in file '" .. file_path .. "'"
		end
	end

	debug.setfenv(result, package)
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

	-- try to fetch the binary module from lua/bin ("à la" Garry's Mod)
	function(name)
		local file_path = dll_prefix .. "_" .. name .. "_" .. dll_suffix .. ".dll"
		local entrypoint_name = "gmod13_open"
		return loadlibmodule(name, file_path, entrypoint_name, true)
	end,

	-- try to fetch the binary module from lua/libraries ("à la" Lua 5.1)
	function(name)
		local file_path = string.gsub(name, "%.", "/") .. "." .. dll_extension
		local entrypoint_name = "luaopen_" .. string.gsub(name, "%.", "_")
		return loadlibmodule(name, file_path, entrypoint_name, false)
	end,

	-- try to fetch the binary module from lua/libraries ("à la" Lua 5.1)
	function(name)
		local file_path = string.match(name, "^([^%.]*)") .. "." .. dll_extension
		local entrypoint_name = "luaopen_" .. string.gsub(name, "%.", "_")
		return loadlibmodule(name, file_path, entrypoint_name, false)
	end
}

local _sentinel = "requiring"
local _registry = debug.getregistry()
function require(name)
	assert(type(name) == "string", type(name))

	local loaded_val = _registry._LOADED[name]
	if loaded_val == _sentinel then
		error("loop or previous error loading module '" .. name .."'", 2)
	elseif loaded_val ~= nil then
		return loaded_val
	end

	local messages = {""}
	local loader = nil

	for _, searcher in ipairs(package.loaders) do
		local result = searcher(name)
		if type(result) == "function" then
			loader = result
			break
		elseif type(result) == "string" then
			messages[#messages + 1] = result
		end
	end

	if not loader then
		error("module '" .. name .. "' not found: " .. table.concat(messages), 2)
	else
		_registry._LOADED[name] = _sentinel
		local result = loader(name)

		if result ~= nil then
			_registry._LOADED[name] = result
		end

		if _registry._LOADED[name] == _sentinel then
			_registry._LOADED[name] = true
		end

		return _registry._LOADED[name]
	end
end
