#include <GarrysMod/Lua/Interface.h>

extern int loadfunc( lua_State *state );

GMOD_MODULE_OPEN( )
{
	LUA->PushSpecial( GarrysMod::Lua::SPECIAL_GLOB );
	LUA->PushCFunction( loadfunc );
	LUA->SetField( -2, "loadfunc" );

	return 0;
}

GMOD_MODULE_CLOSE( )
{
	(void)state;
	return 0;
}