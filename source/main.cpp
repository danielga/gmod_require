#include <GarrysMod/Lua/Interface.h>
#include <GarrysMod/Lua/LuaInterface.h>
#include <GarrysMod/Lua/LuaShared.h>
#include <GarrysMod/Interfaces.hpp>
#include <cstdint>
#include <cstring>

extern int32_t loadlib( lua_State *state );

static SourceSDK::FactoryLoader lua_shared_loader(
	"lua_shared", false, IS_SERVERSIDE, "garrysmod/bin/" );
static GarrysMod::Lua::ILuaShared *lua_shared = nullptr;

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
		LUA->PushNil( );
		LUA->PushFormattedString( "cannot open %s: No such file or directory", path );
		return 2;
	}

	const char *contents = file->contents.c_str( );
	if( !lua->RunStringEx( "", path, contents, false, false, false, false ) )
	{
		LUA->PushNil( );
		LUA->Push( -2 );
		return 2;
	}

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
