local _MODULES = _MODULES
local package_loaded = package.loaded
local _R = debug.getregistry()
local _LOADLIB = _R._LOADLIB

local is_windows = system.IsWindows()
local is_linux = system.IsLinux()
local is_osx = system.IsOSX()
local is_x64 = jit.arch == "x64"
local separator = is_windows and "\\" or "/"

local dll_prefix = CLIENT and "gmcl" or "gmsv"
local dll_suffix = assert(
	(is_windows and (is_x64 and "win64" or "win32")) or
	(is_linux and (is_x64 and "linux64" or "linux")) or
	(is_osx and "osx")
)

local fmt = string.format(
	"^LOADLIB: .+%sgarrysmod%slua%sbin%s%s_%%s_%s.dll$",
	separator,
	separator,
	separator,
	separator,
	dll_prefix,
	dll_suffix
)

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
