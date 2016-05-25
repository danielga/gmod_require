newoption({
	trigger = "gmcommon",
	description = "Sets the path to the garrysmod_common (https://github.com/danielga/garrysmod_common) directory",
	value = "path to garrysmod_common directory"
})

local gmcommon = _OPTIONS.gmcommon or os.getenv("GARRYSMOD_COMMON")
if gmcommon == nil then
	error("you didn't provide a path to your garrysmod_common (https://github.com/danielga/garrysmod_common) directory")
end

include(gmcommon)

CreateWorkspace({name = "loadlib"})
	CreateProject({serverside = true, manual_files = true})
		files("../source/main.cpp")

		filter("system:windows")
			files("../source/loader_win.cpp")

		filter("system:linux or macosx")
			files("../source/loader_pos.cpp")
			links("dl")

	CreateProject({serverside = false, manual_files = true})
		files("../source/main.cpp")

		filter("system:windows")
			files("../source/loader_win.cpp")

		filter("system:linux or macosx")
			files("../source/loader_pos.cpp")
			links("dl")
