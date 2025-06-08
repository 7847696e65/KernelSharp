@echo off

:: Adjust these paths to your actual system setup
set ILCPATH="C:\Users\TAMMY\.nuget\packages\runtime.win-x64.microsoft.dotnet.ilcompiler\7.0.0\tools"
set NTOSKRNLLIBPATH="C:\Program Files (x86)\Windows Kits\10\Lib\10.0.19041.0\km\x64\ntoskrnl.lib"

if not exist %ILCPATH%\ilc.exe (
  echo ILC not found at %ILCPATH%
  exit /B 1
)

del Program.ilexe >nul 2>&1
del Program.obj >nul 2>&1
del Program.exe >nul 2>&1
del Program.map >nul 2>&1
del Program.pdb >nul 2>&1

if "%1"=="clean" exit /B

:: Compile C# to .ilexe (IL)
csc.exe /nologo /debug:embedded /noconfig /nostdlib /runtimemetadataversion:v4.0.30319 ^
  Program.cs ^
  Util.cs ^
  NTImage.cs ^
  WDK.cs ^
  Runtime\InteropServices.cs ^
  Runtime\CompilerHelpers.cs ^
  Runtime\CompilerServices.cs ^
  Runtime\System.cs ^
  Runtime\Runtime.cs ^
  /out:Program.ilexe /langversion:latest /unsafe || goto Error

:: Convert IL to OBJ via NativeAOT (ILC)
%ILCPATH%\ilc.exe Program.ilexe -o Program.obj --systemmodule Program --map Program.map -O || goto Error

:: Link OBJ to SYS
link.exe %NTOSKRNLLIBPATH% /nologo /subsystem:native /DRIVER:WDM Program.obj /entry:DriverEntry /incremental:no /out:Driver.sys || goto Error

echo Build succeeded!
goto :EOF

:Error
echo Tool failed.
exit /B 1
