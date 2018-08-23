#include <GarrysMod/Lua/Interface.h>
#include <string>

extern char GoodSeparator;
extern char BadSeparator;

extern const char ParentDirectory[];
extern const char CurrentDirectory[];

extern const char RelativePathToBin[];
extern const char RelativePathToLibraries[];

std::string GetSystemError( );

bool IsWhitelistedExtension( const std::string &ext );

void *OpenLibrary( const char *path );

bool CloseLibrary( void *handle );

GarrysMod::Lua::CFunc FindFunction( void *handle, const char *name );

std::string GetFullPath( const std::string &path );
