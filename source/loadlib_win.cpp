#include "loadlib.hpp"
#include <windows.h>
#include <direct.h>

char GoodSeparator = '/';
char BadSeparator = '\0';

const char ParentDirectory[] = "../";
const char CurrentDirectory[] = "./";

const char RelativePathToBin[] = "garrysmod/lua/bin/";
const char RelativePathToLibraries[] = "garrysmod/lua/libraries/";

std::string GetSystemError( )
{
	char *temp = nullptr;
	std::string message;
	DWORD res = FormatMessage(
		FORMAT_MESSAGE_IGNORE_INSERTS | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER,
		nullptr,
		GetLastError( ),
		LANG_USER_DEFAULT,
		reinterpret_cast<char *>( &temp ),
		1,
		nullptr
	);
	if( res != 0 )
	{
		message = temp;
		LocalFree( temp );
	}
	else
		message = "unknown system error";

	return message;
}

bool IsWhitelistedExtension( const std::string &ext )
{
	return ext == "dll";
}

void *OpenLibrary( const char *path )
{
	return LoadLibrary( path );
}

bool CloseLibrary( void *handle )
{
	return FreeLibrary( reinterpret_cast<HMODULE>( handle ) );
}

GarrysMod::Lua::CFunc FindFunction( void *handle, const char *name )
{
	return reinterpret_cast<GarrysMod::Lua::CFunc>( GetProcAddress(
		reinterpret_cast<HMODULE>( handle ), name ) );
}

std::string GetFullPath( const std::string &path )
{
	std::string fullpath;
	DWORD size = MAX_PATH;
	fullpath.resize( size );
	DWORD len = GetFullPathName( path.c_str( ), size, &fullpath[0], nullptr );
	if( len == 0 )
		fullpath.clear( );
	else if( len >= size )
	{
		fullpath.resize( len - 1 );
		len = GetFullPathName( path.c_str( ), len, &fullpath[0], nullptr );
	}

	return fullpath;
}
