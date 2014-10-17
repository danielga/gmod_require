#include <GarrysMod/Lua/Interface.h>
#include <dlfcn.h>
#include <stdio.h>

extern "C"
{
	#include <lua.h>
}

static int push_system_error( lua_State *state, const char *error )
{
	LUA->PushNil( );
	LUA->PushString( dlerror( ) );
	LUA->PushString( error );
	return 3;
}

LUA_FUNCTION( loadfunc )
{
	LUA->CheckType( 1, GarrysMod::Lua::Type::STRING );
	LUA->CheckType( 2, GarrysMod::Lua::Type::STRING );

	const char *libpath = lua_pushfstring( state, "garrysmod/lua/%s", LUA->GetString( 1 ) );

	LUA->PushSpecial( GarrysMod::Lua::SPECIAL_REG );
	lua_pushfstring( state, "LOADLIB: %s", libpath );
	LUA->Push( -1 );
	LUA->GetTable( -3 );

	GarrysMod::Lua::CFunc func = nullptr;
	if( !LUA->IsType( -1, GarrysMod::Lua::Type::NIL ) )
	{
		void **libhandle = reinterpret_cast<HMODULE *>( LUA->GetUserdata( -1 ) );

		func = reinterpret_cast<GarrysMod::Lua::CFunc>( dlsym( *libhandle, LUA->GetString( 2 ) ) );
		if( func == nullptr )
			return push_system_error( state, "no_func" );
	}
	else
	{
		void *handle = dlopen( libpath, RTLD_LAZY | RTLD_LOCAL );
		if( handle == nullptr )
			return push_system_error( state, "link_fail" );

		func = reinterpret_cast<GarrysMod::Lua::CFunc>( dlsym( handle, LUA->GetString( 2 ) ) );
		if( func == nullptr )
		{
			dlclose( handle );
			return push_system_error( state, "no_func" );
		}

		LUA->Pop( 1 );

		lua_pushfstring( state, "LOADLIB: %s", libpath );

		void **libhandle = reinterpret_cast<void **>( LUA->NewUserdata( sizeof( void * ) ) );
		*libhandle = handle;

		LUA->GetField( -3, "_LOADLIB" );
		LUA->SetMetaTable( -2 );

		LUA->SetTable( -3 );
	}

	LUA->PushCFunction( func );
	return 1;
}