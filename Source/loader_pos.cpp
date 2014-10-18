#include <GarrysMod/Lua/Interface.h>
#include <dlfcn.h>

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
	LUA->CheckType( 3, GarrysMod::Lua::Type::BOOL );

	const char *libpath = LUA->GetString( 1 );
	const char *fullpath = nullptr;
	if( LUA->GetBool( 3 ) )
		fullpath = lua_pushfstring( state, "garrysmod/lua/bin/%s", libpath );
	else
		fullpath = lua_pushfstring( state, "garrysmod/lua/libraries/%s", libpath );

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
			return push_system_error( state, "load_fail" );

		func = reinterpret_cast<GarrysMod::Lua::CFunc>( dlsym( handle, LUA->GetString( 2 ) ) );
		if( func == nullptr )
		{
			dlclose( handle );
			return push_system_error( state, "no_func" );
		}

		LUA->Pop( 1 );

		void **libhandle = reinterpret_cast<void **>( LUA->NewUserdata( sizeof( void * ) ) );
		*libhandle = handle;

		LUA->GetField( -3, "_LOADLIB" );
		LUA->SetMetaTable( -2 );

		LUA->SetTable( -3 );
	}

	LUA->PushCFunction( func );
	return 1;
}