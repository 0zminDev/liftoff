#if defined(__WATCOMC__)
#define ASMCALL _cdecl
#elif defined(__clang__) || defined(__GNUC__)
#define ASMCALL __attribute__((cdecl))
#else
#define ASMCALL
#endif
