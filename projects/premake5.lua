newoption({
	trigger = "gmcommon",
	description = "Sets the path to the garrysmod_common (https://bitbucket.org/danielga/garrysmod_common) directory",
	value = "path to garrysmod_common dir"
})

local gmcommon = _OPTIONS.gmcommon or os.getenv("GARRYSMOD_COMMON")
if gmcommon == nil then
	error("you didn't provide a path to your garrysmod_common (https://bitbucket.org/danielga/garrysmod_common) directory")
end

include(gmcommon)

CreateSolution("loadlib")
	CreateProject(SERVERSIDE, SOURCES_MANUAL)
		AddFiles("main.cpp")

		SetFilter(FILTER_WINDOWS)
			AddFiles("loader_win.cpp")

		SetFilter(FILTER_LINUX, FILTER_MACOSX)
			AddFiles("loader_pos.cpp")
			links("dl")

	CreateProject(CLIENTSIDE, SOURCES_MANUAL)
		AddFiles("main.cpp")

		SetFilter(FILTER_WINDOWS)
			AddFiles("loader_win.cpp")

		SetFilter(FILTER_LINUX, FILTER_MACOSX)
			AddFiles("loader_pos.cpp")
			links("dl")
