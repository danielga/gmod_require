# gmod\_require

Modules for Garry's Mod for obtaining pointers to functions inside of modules (specially useful for loading Lua only modules).  

## Compiling

The only supported compilation platform for this project on Windows is **Visual Studio 2017** on **release** mode.  
On Linux, everything should work fine as is, on **release** mode.  
For Mac OSX, any **Xcode (using the GCC compiler)** version *MIGHT* work as long as the **Mac OSX 10.7 SDK** is used, on **release** mode.  
These restrictions are not random; they exist because of ABI compatibility reasons.  
If stuff starts erroring or fails to work, be sure to check the correct line endings (\\n and such) are present in the files for each OS.  

## Requirements

This project requires [garrysmod\_common][1], a framework to facilitate the creation of compilations files (Visual Studio, make, XCode, etc). Simply set the environment variable '**GARRYSMOD\_COMMON**' or the premake option '**gmcommon**' to the path of your local copy of [garrysmod\_common][1].  

  [1]: https://github.com/danielga/garrysmod_common
