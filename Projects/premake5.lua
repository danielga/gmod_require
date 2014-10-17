SDK_FOLDER = "E:/Programming/source-sdk-2013/mp/src"
GARRYSMOD_MODULE_BASE_FOLDER = "../gmod-module-base"
SOURCE_FOLDER = "../Source"
PROJECT_FOLDER = os.get() .. "/" .. _ACTION

solution("gm_loadfunc")
	language("C++")
	location(PROJECT_FOLDER)
	warnings("Extra")
	flags({"NoPCH", "StaticRuntime"})
	platforms({"x86"})
	configurations({"Release", "Debug"})

	filter("platforms:x86")
		architecture("x32")

	filter("configurations:Release")
		optimize("On")
		vectorextensions("SSE2")
		objdir(PROJECT_FOLDER .. "/Intermediate")
		targetdir(PROJECT_FOLDER .. "/Release")

	filter({"configurations:Debug"})
		flags({"Symbols"})
		objdir(PROJECT_FOLDER .. "/Intermediate")
		targetdir(PROJECT_FOLDER .. "/Debug")

	project("gmcl_loadfunc")
		kind("SharedLib")
		defines({"GMMODULE", "LOADFUNC_CLIENT", "CLIENT_DLL"})
		includedirs({
			SOURCE_FOLDER,
			GARRYSMOD_MODULE_BASE_FOLDER .. "/include",
			SDK_FOLDER .. "/public",
			SDK_FOLDER .. "/public/tier0"
		})
		files({SOURCE_FOLDER .. "/main.cpp", SDK_FOLDER .. "/public/tier0/memoverride.cpp"})
		vpaths({["Headers"] = SOURCE_FOLDER .. "/*.hpp", ["Sources"] = {SOURCE_FOLDER .. "/**.cpp", SDK_FOLDER .. "/**.cpp"}})
		links({"lua_shared", "tier0", "tier1"})

		targetprefix("")
		targetextension(".dll")

		filter({"system:windows"})
			defines({"SUPPRESS_INVALID_PARAMETER_NO_INFO"})
			files({SOURCE_FOLDER .. "/loader_win.cpp"})
			libdirs({GARRYSMOD_MODULE_BASE_FOLDER, SDK_FOLDER .. "/lib/public"})
			targetsuffix("_win32")

			filter({"system:windows", "configurations:Release"})
				linkoptions({"/NODEFAULTLIB:libcmtd.lib"})

			filter({"system:windows", "configurations:Debug"})
				linkoptions({"/NODEFAULTLIB:libcmt.lib"})

		filter("system:linux")
			files({SOURCE_FOLDER .. "/loader_pos.cpp"})
			libdirs({SDK_FOLDER .. "/lib/public/linux32"})
			targetsuffix("_linux")

		filter({"system:macosx"})
			files({SOURCE_FOLDER .. "/loader_pos.cpp"})
			libdirs({SDK_FOLDER .. "/lib/public/osx32"})
			targetsuffix("_mac")

	project("gmsv_loadfunc")
		kind("SharedLib")
		defines({"GMMODULE", "LOADFUNC_SERVER", "GAME_DLL"})
		includedirs({
			SOURCE_FOLDER,
			GARRYSMOD_MODULE_BASE_FOLDER .. "/include",
			SDK_FOLDER .. "/public",
			SDK_FOLDER .. "/public/tier0"
		})
		files({SOURCE_FOLDER .. "/main.cpp", SDK_FOLDER .. "/public/tier0/memoverride.cpp"})
		vpaths({["Headers"] = SOURCE_FOLDER .. "/*.hpp", ["Sources"] = {SOURCE_FOLDER .. "/**.cpp", SDK_FOLDER .. "/**.cpp"}})
		links({"lua_shared", "tier0", "tier1"})

		targetprefix("")
		targetextension(".dll")

		filter({"system:windows"})
			defines({"SUPPRESS_INVALID_PARAMETER_NO_INFO"})
			files({SOURCE_FOLDER .. "/loader_win.cpp"})
			libdirs({GARRYSMOD_MODULE_BASE_FOLDER, SDK_FOLDER .. "/lib/public"})
			targetsuffix("_win32")

			filter({"system:windows", "configurations:Release"})
				linkoptions({"/NODEFAULTLIB:libcmtd.lib"})

			filter({"system:windows", "configurations:Debug"})
				linkoptions({"/NODEFAULTLIB:libcmt.lib"})

		filter("system:linux")
			files({SOURCE_FOLDER .. "/loader_pos.cpp"})
			libdirs({SDK_FOLDER .. "/lib/public/linux32"})
			targetsuffix("_linux")

		filter({"system:macosx"})
			files({SOURCE_FOLDER .. "/loader_pos.cpp"})
			libdirs({SDK_FOLDER .. "/lib/public/osx32"})
			targetsuffix("_mac")