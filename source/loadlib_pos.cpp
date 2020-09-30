#include "loadlib.hpp"
#include <dlfcn.h>
#include <stdlib.h>
#include <cstring>
#include <linux/limits.h>

char GoodSeparator = '/';
char BadSeparator = '\0';

const char ParentDirectory[] = "../";
const char CurrentDirectory[] = "./";

const char RelativePathToBin[] = "garrysmod/lua/bin/";
const char RelativePathToLibraries[] = "garrysmod/lua/libraries/";

std::string GetSystemError( )
{
	const char *errstr = dlerror( );
	return errstr != nullptr ? errstr : "unknown system error";
}

bool IsWhitelistedExtension( const std::string &ext )
{
	return ext == "dll" || ext == "so" || ext == "dylib";
}

void *OpenLibrary( const char *path )
{
	return dlopen( path, RTLD_NOW );
}

bool CloseLibrary( void *handle )
{
	return dlclose( handle ) == 0;
}

GarrysMod::Lua::CFunc FindFunction( void *handle, const char *name )
{
	return reinterpret_cast<GarrysMod::Lua::CFunc>( dlsym( handle, name ) );
}

std::string GetFullPath( const std::string &path )
{
	std::string fullpath;
	fullpath.resize( PATH_MAX );
	if( realpath( path.c_str( ), &fullpath[0] ) != nullptr )
		fullpath.resize( std::strlen( fullpath.c_str( ) ) );
	else
		fullpath.clear( );

	return fullpath;
}
