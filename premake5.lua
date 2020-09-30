PROJECT_GENERATOR_VERSION = 2

newoption({
	trigger = "gmcommon",
	description = "Sets the path to the garrysmod_common (https://github.com/danielga/garrysmod_common) directory",
	value = "path to garrysmod_common directory"
})

local gmcommon = assert(_OPTIONS.gmcommon or os.getenv("GARRYSMOD_COMMON"),
	"you didn't provide a path to your garrysmod_common (https://github.com/danielga/garrysmod_common) directory")
include(gmcommon)

CreateWorkspace({name = "require.core", abi_compatible = true})
	CreateProject({serverside = true, manual_files = true})
		IncludeLuaShared()
		IncludeSDKCommon()
		IncludeSDKTier0()
		IncludeSDKTier1()

		files({"source/main.cpp", "source/loadlib.hpp"})

		filter("system:windows")
			files("source/loadlib_win.cpp")

		filter("system:linux or macosx")
			files("source/loadlib_pos.cpp")
			links("dl")

	CreateProject({serverside = false, manual_files = true})
		IncludeLuaShared()
		IncludeSDKCommon()
		IncludeSDKTier0()
		IncludeSDKTier1()

		files({"source/main.cpp", "source/loadlib.hpp"})

		filter("system:windows")
			files("source/loadlib_win.cpp")

		filter("system:linux or macosx")
			files("source/loadlib_pos.cpp")
			links("dl")
