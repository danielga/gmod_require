# gmod_require

Modules for Garry's Mod for obtaining pointers to functions inside of modules (specially useful for loading Lua only modules).

## Info

This project is composed by the Lua modules (in includes/modules) and the internal (binary) module (gm_require.core).
The Lua files go into lua/includes/modules (just copy includes from this repo onto lua) and the binary module goes into lua/bin.

Mac was not tested at all (sorry but I'm poor).

If stuff starts erroring or fails to work, be sure to check the correct line endings (\n and such) are present in the files for each OS.

This project requires [garrysmod_common][1], a framework to facilitate the creation of compilations files (Visual Studio, make, XCode, etc). Simply set the environment variable 'GARRYSMOD_COMMON' or the premake option 'gmcommon' to the path of your local copy of [garrysmod_common][1].

  [1]: https://github.com/danielga/garrysmod_common
