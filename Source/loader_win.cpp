#include <GarrysMod/Lua/Interface.h>
#include <stdio.h>
#include <tier1/strtools.h>
#include <windows.h>

extern "C"
{
	#include <lua.h>
}

static DLL_DIRECTORY_COOKIE dir_cookie = nullptr;

static int push_system_error( lua_State *state, const char *error )
{
	LUA->PushNil( );

	DWORD errid = GetLastError( );
	char *message = nullptr;

	DWORD res = FormatMessage(
		FORMAT_MESSAGE_IGNORE_INSERTS | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER,
		nullptr,
		errid,
		LANG_USER_DEFAULT,
		reinterpret_cast<char *>( &message ),
		1,
		nullptr
	);
	if( res != 0 )
	{
		LUA->PushString( message, res );
		LocalFree( message );
	}
	else
	{
		lua_pushfstring( state, "system error 0x%08X\n", errid );
	}

	LUA->PushString( error );

	return 3;
}

LUA_FUNCTION( loadfunc )
{
	LUA->CheckType( 1, GarrysMod::Lua::Type::STRING );
	LUA->CheckType( 2, GarrysMod::Lua::Type::STRING );

	const char *libpath = lua_pushfstring( state, "garrysmod\\lua\\%s", LUA->GetString( 1 ) );

	LUA->PushSpecial( GarrysMod::Lua::SPECIAL_REG );
	lua_pushfstring( state, "LOADLIB: %s", libpath );
	LUA->Push( -1 );
	LUA->GetTable( -3 );

	GarrysMod::Lua::CFunc func = nullptr;
	if( !LUA->IsType( -1, GarrysMod::Lua::Type::NIL ) )
	{
		HMODULE *libhandle = reinterpret_cast<HMODULE *>( LUA->GetUserdata( -1 ) );

		func = reinterpret_cast<GarrysMod::Lua::CFunc>( GetProcAddress( *libhandle, LUA->GetString( 2 ) ) );
		if( func == nullptr )
			return push_system_error( state, "no_func" );
	}
	else
	{
		HMODULE handle = LoadLibrary( libpath );
		if( handle == nullptr )
			return push_system_error( state, "link_fail" );

		func = reinterpret_cast<GarrysMod::Lua::CFunc>( GetProcAddress( handle, LUA->GetString( 2 ) ) );
		if( func == nullptr )
		{
			FreeLibrary( handle );
			return push_system_error( state, "no_func" );
		}

		LUA->Pop( 1 );

		HMODULE *libhandle = reinterpret_cast<HMODULE *>( LUA->NewUserdata( sizeof( HMODULE ) ) );
		*libhandle = handle;

		LUA->GetField( -3, "_LOADLIB" );
		LUA->SetMetaTable( -2 );

		LUA->SetTable( -3 );
	}

	LUA->PushCFunction( func );
	return 1;
}