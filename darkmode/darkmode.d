module darkmode.darkmode;

version(Windows)
{
	extern(Windows) :

	private:
	import std.bitmanip;
	import core.sys.windows.windows, core.stdc.string, core.sys.windows.winnt, core.stdc.wchar_;

	alias HANDLE HTHEME;
	/+
	MIT License

	Copyright (c) 2018 Stephen Eckels

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
	+/
	struct _IMAGE_DELAYLOAD_DESCRIPTOR {
		union {
			DWORD AllAttributes;
			
			struct {
				mixin(bitfields!(
					DWORD, "RvaBased", 1,
					DWORD, "ReservedAttributes", 31));
				/*
				DWORD RvaBased : 1;             // Delay load version 2
				DWORD ReservedAttributes : 31;
				*/
			}
		}

		DWORD DllNameRVA;                       // RVA to the name of the target library (NULL-terminate ASCII string)
		DWORD ModuleHandleRVA;                  // RVA to the HMODULE caching location (PHMODULE)
		DWORD ImportAddressTableRVA;            // RVA to the start of the IAT (PIMAGE_THUNK_DATA)
		DWORD ImportNameTableRVA;               // RVA to the start of the name table (PIMAGE_THUNK_DATA::AddressOfData)
		DWORD BoundImportAddressTableRVA;       // RVA to an optional bound IAT
		DWORD UnloadInformationTableRVA;        // RVA to an optional unload info table
		DWORD TimeDateStamp;                    // 0 if not bound,
												// Otherwise, date/time of the target DLL

	}
	alias _IMAGE_DELAYLOAD_DESCRIPTOR* PIMAGE_DELAYLOAD_DESCRIPTOR;


	// This file contains code from
	// https://github.com/stevemk14ebr/PolyHook_2_0/blob/master/sources/IatHook.cpp
	// which is licensed under the MIT License.
	// See PolyHook_2_0-LICENSE for more information.

	//template <typename T, typename T1, typename T2>
	T RVA2VA(T, T1, T2)(T1 base, T2 rva)
	{
		return cast(T)(cast(ULONG_PTR)(base) + rva);
	}

	T DataDirectoryFromModuleBase(T)(void *moduleBase, size_t entryID)
	{
		auto dosHdr = cast(PIMAGE_DOS_HEADER)(moduleBase);
		auto ntHdr = RVA2VA!(PIMAGE_NT_HEADERS)(moduleBase, dosHdr.e_lfanew);
		auto dataDir = ntHdr.OptionalHeader.DataDirectory;
		return RVA2VA!(T)(moduleBase, dataDir[entryID].VirtualAddress);
	}

	PIMAGE_THUNK_DATA FindAddressByName(void *moduleBase, PIMAGE_THUNK_DATA impName, PIMAGE_THUNK_DATA impAddr, const char *funcName)
	{
		for (; impName.u1.Ordinal; ++impName, ++impAddr)
		{
			if (IMAGE_SNAP_BY_ORDINAL(impName.u1.Ordinal))
				continue;

			auto _import = RVA2VA!(PIMAGE_IMPORT_BY_NAME)(moduleBase, impName.u1.AddressOfData);
			if (strcmp(cast(char*)_import.Name, funcName) != 0)
				continue;
			return impAddr;
		}
		return null;
	}

	PIMAGE_THUNK_DATA FindAddressByOrdinal(void *moduleBase, PIMAGE_THUNK_DATA impName, PIMAGE_THUNK_DATA impAddr, ushort ordinal)
	{
		for (; impName.u1.Ordinal; ++impName, ++impAddr)
		{
			if (IMAGE_SNAP_BY_ORDINAL(impName.u1.Ordinal) && IMAGE_ORDINAL(impName.u1.Ordinal) == ordinal)
				return impAddr;
		}
		return null;
	}

	PIMAGE_THUNK_DATA FindIatThunkInModule(void *moduleBase, const char *dllName, const char *funcName)
	{
		auto imports = DataDirectoryFromModuleBase!(PIMAGE_IMPORT_DESCRIPTOR)(moduleBase, IMAGE_DIRECTORY_ENTRY_IMPORT);
		for (; imports.Name; ++imports)
		{
			if (lstrcmpiA(RVA2VA!(LPCSTR)(moduleBase, imports.Name), dllName) != 0)
				continue;

			auto origThunk = RVA2VA!(PIMAGE_THUNK_DATA)(moduleBase, imports.OriginalFirstThunk);
			auto thunk = RVA2VA!(PIMAGE_THUNK_DATA)(moduleBase, imports.FirstThunk);
			return FindAddressByName(moduleBase, origThunk, thunk, funcName);
		}
		return null;
	}
	/+
	PIMAGE_THUNK_DATA FindDelayLoadThunkInModule(void *moduleBase, const char *dllName, const char *funcName)
	{
		auto imports = DataDirectoryFromModuleBase!(PIMAGE_DELAYLOAD_DESCRIPTOR)(moduleBase, IMAGE_DIRECTORY_ENTRY_DELAY_IMPORT);
		for (; imports.DllNameRVA; ++imports)
		{
			if (lstrcmpiA(RVA2VA!(LPCSTR)(moduleBase, imports.DllNameRVA), dllName) != 0)
				continue;

			auto impName = RVA2VA!(PIMAGE_THUNK_DATA)(moduleBase, imports.ImportNameTableRVA);
			auto impAddr = RVA2VA!(PIMAGE_THUNK_DATA)(moduleBase, imports.ImportAddressTableRVA);
			return FindAddressByName(moduleBase, impName, impAddr, funcName);
		}
		return null;
	}
	+/
	PIMAGE_THUNK_DATA FindDelayLoadThunkInModule(void *moduleBase, const char *dllName, ushort ordinal)
	{
		auto imports = DataDirectoryFromModuleBase!(PIMAGE_DELAYLOAD_DESCRIPTOR)(moduleBase, IMAGE_DIRECTORY_ENTRY_DELAY_IMPORT);
		for (; imports.DllNameRVA; ++imports)
		{
			auto _s= RVA2VA!(LPCSTR)(moduleBase, imports.DllNameRVA);

			if (lstrcmpiA(RVA2VA!(LPCSTR)(moduleBase, imports.DllNameRVA), dllName) != 0)
				continue;
			auto impName = RVA2VA!(PIMAGE_THUNK_DATA)(moduleBase, imports.ImportNameTableRVA);
			auto impAddr = RVA2VA!(PIMAGE_THUNK_DATA)(moduleBase, imports.ImportAddressTableRVA);
			return FindAddressByOrdinal(moduleBase, impName, impAddr, ordinal);
		}
		return null;
	}

	/+
	MIT License

	Copyright (c) 2019 Richard Yu

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
	+/
	enum IMMERSIVE_HC_CACHE_MODE
	{
		IHCM_USE_CACHED_VALUE,
		IHCM_REFRESH
	}

	// 1903 18362
	enum PreferredAppMode
	{
		Default,
		AllowDark,
		ForceDark,
		ForceLight,
		Max
	}

	enum WINDOWCOMPOSITIONATTRIB
	{
		WCA_UNDEFINED = 0,
		WCA_NCRENDERING_ENABLED = 1,
		WCA_NCRENDERING_POLICY = 2,
		WCA_TRANSITIONS_FORCEDISABLED = 3,
		WCA_ALLOW_NCPAINT = 4,
		WCA_CAPTION_BUTTON_BOUNDS = 5,
		WCA_NONCLIENT_RTL_LAYOUT = 6,
		WCA_FORCE_ICONIC_REPRESENTATION = 7,
		WCA_EXTENDED_FRAME_BOUNDS = 8,
		WCA_HAS_ICONIC_BITMAP = 9,
		WCA_THEME_ATTRIBUTES = 10,
		WCA_NCRENDERING_EXILED = 11,
		WCA_NCADORNMENTINFO = 12,
		WCA_EXCLUDED_FROM_LIVEPREVIEW = 13,
		WCA_VIDEO_OVERLAY_ACTIVE = 14,
		WCA_FORCE_ACTIVEWINDOW_APPEARANCE = 15,
		WCA_DISALLOW_PEEK = 16,
		WCA_CLOAK = 17,
		WCA_CLOAKED = 18,
		WCA_ACCENT_POLICY = 19,
		WCA_FREEZE_REPRESENTATION = 20,
		WCA_EVER_UNCLOAKED = 21,
		WCA_VISUAL_OWNER = 22,
		WCA_HOLOGRAPHIC = 23,
		WCA_EXCLUDED_FROM_DDA = 24,
		WCA_PASSIVEUPDATEMODE = 25,
		WCA_USEDARKMODECOLORS = 26,
		WCA_LAST = 27
	}

	struct WINDOWCOMPOSITIONATTRIBDATA
	{
		WINDOWCOMPOSITIONATTRIB Attrib;
		PVOID pvData;
		SIZE_T cbData;
	}


	alias fnRtlGetNtVersionNumbers = void function(LPDWORD major, LPDWORD minor, LPDWORD build);
	alias fnSetWindowCompositionAttribute = BOOL function(HWND hWnd, WINDOWCOMPOSITIONATTRIBDATA*);
	// 1809 17763
	alias fnShouldAppsUseDarkMode = bool function(); // ordinal 132
	alias fnAllowDarkModeForWindow = bool function(HWND hWnd, bool allow); // ordinal 133
	alias fnAllowDarkModeForApp = bool function(bool allow); // ordinal 135, in 1809
	alias fnFlushMenuThemes = void function(); // ordinal 136
	alias fnRefreshImmersiveColorPolicyState = void function(); // ordinal 104
	alias fnIsDarkModeAllowedForWindow = bool function(HWND hWnd); // ordinal 137
	alias fnGetIsImmersiveColorUsingHighContrast = bool function(IMMERSIVE_HC_CACHE_MODE mode); // ordinal 106
	alias fnOpenNcThemeData = HTHEME function(HWND hWnd, LPCWSTR pszClassList); // ordinal 49
	// 1903 18362
	alias fnShouldSystemUseDarkMode = bool function(); // ordinal 138
	alias fnSetPreferredAppMode = PreferredAppMode function(PreferredAppMode appMode); // ordinal 135, in 1903
	alias fnIsDarkModeAllowedForApp = bool function(); // ordinal 139
	alias fnSetWindowTheme = HRESULT function(HWND hwnd,LPCWSTR pszSubAppName,LPCWSTR pszSubIdList);

	fnSetWindowCompositionAttribute _SetWindowCompositionAttribute = null;
	fnShouldAppsUseDarkMode _ShouldAppsUseDarkMode = null;
	fnAllowDarkModeForWindow _AllowDarkModeForWindow = null;
	fnAllowDarkModeForApp _AllowDarkModeForApp = null;
	fnFlushMenuThemes _FlushMenuThemes = null;
	fnRefreshImmersiveColorPolicyState _RefreshImmersiveColorPolicyState = null;
	fnIsDarkModeAllowedForWindow _IsDarkModeAllowedForWindow = null;
	fnGetIsImmersiveColorUsingHighContrast _GetIsImmersiveColorUsingHighContrast = null;
	fnOpenNcThemeData _OpenNcThemeData = null;
	// 1903 18362
	fnShouldSystemUseDarkMode _ShouldSystemUseDarkMode = null;
	fnSetPreferredAppMode _SetPreferredAppMode = null;
	
	bool g_darkModeSupported = false;
	bool g_darkModeEnabled = false;
	DWORD g_buildNumber = 0;

	bool AllowDarkModeForWindow(HWND hWnd, bool allow)
	{
		if (g_darkModeSupported)
			return _AllowDarkModeForWindow(hWnd, allow);
		return false;
	}

	bool IsHighContrast()
	{
		HIGHCONTRASTW highContrast;// = { sizeof(highContrast) };
		if (SystemParametersInfoW(SPI_GETHIGHCONTRAST, highContrast.sizeof, &highContrast, FALSE))
			return highContrast.dwFlags & HCF_HIGHCONTRASTON;
		return false;
	}

	void RefreshTitleBarThemeColor(HWND hWnd)
	{
		BOOL dark = FALSE;
		if (_IsDarkModeAllowedForWindow(hWnd) &&
			_ShouldAppsUseDarkMode() &&
			!IsHighContrast())
		{
			dark = TRUE;
		}
		if (g_buildNumber < 18362)
			SetPropW(hWnd, "UseImmersiveDarkModeColors", cast(HANDLE)(cast(INT_PTR)(dark)));
		else if (_SetWindowCompositionAttribute)
		{
			WINDOWCOMPOSITIONATTRIBDATA data;// = { WCA_USEDARKMODECOLORS, &dark, sizeof(dark) };
			_SetWindowCompositionAttribute(hWnd, &data);
		}
	}
	/+
	bool IsColorSchemeChangeMessage(LPARAM lParam)
	{
		bool _is = false;
		if (lParam && lstrcmpi(cast(LPCWCH)(lParam), "ImmersiveColorSet" ) == 0)
		{
			_RefreshImmersiveColorPolicyState();
			_is = true;
		}
		_GetIsImmersiveColorUsingHighContrast(IMMERSIVE_HC_CACHE_MODE.IHCM_REFRESH);
		return _is;
	}

	bool IsColorSchemeChangeMessage(UINT message, LPARAM lParam)
	{
		if (message == WM_SETTINGCHANGE)
			return IsColorSchemeChangeMessage(lParam);
		return false;
	}
	+/
	void AllowDarkModeForApp(bool allow)
	{
		if (_AllowDarkModeForApp)
			_AllowDarkModeForApp(allow);
		else if (_SetPreferredAppMode)
			_SetPreferredAppMode(allow ? PreferredAppMode.AllowDark : PreferredAppMode.Default);
	}

	void FixDarkScrollBar()
	{
		HMODULE hComctl = LoadLibraryExW("comctl32.dll", null, 0x00000800); // LOAD_LIBRARY_SEARCH_SYSTEM32 = 0x00000800
		if (hComctl)
		{
			auto addr = FindDelayLoadThunkInModule(hComctl, "uxtheme.dll", 49); // OpenNcThemeData
			if (addr)
			{
				DWORD oldProtect;
				if (VirtualProtect(addr, IMAGE_THUNK_DATA.sizeof, PAGE_READWRITE, &oldProtect))
				{
					addr.u1.Function = cast(ULONG_PTR) (cast(fnOpenNcThemeData) function(HWND hWnd, LPCWSTR classList)
					{
						if (wcscmp(classList, "ScrollBar") == 0)
						{
							hWnd = null;
							classList = "Explorer::ScrollBar";
						}
						return _OpenNcThemeData(hWnd, classList);
					});
					VirtualProtect(addr, IMAGE_THUNK_DATA.sizeof, oldProtect, &oldProtect);
				}
			}
		}
	}

	bool CheckBuildNumber(DWORD buildNumber)
	{
		return (buildNumber == 17763 || // 1809
			buildNumber == 18362 || // 1903
			buildNumber == 18363 || // 1909
			( buildNumber >= 19041 && buildNumber < 22000 ) ||
			buildNumber >= 22000 ); // 2004
	}


	public:
	fnSetWindowTheme SetWindowTheme = null;
	bool InitDarkMode()
	{
		import std.string, std.conv;
		
		auto RtlGetNtVersionNumbers = cast(fnRtlGetNtVersionNumbers)(GetProcAddress(GetModuleHandleW("ntdll.dll"), "RtlGetNtVersionNumbers"));
		if (RtlGetNtVersionNumbers)
		{
			DWORD major, minor;
			RtlGetNtVersionNumbers(&major, &minor, &g_buildNumber);
			g_buildNumber = g_buildNumber & 0xffff;
			if (major == 10 && minor == 0 && CheckBuildNumber(g_buildNumber))
			{
				HMODULE hUxtheme = LoadLibraryExW("uxtheme.dll", null, 0x00000800); // LOAD_LIBRARY_SEARCH_SYSTEM32 = 0x00000800
				if (hUxtheme)
				{
					_OpenNcThemeData = cast(fnOpenNcThemeData)(GetProcAddress(hUxtheme, MAKEINTRESOURCEA(49)));
					_RefreshImmersiveColorPolicyState = cast(fnRefreshImmersiveColorPolicyState)(GetProcAddress(hUxtheme, MAKEINTRESOURCEA(104)));
					_GetIsImmersiveColorUsingHighContrast = cast(fnGetIsImmersiveColorUsingHighContrast)(GetProcAddress(hUxtheme, MAKEINTRESOURCEA(106)));
					_ShouldAppsUseDarkMode = cast(fnShouldAppsUseDarkMode)(GetProcAddress(hUxtheme, MAKEINTRESOURCEA(132)));
					_AllowDarkModeForWindow = cast(fnAllowDarkModeForWindow)(GetProcAddress(hUxtheme, MAKEINTRESOURCEA(133)));
					SetWindowTheme = cast(fnSetWindowTheme)(GetProcAddress(hUxtheme, "SetWindowTheme"));
					auto ord135 = GetProcAddress(hUxtheme, MAKEINTRESOURCEA(135));
					if (g_buildNumber < 18362)
						_AllowDarkModeForApp = cast(fnAllowDarkModeForApp)(ord135);
					else
						_SetPreferredAppMode = cast(fnSetPreferredAppMode)(ord135);

					//_FlushMenuThemes = reinterpret_cast<fnFlushMenuThemes>(GetProcAddress(hUxtheme, MAKEINTRESOURCEA(136)));
					_IsDarkModeAllowedForWindow = cast(fnIsDarkModeAllowedForWindow)(GetProcAddress(hUxtheme, MAKEINTRESOURCEA(137)));

					_SetWindowCompositionAttribute = cast(fnSetWindowCompositionAttribute)(GetProcAddress(GetModuleHandleW("user32.dll"), "SetWindowCompositionAttribute"));

					if (_OpenNcThemeData &&
						_RefreshImmersiveColorPolicyState &&
						_ShouldAppsUseDarkMode &&
						_AllowDarkModeForWindow &&
						(_AllowDarkModeForApp || _SetPreferredAppMode) &&
						//_FlushMenuThemes &&
						_IsDarkModeAllowedForWindow)
					{
						g_darkModeSupported = true;

						AllowDarkModeForApp(true);
						_RefreshImmersiveColorPolicyState();

						g_darkModeEnabled = _ShouldAppsUseDarkMode() && !IsHighContrast();

						FixDarkScrollBar();
						
						return true;
					}
				}
			}
		}
		return false;
	}
}