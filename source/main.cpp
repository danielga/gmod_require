#include <GarrysMod/Lua/Interface.h>
#include <GarrysMod/Lua/LuaInterface.h>
#include <GarrysMod/Lua/LuaShared.h>
#include <GarrysMod/Interfaces.hpp>
#include <cstdint>

extern int32_t loadlib( lua_State *state );

static SourceSDK::FactoryLoader lua_shared_loader(
	"lua_shared", false, IS_SERVERSIDE, "garrysmod/bin/" );
static GarrysMod::Lua::ILuaShared *lua_shared = nullptr;

LUA_FUNCTION_STATIC( loadfile )
{
	const char *path = LUA->CheckString( 1 );

	auto lua = static_cast<GarrysMod::Lua::ILuaInterface *>( LUA );

	auto file = lua_shared->LoadFile( path, lua->GetPathID( ), lua->IsClient( ), true );
	if( file == nullptr )
	{
		LUA->PushBool( false );
		return 1;
	}

	const char *contents = file->contents.c_str( );
	LUA->PushBool( lua->RunStringEx( "", path, contents, false, false, false, false ) );
	LUA->Push( -2 );
	return 2;
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
