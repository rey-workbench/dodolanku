@echo off
setlocal enabledelayedexpansion
REM ====================================================
REM Skrip Auto-Release & Tag untuk YourCashier
REM ====================================================

echo.
echo ====================================================
echo   YourCashier - Automated Release & Tag Utility
echo ====================================================
echo.

REM 1. Cek Git
git --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Git tidak ditemukan di PATH.
    pause
    exit /b 1
)

REM 2. Baca versi dari pubspec.yaml
if not exist pubspec.yaml (
    echo [ERROR] pubspec.yaml tidak ditemukan di direktori saat ini.
    pause
    exit /b 1
)

for /f "tokens=2" %%i in ('findstr "^version: " pubspec.yaml') do set FULL_VERSION=%%i
for /f "tokens=1 delims=+" %%i in ("%FULL_VERSION%") do set VERSION=%%i

if "%VERSION%"=="" (
    echo [ERROR] Gagal membaca versi dari pubspec.yaml.
    pause
    exit /b 1
)

REM 3. Deteksi branch git aktif
for /f "tokens=*" %%i in ('git branch --show-current 2^>nul') do set CURRENT_BRANCH=%%i
if "%CURRENT_BRANCH%"=="" set CURRENT_BRANCH=main

echo Version Target : v%VERSION% (Full: %FULL_VERSION%)
echo Target Branch  : %CURRENT_BRANCH%
echo ----------------------------------------------------
echo.

REM 4. Cek apakah Tag sudah pernah dibuat sebelumnya
git tag -l "v%VERSION%" | findstr "^v%VERSION%$" >nul 2>&1
if not errorlevel 1 (
    echo [WARNING] Tag v%VERSION% sudah ada di repositori lokal!
    set /p ovr="Apakah Anda ingin menghapus dan menimpa tag ini? (y/N): "
    if /i "!ovr!"=="y" (
        git tag -d "v%VERSION%" >nul 2>&1
        echo Tag lama lokal dihapus.
    ) else (
        echo Proses dibatalkan. Naikkan versi di pubspec.yaml terlebih dahulu.
        pause
        exit /b 1
    )
)

REM 5. Pre-flight Check: Flutter Analyze
set /p run_lint="Jalankan flutter analyze sebelum release? (Y/n): "
if /i not "%run_lint%"=="n" (
    echo.
    echo [1/5] Menjalankan flutter analyze...
    call flutter analyze
    if errorlevel 1 (
        echo.
        echo [ERROR] Terdapat issue pada flutter analyze!
        echo Perbaiki error sebelum melakukan release.
        pause
        exit /b 1
    )
    echo [OK] Analisis selesai tanpa issue.
)

REM 6. Input Pesan Commit
echo.
set /p msg="Masukkan pesan commit (default: 'Release v%VERSION%'): "
if "%msg%"=="" set msg=Release v%VERSION%

REM 7. Konfirmasi Final
echo.
echo ====================================================
echo   Siap melakukan release:
echo   - Versi   : v%VERSION%
echo   - Branch  : %CURRENT_BRANCH%
echo   - Pesan   : %msg%
echo ====================================================
set /p confirm="Lanjutkan push ke remote? (Y/n): "
if /i "%confirm%"=="n" (
    echo Release dibatalkan.
    exit /b 0
)

echo.
echo [2/5] Menyimpan perubahan ke Git (git add .)...
git add .

echo.
echo [3/5] Membuat Commit...
git commit -m "%msg%" >nul 2>&1
if errorlevel 1 (
    echo (Tidak ada perubahan baru untuk di-commit, melanjutkan ke tag...)
)

echo.
echo [4/5] Membuat Tag v%VERSION%...
git tag -a "v%VERSION%" -m "Release v%VERSION%"
if errorlevel 1 (
    echo [ERROR] Gagal membuat tag v%VERSION%.
    pause
    exit /b 1
)

echo.
echo [5/5] Mengirim (Push) ke remote (%CURRENT_BRANCH% & tag v%VERSION%)...
git push origin "%CURRENT_BRANCH%"
if errorlevel 1 (
    echo [ERROR] Gagal push branch %CURRENT_BRANCH% ke origin.
    pause
    exit /b 1
)

git push origin "v%VERSION%" --force
if errorlevel 1 (
    echo [ERROR] Gagal push tag v%VERSION% ke origin.
    pause
    exit /b 1
)

echo.
echo ====================================================
echo [SUKSES] Release v%VERSION% berhasil dikirim ke GitHub!
echo GitHub Actions akan otomatis mem-build APK Release.
echo ====================================================
echo.
pause

