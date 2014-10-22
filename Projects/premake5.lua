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
		defines({"GMMODULE", "LOADFUNC_CLIENT"})
		includedirs({
			SOURCE_FOLDER,
			GARRYSMOD_MODULE_BASE_FOLDER .. "/include"
		})
		files({SOURCE_FOLDER .. "/main.cpp"})
		vpaths({["Headers"] = SOURCE_FOLDER .. "/*.hpp", ["Sources"] = SOURCE_FOLDER .. "/**.cpp"})

		targetprefix("")
		targetextension(".dll")

		filter("system:windows")
			files({SOURCE_FOLDER .. "/loader_win.cpp"})
			targetsuffix("_win32")

		filter("system:linux")
			files({SOURCE_FOLDER .. "/loader_pos.cpp"})
			targetsuffix("_linux")

		filter({"system:macosx"})
			files({SOURCE_FOLDER .. "/loader_pos.cpp"})
			targetsuffix("_mac")

	project("gmsv_loadfunc")
		kind("SharedLib")
		defines({"GMMODULE", "LOADFUNC_SERVER"})
		includedirs({
			SOURCE_FOLDER,
			GARRYSMOD_MODULE_BASE_FOLDER .. "/include"
		})
		files({SOURCE_FOLDER .. "/main.cpp"})
		vpaths({["Headers"] = SOURCE_FOLDER .. "/*.hpp", ["Sources"] = SOURCE_FOLDER .. "/**.cpp"})

		targetprefix("")
		targetextension(".dll")

		filter("system:windows")
			files({SOURCE_FOLDER .. "/loader_win.cpp"})
			targetsuffix("_win32")

		filter("system:linux")
			files({SOURCE_FOLDER .. "/loader_pos.cpp"})
			targetsuffix("_linux")

		filter({"system:macosx"})
			files({SOURCE_FOLDER .. "/loader_pos.cpp"})
			targetsuffix("_mac")