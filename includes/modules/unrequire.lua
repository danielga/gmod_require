local _MODULES = _MODULES
local package_loaded = package.loaded
local _R = debug.getregistry()
local _LOADLIB = _R._LOADLIB

local prefix = SERVER and "gmsv" or "gmcl"
local suffix = system.IsWindows() and "win32" or (system.IsLinux() and "linux" or "macos")
local sep = system.IsWindows() and "\\" or "/"
local fmt = string.format("^LOADLIB: .+%sgarrysmod%slua%sbin%s%s_%%s_%s.dll$", sep, sep, sep, sep, prefix, suffix)

function unrequire(name)
	_MODULES[name] = nil
	package_loaded[name] = nil

	local loadlib = string.format(fmt, name)
	for name, mod in pairs(_R) do
		if type(name) == "string" and string.find(name, loadlib) then
			_LOADLIB.__gc(mod)
			_R[name] = nil
			break
		end
	end
end
