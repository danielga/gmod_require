local _MODULES = _MODULES
local package_loaded = package.loaded
local _R = debug.getregistry()
local _LOADLIB = _R._LOADLIB

local prefix = SERVER and "gmsv" or "gmcl"
local suffix = system.IsWindows() and "win32" or (system.IsLinux() and "linux" or "macos")
local sep = system.IsWindows() and "\\" or "/"
local fmt = "^LOADLIB: .+" .. sep .. "garrysmod" .. sep .. "lua" .. sep .. "bin" .. sep .. prefix .. "_%s_" .. suffix .. ".dll$"

function unrequire(name)
	_MODULES[name] = nil
	package_loaded[name] = nil

	local loadlib = fmt:format(name)
	for name, mod in pairs(_R) do
		if type(name) == "string" and name:find(loadlib) then
			_LOADLIB.__gc(mod)
			_R[name] = nil
			break
		end
	end
end