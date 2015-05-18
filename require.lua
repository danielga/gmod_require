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
		return ("\n\tno file '%s'"):format(file_path)
	end

	local file_text = src_file:Read(src_file:Size())
	src_file:Close()

	local load_result = CompileString(file_text, file_path, false)
	if type(load_result) == "string" then
		error(
			("error loading module '%s' from file '%s':\n\t%s"):format(
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
	if not file.Exists(("lua/%s/%s"):format(isgmodmodule and "bin" or "libraries", file_path), "MOD") then
		return ("\n\tno file '%s'"):format(file_path)
	end

	local result, msg, reason = loadlib(iswindows and file_path:gsub("/", separator) or file_path, entrypoint_name, isgmodmodule)
	if not result then
		assert(reason == "load_fail" or reason == "no_func", ("%s (%u)"):format(reason, #reason))
		if reason == "load_fail" then
			error(
				("error loading module '%s' from file '%s':\n\t%s"):format(
					name,
					file_path,
					msg
				),
				4
			)
		elseif reason == "no_func" then
			return ("\n\tno module '%s' in file '%s'"):format(name, file_path)
		end
	end

	debug.setfenv(result, package)
	return result
end

-- Garry's Mod modules always have priority to Lua ones
package.loaders = {
	-- try to fetch the module from package.preload
	function(name)
		return package.preload[name] or ("\n\tno field package.preload['%s']"):format(name)
	end,

	-- try to fetch the pure Lua module from lua/includes/modules ("à la" Garry's Mod)
	function(name)
		return loadluamodule(name, ("includes/modules/%s.lua"):format(name))
	end,

	-- try to fetch the pure Lua module from lua/libraries ("à la" Lua 5.1)
	function(name)
		return loadluamodule(name, ("libraries/%s.lua"):format(name:gsub("%.", "/")))
	end,

	-- try to fetch the binary module from lua/bin ("à la" Garry's Mod)
	function(name)
		local file_path = ("%s_%s_%s.dll"):format(dll_prefix, name, dll_suffix)
		local entrypoint_name = "gmod13_open"
		return loadlibmodule(name, file_path, entrypoint_name, true)
	end,

	-- try to fetch the binary module from lua/libraries ("à la" Lua 5.1)
	function(name)
		local file_path = ("%s.%s"):format(name:gsub("%.", "/"), dll_extension)
		local entrypoint_name = ("luaopen_%s"):format(name:gsub("%.", "_"))
		return loadlibmodule(name, file_path, entrypoint_name, false)
	end,

	-- try to fetch the binary module from lua/libraries ("à la" Lua 5.1)
	function(name)
		local file_path = ("%s.%s"):format(name:match("^([^%.]*)"), dll_extension)
		local entrypoint_name = ("luaopen_%s"):format(name:gsub("%.", "_"))
		return loadlibmodule(name, file_path, entrypoint_name, false)
	end
}

local _sentinel = "requiring"
local _registry = debug.getregistry()
function require(name)
	assert(type(name) == "string", type(name))

	local loaded_val = _registry._LOADED[name]
	if loaded_val == _sentinel then
		error(("loop or previous error loading module '%s'"):format(name), 2)
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
		error(("module '%s' not found:%s"):format(name, table.concat(messages)), 2)
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