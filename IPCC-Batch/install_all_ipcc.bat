@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Install IPCC Batch
cd /d "%~dp0"

rem ================== PENGATURAN ==================
rem Repo sumber pembaruan .ipcc (GitHub Releases)
set "REPO=sulthannaf/ios-carrier-bundles"
rem 1 = cek ^& unduh pembaruan .ipcc otomatis sebelum install, 0 = tidak
set "AUTO_UPDATE=1"
rem Operator yang dipasang PALING AKHIR (operator SIM Anda), pisahkan spasi.
rem Contoh: set "PRIORITAS=Telkomsel_id"   Kosongkan jika tidak perlu.
set "PRIORITAS=Telkomsel_id Indosat_id XL_id Smartfren_id"
rem Jeda antar pemasangan (detik)
set "JEDA=2"
rem ================================================

set "TOOLS=%~dp0tools"
set "INST=%TOOLS%\ideviceinstaller.exe"
set "IDID=%TOOLS%\idevice_id.exe"
set "IPCCDIR=%~dp0ipcc"
set "LOG=%~dp0install_log.txt"
set "LIST=%TEMP%\ipcc_install_list.txt"
set "PATH=%TOOLS%;%PATH%"

echo ==================================================
echo   IPCC Batch Installer
echo ==================================================
echo.

if not exist "%INST%" (
  echo [ERROR] tools\ideviceinstaller.exe tidak ditemukan.
  goto :end
)

rem --- 1. Cek pembaruan .ipcc dari GitHub Releases ---
if "%AUTO_UPDATE%"=="1" (
  echo Mengecek pembaruan .ipcc dari github.com/%REPO% ...
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0update_ipcc.ps1" -Repo "%REPO%" -Dest "%IPCCDIR%"
  echo.
)
if exist "%IPCCDIR%\VERSION.txt" (
  set /p VER=<"%IPCCDIR%\VERSION.txt"
  echo Versi paket .ipcc: !VER!
)

if not exist "%IPCCDIR%\*.ipcc" (
  echo [ERROR] Tidak ada file .ipcc di folder ipcc.
  goto :end
)

rem --- 2. Cek iPhone terhubung ---
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
)

rem --- 3. Susun urutan: operator lain dulu, PRIORITAS paling akhir ---
set "PRI= %PRIORITAS% "
if exist "%LIST%" del /q "%LIST%"
for %%F in ("%IPCCDIR%\*.ipcc") do (
  call :is_prioritas "%%~nF"
  if "!ISPRI!"=="0" echo %%~fF>>"%LIST%"
)
for %%P in (%PRIORITAS%) do (
  for %%F in ("%IPCCDIR%\%%P.ipcc" "%IPCCDIR%\%%P_iOS*.ipcc") do if exist "%%~fF" echo %%~fF>>"%LIST%"
)

set /a TOTAL=0
for /f "usebackq delims=" %%L in ("%LIST%") do set /a TOTAL+=1
echo Akan memasang !TOTAL! file .ipcc (jeda %JEDA% detik per file).
if not "%PRIORITAS%"=="" echo Dipasang paling akhir: %PRIORITAS%
echo.
echo Tekan tombol apa saja untuk mulai, atau tutup jendela ini untuk batal.
pause >nul

echo ==== %DATE% %TIME% ==== >> "%LOG%"
set /a OK=0, FAIL=0, N=0
set "MODE="

rem --- 4. Pasang satu per satu ---
for /f "usebackq delims=" %%L in ("%LIST%") do (
  set /a N+=1
  <nul set /p "=[!N!/!TOTAL!] %%~nxL ... "
  call :install "%%L"
  if !errorlevel! equ 0 (
    set /a OK+=1
    echo OK
    echo [OK]   %%~nxL >> "%LOG%"
  ) else (
    set /a FAIL+=1
    echo GAGAL
    echo [FAIL] %%~nxL >> "%LOG%"
  )
  timeout /t %JEDA% /nobreak >nul
)
del /q "%LIST%" 2>nul

echo.
echo ==================================================
echo   Selesai: !OK! berhasil, !FAIL! gagal, dari !TOTAL! file
echo ==================================================
echo Detail: install_log.txt
echo Restart iPhone, lalu cek Settings ^> General ^> About ^> Carrier
goto :end

rem ------------------------------------------------------------
rem ISPRI=1 jika operator ada di PRIORITAS.
rem Nama dasar: "Telkomsel_id_iOS27.0.1" -> "Telkomsel_id"
:is_prioritas
set "BASE=%~1"
set "BASE=%BASE:_iOS=|%"
for /f "delims=|" %%B in ("%BASE%") do set "BASE=%%B"
set "ISPRI=0"
if not "!PRI: %BASE% =!"=="!PRI!" set "ISPRI=1"
exit /b 0

rem Mendukung ideviceinstaller lama (-i) dan baru (install)
:install
if "%MODE%"=="new" goto :install_new
"%INST%" -i "%~1" >> "%LOG%" 2>&1
if %errorlevel% equ 0 (set "MODE=old" & exit /b 0)
if "%MODE%"=="old" exit /b 1
:install_new
"%INST%" install "%~1" >> "%LOG%" 2>&1
if %errorlevel% equ 0 (set "MODE=new" & exit /b 0)
exit /b 1

:end
echo.
pause
endlocal
