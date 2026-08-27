# ====================================================
# YourCashier - Automated Release & Tag Script (PowerShell)
# ====================================================

Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "   YourCashier - Automated Release & Tag Utility    " -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Cek pubspec.yaml
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "[ERROR] pubspec.yaml tidak ditemukan di direktori saat ini." -ForegroundColor Red
    Exit 1
}

# 2. Ambil versi
$pubspec = Get-Content "pubspec.yaml"
$versionLine = $pubspec | Where-Object { $_ -match "^version:\s*(.+)$" } | Select-Object -First 1
if ($versionLine -match "^version:\s*([^+]+)") {
    $version = $Matches[1].Trim()
} else {
    Write-Host "[ERROR] Gagal membaca versi dari pubspec.yaml." -ForegroundColor Red
    Exit 1
}

# 3. Ambil current branch
$branch = (git branch --show-current 2>$null).Trim()
if (-not $branch) { $branch = "main" }

Write-Host "Version Target : v$version" -ForegroundColor Green
Write-Host "Target Branch  : $branch" -ForegroundColor Green
Write-Host "----------------------------------------------------"
Write-Host ""

# 4. Cek apakah tag sudah ada
$existingTag = git tag -l "v$version"
if ($existingTag) {
    Write-Host "[WARNING] Tag v$version sudah ada di repositori lokal!" -ForegroundColor Yellow
    $ovr = Read-Host "Apakah Anda ingin menghapus dan menimpa tag ini? (y/N)"
    if ($ovr -eq "y" -or $ovr -eq "Y") {
        git tag -d "v$version" | Out-Null
        Write-Host "Tag lama lokal dihapus." -ForegroundColor Gray
    } else {
        Write-Host "Proses dibatalkan. Naikkan versi di pubspec.yaml terlebih dahulu." -ForegroundColor Yellow
        Exit 0
    }
}

# 5. Pre-flight Flutter Analyze
$runLint = Read-Host "Jalankan flutter analyze sebelum release? (Y/n)"
if ($runLint -ne "n" -and $runLint -ne "N") {
    Write-Host ""
    Write-Host "[1/5] Menjalankan flutter analyze..." -ForegroundColor Cyan
    flutter analyze
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "[ERROR] Terdapat issue pada flutter analyze! Perbaiki sebelum release." -ForegroundColor Red
        Exit 1
    }
    Write-Host "[OK] Analisis selesai tanpa issue." -ForegroundColor Green
}

# 6. Input Pesan Commit
Write-Host ""
$msg = Read-Host "Masukkan pesan commit (default: 'Release v$version')"
if (-not $msg) { $msg = "Release v$version" }

# 7. Konfirmasi Final
Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  Siap melakukan release:"
Write-Host "  - Versi   : v$version"
Write-Host "  - Branch  : $branch"
Write-Host "  - Pesan   : $msg"
Write-Host "====================================================" -ForegroundColor Cyan
$confirm = Read-Host "Lanjutkan push ke remote? (Y/n)"
if ($confirm -eq "n" -or $confirm -eq "N") {
    Write-Host "Release dibatalkan." -ForegroundColor Yellow
    Exit 0
}

Write-Host ""
Write-Host "[2/5] Menyimpan perubahan ke Git (git add .)..." -ForegroundColor Cyan
git add .

Write-Host "[3/5] Membuat Commit..." -ForegroundColor Cyan
git commit -m $msg 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "(Tidak ada perubahan baru untuk di-commit, melanjutkan ke tag...)" -ForegroundColor Gray
}

Write-Host "[4/5] Membuat Tag v$version..." -ForegroundColor Cyan
git tag -a "v$version" -m "Release v$version"
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Gagal membuat tag v$version." -ForegroundColor Red
    Exit 1
}

Write-Host "[5/5] Mengirim (Push) ke remote ($branch & tag v$version)..." -ForegroundColor Cyan
git push origin $branch
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Gagal push branch $branch ke origin." -ForegroundColor Red
    Exit 1
}

git push origin "v$version" --force
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Gagal push tag v$version ke origin." -ForegroundColor Red
    Exit 1
}

Write-Host ""
Write-Host "====================================================" -ForegroundColor Green
Write-Host "[SUKSES] Release v$version berhasil dikirim ke GitHub!" -ForegroundColor Green
Write-Host "GitHub Actions akan otomatis mem-build APK Release." -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Green
Write-Host ""
