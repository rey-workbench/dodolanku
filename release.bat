@echo off
REM ==========================================
REM Skrip Auto-Release & Tag untuk YourCashier
REM ==========================================

echo Membaca versi dari pubspec.yaml...
for /f "tokens=2" %%i in ('findstr "^version: " pubspec.yaml') do set FULL_VERSION=%%i

REM Mengambil hanya bagian versi (misal 1.0.0 dari 1.0.0+1)
for /f "tokens=1 delims=+" %%i in ("%FULL_VERSION%") do set VERSION=%%i

echo.
echo ------------------------------------------
echo Versi yang terdeteksi: v%VERSION%
echo ------------------------------------------
echo.

set /p msg="Masukkan pesan commit (kosongkan untuk default 'Release v%VERSION%'): "
if "%msg%"=="" set msg=Release v%VERSION%

echo.
echo Menyimpan perubahan ke Git (git add .)...
git add .

echo.
echo Membuat Commit...
git commit -m "%msg%"

echo.
echo Membuat Tag v%VERSION%...
git tag v%VERSION%

echo.
echo Mengirim (Push) commit ke branch main...
git push origin main

echo.
echo Mengirim (Push) Tag v%VERSION% ke GitHub...
git push origin v%VERSION%

echo.
echo ==========================================
echo SELESAI!
echo Tag v%VERSION% berhasil didorong ke GitHub.
echo GitHub Actions sekarang akan otomatis membuat Release dan mem-build APK-nya.
echo ==========================================
pause
