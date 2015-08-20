local no_errors, returned_value = pcall(require, "string")
if no_errors and returned_value == string then
	print("Default require() function seems to be working")
	return
else
	ErrorNoHalt("Ignore the above error about being unable to include string.lua, it means Garry is being an ass\n")
end

assert(type(package.preload) == "table", "package.preload is not a table?")

package.preload.timer = function() return timer end
package.preload.string = function() return string end
package.preload.math = function() return math end
package.preload.table = function() return table end
local io = {}
package.preload.io = function() return io end

require("loadlib")

local loadlib = loadlib
_G.loadlib = nil

local iswindows = system.IsWindows()
local islinux = system.IsLinux()
local dll_prefix = CLIENT and "gmcl" or "gmsv"
local dll_suffix = iswindows and "win32" or (islinux and "linux" or "mac")
local dll_extension = iswindows and "dll" or (islinux and "so" or "dylib")

local function loadluamodule(name, file_path)
	local src_file = file.Open(file_path, "r", "LUA")
	if not src_file then
		return string.format("\n\tno file '%s'", file_path)
	end

	local file_text = src_file:Read(src_file:Size())
	src_file:Close()

	local load_result = CompileString(file_text, file_path, false)
	if type(load_result) == "string" then
		error(
			string.format(
				"error loading module '%s' from file '%s':\n\t%s",
				name,
				file_path,
				load_result
			),
			4
		)
	end

	return load_result
end

local function loadlibmodule(name, file_path, entrypoint_name, isgmodmodule)
	local separator = iswindows and "\\" or "/"
	if not file.Exists(string.format("lua/%s/%s", isgmodmodule and "bin" or "libraries", file_path), "MOD") then
		return string.format("\n\tno file '%s'", file_path)
	end

	local result, msg, reason = loadlib(iswindows and string.gsub(file_path, "/", separator) or file_path, entrypoint_name, isgmodmodule)
	if not result then
		assert(reason == "load_fail" or reason == "no_func", string.format("%s (%u)", reason, #reason))
		if reason == "load_fail" then
			error(
				string.format(
					"error loading module '%s' from file '%s':\n\t%s",
					name,
					file_path,
					msg
				),
				4
			)
		elseif reason == "no_func" then
			return string.format("\n\tno module '%s' in file '%s'", name, file_path)
		end
	end

	debug.setfenv(result, package)
	return result
end

-- Garry's Mod modules always have priority to Lua ones
package.loaders = {
	-- try to fetch the module from package.preload
	function(name)
		return package.preload[name] or string.format("\n\tno field package.preload['%s']", name)
	end,

	-- try to fetch the pure Lua module from lua/includes/modules ("à la" Garry's Mod)
	function(name)
		return loadluamodule(name, string.format("includes/modules/%s.lua", name))
	end,

	-- try to fetch the pure Lua module from lua/libraries ("à la" Lua 5.1)
	function(name)
		return loadluamodule(name, string.format("libraries/%s.lua", string.gsub(name, "%.", "/")))
	end,

	-- try to fetch the binary module from lua/bin ("à la" Garry's Mod)
	function(name)
		local file_path = string.format("%s_%s_%s.dll", dll_prefix, name, dll_suffix)
		local entrypoint_name = "gmod13_open"
		return loadlibmodule(name, file_path, entrypoint_name, true)
	end,

	-- try to fetch the binary module from lua/libraries ("à la" Lua 5.1)
	function(name)
		local file_path = string.format("%s.%s", string.gsub(name, "%.", "/"), dll_extension)
		local entrypoint_name = string.format("luaopen_%s", string.gsub(name, "%.", "_"))
		return loadlibmodule(name, file_path, entrypoint_name, false)
	end,

	-- try to fetch the binary module from lua/libraries ("à la" Lua 5.1)
	function(name)
		local file_path = string.format("%s.%s", string.match(name, "^([^%.]*)"), dll_extension)
		local entrypoint_name = string.format("luaopen_%s", string.gsub(name, "%.", "_"))
		return loadlibmodule(name, file_path, entrypoint_name, false)
	end
}

local _sentinel = "requiring"
local _registry = debug.getregistry()
function require(name)
	assert(type(name) == "string", type(name))

	local loaded_val = _registry._LOADED[name]
	if loaded_val == _sentinel then
		error(string.format("loop or previous error loading module '%s'", name), 2)
	elseif loaded_val ~= nil then
		return loaded_val
	end

	local messages = {""}
	local loader = nil
	for i = 1, #package.loaders do
	    local result = package.loaders[i](name)
	    if type(result) == "function" then
	        loader = result
	        break
	    elseif type(result) == "string" then
	        messages[#messages + 1] = result
	    end
	end

	if not loader then
		error(string.format("module '%s' not found:%s", name, table.concat(messages)), 2)
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
