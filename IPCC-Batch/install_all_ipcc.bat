@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Install IPCC Batch
cd /d "%~dp0"

set "TOOLS=%~dp0tools"
set "INST=%TOOLS%\ideviceinstaller.exe"
set "IDID=%TOOLS%\idevice_id.exe"
set "LOG=%~dp0install_log.txt"
set "PATH=%TOOLS%;%PATH%"

echo ============================================
echo   Install semua .ipcc di folder "ipcc"
echo ============================================
echo.

if not exist "%INST%" (
  echo [ERROR] tools\ideviceinstaller.exe tidak ditemukan.
  echo         Salin ideviceinstaller.exe + semua file .dll ke folder tools.
  goto :end
)

if not exist "ipcc\*.ipcc" (
  echo [ERROR] Tidak ada file .ipcc di folder ipcc.
  goto :end
)

rem --- Cek iPhone terhubung ---
set "UDID="
if exist "%IDID%" (
  for /f "tokens=1" %%U in ('call "%IDID%" -l 2^>nul') do if not defined UDID set "UDID=%%U"
  if not defined UDID (
    echo [ERROR] iPhone tidak terdeteksi.
    echo         - Sambungkan kabel, buka kunci layar, tekan "Trust/Percayai".
    echo         - Pastikan iTunes / Apple Devices / driver 3uTools terpasang.
    echo         - Tutup 3uTools dulu agar tidak berebut koneksi.
    goto :end
  )
  echo iPhone terdeteksi: !UDID!
  echo.
)

echo Log: %LOG%
echo ==== %DATE% %TIME% ==== >> "%LOG%"

set /a OK=0, FAIL=0, N=0
set "MODE="

for %%F in ("ipcc\*.ipcc") do (
  set /a N+=1
  echo [!N!] Memasang %%~nxF ...
  call :install "%%~fF"
  if !errorlevel! equ 0 (
    set /a OK+=1
    echo       BERHASIL
    echo [OK]   %%~nxF >> "%LOG%"
  ) else (
    set /a FAIL+=1
    echo       GAGAL - lihat install_log.txt
    echo [FAIL] %%~nxF >> "%LOG%"
  )
  rem jeda agar iPhone selesai memproses bundle
  timeout /t 3 /nobreak >nul
)

echo.
echo ============================================
echo   Selesai: !OK! berhasil, !FAIL! gagal, dari !N! file
echo ============================================
echo Restart iPhone, lalu cek Settings ^> General ^> About ^> Carrier
goto :end

rem ------------------------------------------------------------
rem Mendukung 2 versi ideviceinstaller:
rem   baru : ideviceinstaller install FILE.ipcc
rem   lama : ideviceinstaller -i FILE.ipcc
rem ------------------------------------------------------------
:install
if "%MODE%"=="old" goto :install_old
"%INST%" install "%~1" >> "%LOG%" 2>&1
if %errorlevel% equ 0 (set "MODE=new" & exit /b 0)
if "%MODE%"=="new" exit /b 1
:install_old
"%INST%" -i "%~1" >> "%LOG%" 2>&1
if %errorlevel% equ 0 (set "MODE=old" & exit /b 0)
exit /b 1

:end
echo.
pause
endlocal
