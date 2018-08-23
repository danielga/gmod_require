#include <GarrysMod/Lua/Interface.h>
#include <GarrysMod/Lua/LuaInterface.h>
#include <GarrysMod/Lua/LuaShared.h>
#include <GarrysMod/Interfaces.hpp>
#include <cstdint>
#include <cstring>
#include "loadlib.hpp"

static SourceSDK::FactoryLoader lua_shared_loader(
	"lua_shared", false, IS_SERVERSIDE, "garrysmod/bin/" );
static GarrysMod::Lua::ILuaShared *lua_shared = nullptr;

static int32_t PushError( GarrysMod::Lua::ILuaBase *LUA, int idxError, const char *reason )
{
	if( idxError < 0 )
		idxError -= 1;

	LUA->PushNil( );
	LUA->Push( idxError );
	LUA->PushString( reason );
	return 3;
}

static int32_t PushSystemError( GarrysMod::Lua::ILuaBase *LUA, const char *reason )
{
	LUA->PushString( GetSystemError( ).c_str( ) );
	return PushError( LUA, -1, reason );
}

static void SubstituteChar( std::string &path, char part, char sub )
{
	if( part == '\0' )
		return;

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
		size_t lastslash = path.rfind( GoodSeparator );
		if( lastslash != path.npos && lastslash > extstart )
			return false;

		std::string ext = path.substr( extstart + 1 );
		return IsWhitelistedExtension( ext );
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
		SubstituteChar( lib, BadSeparator, GoodSeparator );
		RemovePart( lib, CurrentDirectory );
		LUA->PushString( lib.c_str( ) );
	}

	const char *libpath = LUA->GetString( -1 );
	if( std::strstr( libpath, ParentDirectory ) != nullptr )
		LUA->ThrowError( "path provided has an unauthorized parent directory sequence" );

	if( !HasWhitelistedExtension( libpath ) )
		LUA->ThrowError( "path provided has an unauthorized extension" );

	{
		std::string relpath = LUA->GetBool( 3 ) ? RelativePathToBin : RelativePathToLibraries;
		relpath += libpath;
		LUA->PushString( GetFullPath( relpath ).c_str( ) );
	}

	const char *fullpath = LUA->GetString( -1 );

	LUA->PushFormattedString( "LOADLIB: %s", libpath );

	LUA->Push( -1 );
	LUA->GetTable( GarrysMod::Lua::INDEX_REGISTRY );

	GarrysMod::Lua::CFunc func = nullptr;
	if( !LUA->IsType( -1, GarrysMod::Lua::Type::NIL ) )
	{
		void **libhandle = LUA->GetUserType<void *>( -1, GarrysMod::Lua::Type::USERDATA );

		func = FindFunction( *libhandle, LUA->GetString( 2 ) );
		if( func == nullptr )
			return PushSystemError( LUA, "no_func" );
	}
	else
	{
		void *handle = OpenLibrary( fullpath );
		if( handle == nullptr )
			return PushSystemError( LUA, "load_fail" );

		func = FindFunction( handle, LUA->GetString( 2 ) );
		if( func == nullptr )
		{
			CloseLibrary( handle );
			return PushSystemError( LUA, "no_func" );
		}

		LUA->Pop( 1 );

		LUA->PushUserType( handle, GarrysMod::Lua::Type::USERDATA );

		LUA->GetField( GarrysMod::Lua::INDEX_REGISTRY, "_LOADLIB" );
		LUA->SetMetaTable( -2 );

		LUA->SetTable( GarrysMod::Lua::INDEX_REGISTRY );
	}

	LUA->PushCFunction( func );
	return 1;
}

LUA_FUNCTION_STATIC( loadfile )
{
	if( !LUA->IsType( 1, GarrysMod::Lua::Type::STRING ) )
		LUA->ThrowError(
			"This implementation of \"loadfile\" requires a filename to be provided!" );

	if( LUA->Top( ) >= 2 )
	{
		const char *mode = LUA->GetString( 2 );
		if( std::strchr( mode, 'b' ) != nullptr )
			LUA->ThrowError(
				"This implementation of \"loadfile\" doesn't accept binary Lua chunks!" );
	}

	const char *path = LUA->GetString( 1 );
	const bool hasenv = LUA->GetType( 3 ) > GarrysMod::Lua::Type::NIL;

	auto lua = static_cast<GarrysMod::Lua::ILuaInterface *>( LUA );

	auto file = lua_shared->LoadFile( path, lua->GetPathID( ), lua->IsClient( ), true );
	if( file == nullptr )
	{
		LUA->PushFormattedString( "cannot open %s: No such file or directory", path );
		return PushError( LUA, -1, "open_fail" );
	}

	const char *contents = file->contents.c_str( );
	if( !lua->RunStringEx( "", path, contents, false, false, false, false ) )
		return PushError( LUA, -1, "load_fail" );

	if( hasenv )
	{
		LUA->Push( 3 );
		LUA->SetFEnv( -2 );
	}

	return 1;
}

GMOD_MODULE_OPEN( )
{
	lua_shared =
		lua_shared_loader.GetInterface<GarrysMod::Lua::ILuaShared>( GMOD_LUASHARED_INTERFACE );
	if( lua_shared == nullptr )
		LUA->ThrowError( "unable to get ILuaShared!" );

	LUA->PushCFunction( loadlib );
	LUA->SetField( GarrysMod::Lua::INDEX_GLOBAL, "loadlib" );

	LUA->PushCFunction( loadfile );
	LUA->SetField( GarrysMod::Lua::INDEX_GLOBAL, "loadfile" );

	return 0;
}

GMOD_MODULE_CLOSE( )
{
	LUA->PushNil( );
	LUA->SetField( GarrysMod::Lua::INDEX_GLOBAL, "loadlib" );

	LUA->PushNil( );
	LUA->SetField( GarrysMod::Lua::INDEX_GLOBAL, "loadfile" );

	return 0;
}
