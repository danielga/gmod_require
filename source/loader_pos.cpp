#include <GarrysMod/Lua/Interface.h>
#include <string>
#include <cstdint>
#include <dlfcn.h>

#define GOOD_SEPARATOR '/'
#define BAD_SEPARATOR '\\'

#define PARENT_DIRECTORY "../"
#define CURRENT_DIRECTORY "./"

static int32_t PushSystemError( lua_State *state, const char *error )
{
	LUA->PushNil( );
	LUA->PushString( dlerror( ) );
	LUA->PushString( error );
	return 3;
}

static void SubstituteChar( std::string &path, char part, char sub )
{
	size_t pos = path.find( part );
	while( pos != path.npos )
	{
		path.erase( pos, 1 );
		path.insert( pos, 1, sub );
		pos = path.find( part, pos + 1 );
	}
}

static void RemovePart( std::string &path, const std::string &part )
{
	size_t len = part.size( ), pos = path.find( part );
	while( pos != path.npos )
	{
		path.erase( pos, len );
		pos = path.find( part, pos );
	}
}

static bool HasWhitelistedExtension( const std::string &path )
{
	size_t extstart = path.rfind( '.' );
	if( extstart != path.npos )
	{
		size_t lastslash = path.rfind( GOOD_SEPARATOR );
		if( lastslash != path.npos && lastslash > extstart )
			return false;

		std::string ext = path.substr( extstart + 1 );
		return ext == "dll" || ext == "so" || ext == "dylib";
	}

	return false;
}

LUA_FUNCTION( loadlib )
{
	LUA->CheckType( 1, GarrysMod::Lua::Type::STRING );
	LUA->CheckType( 2, GarrysMod::Lua::Type::STRING );
	LUA->CheckType( 3, GarrysMod::Lua::Type::BOOL );

	{
		std::string lib = LUA->GetString( 1 );

		SubstituteChar( lib, BAD_SEPARATOR, GOOD_SEPARATOR );

		RemovePart( lib, PARENT_DIRECTORY );
		RemovePart( lib, CURRENT_DIRECTORY );

		LUA->PushString( lib.c_str( ) );
	}

	const char *libpath = LUA->GetString( -1 );

	if( !HasWhitelistedExtension( libpath ) )
		LUA->ThrowError( "path provided has an unauthorized extension" );

	{
		std::string fullpath;
		if( LUA->GetBool( 3 ) )
			fullpath = "garrysmod/lua/bin/";
		else
			fullpath = "garrysmod/lua/libraries/";

		fullpath += libpath;

		LUA->PushString( fullpath.c_str( ) );
	}

	const char *fullpath = LUA->GetString( -1 );

	{
		std::string loadlib = "LOADLIB: ";
		loadlib += libpath;
		LUA->PushString( loadlib.c_str( ) );
	}

	LUA->Push( -1 );
	LUA->GetTable( GarrysMod::Lua::INDEX_REGISTRY );

	GarrysMod::Lua::CFunc func = nullptr;
	if( !LUA->IsType( -1, GarrysMod::Lua::Type::NIL ) )
	{
		void **libhandle = reinterpret_cast<void **>( LUA->GetUserdata( -1 ) );

		func = reinterpret_cast<GarrysMod::Lua::CFunc>( dlsym( *libhandle, LUA->GetString( 2 ) ) );
		if( func == nullptr )
			return PushSystemError( state, "no_func" );
	}
	else
	{
		void *handle = dlopen( fullpath, RTLD_LAZY | RTLD_LOCAL );
		if( handle == nullptr )
			return PushSystemError( state, "load_fail" );

		func = reinterpret_cast<GarrysMod::Lua::CFunc>( dlsym( handle, LUA->GetString( 2 ) ) );
		if( func == nullptr )
		{
			dlclose( handle );
			return PushSystemError( state, "no_func" );
		}

		LUA->Pop( 1 );

		void **libhandle = reinterpret_cast<void **>( LUA->NewUserdata( sizeof( void * ) ) );
		*libhandle = handle;

		LUA->GetField( GarrysMod::Lua::INDEX_REGISTRY, "_LOADLIB" );
		LUA->SetMetaTable( -2 );

		LUA->SetTable( GarrysMod::Lua::INDEX_REGISTRY );
	}

	LUA->PushCFunction( func );
	return 1;
}
