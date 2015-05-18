#include <GarrysMod/Lua/Interface.h>

extern int loadlib( lua_State *state );

GMOD_MODULE_OPEN( )
{
	LUA->PushSpecial( GarrysMod::Lua::SPECIAL_GLOB );
	LUA->PushCFunction( loadlib );
	LUA->SetField( -2, "loadlib" );

	return 0;
}

GMOD_MODULE_CLOSE( )
{
	(void)state;
	return 0;
}