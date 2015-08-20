#include <GarrysMod/Lua/Interface.h>
#include <cstdint>

extern int32_t loadlib( lua_State *state );

GMOD_MODULE_OPEN( )
{
	LUA->PushCFunction( loadlib );
	LUA->SetField( GarrysMod::Lua::INDEX_GLOBAL, "loadlib" );
	return 0;
}

GMOD_MODULE_CLOSE( )
{
	LUA->PushNil( );
	LUA->SetField( GarrysMod::Lua::INDEX_GLOBAL, "loadlib" );
	return 0;
}
