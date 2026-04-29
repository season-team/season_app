# PowerShell script to get SHA-1 fingerprint for Firebase
# This script retrieves the SHA-1 fingerprint from the debug keystore

Write-Host "Getting SHA-1 fingerprint from debug keystore..." -ForegroundColor Cyan
Write-Host ""

$debugKeystore = "$env:USERPROFILE\.android\debug.keystore"

if (Test-Path $debugKeystore) {
    Write-Host "Debug keystore found at: $debugKeystore" -ForegroundColor Green
    Write-Host ""
    Write-Host "SHA-1 Fingerprint:" -ForegroundColor Yellow
    Write-Host "==================" -ForegroundColor Yellow
    
    keytool -list -v -keystore $debugKeystore -alias androiddebugkey -storepass android -keypass android | Select-String "SHA1:" | ForEach-Object {
        $sha1 = $_.Line.Trim()
        Write-Host $sha1 -ForegroundColor Green
        # Extract just the SHA-1 value
        $sha1Value = $sha1 -replace ".*SHA1:\s+", ""
        Write-Host ""
        Write-Host "SHA-1 Value (copy this to Firebase):" -ForegroundColor Cyan
        Write-Host $sha1Value -ForegroundColor White -BackgroundColor DarkGreen
    }
    
    Write-Host ""
    Write-Host "SHA-256 Fingerprint:" -ForegroundColor Yellow
    Write-Host "====================" -ForegroundColor Yellow
    keytool -list -v -keystore $debugKeystore -alias androiddebugkey -storepass android -keypass android | Select-String "SHA256:" | ForEach-Object {
        $sha256 = $_.Line.Trim()
        Write-Host $sha256 -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Instructions:" -ForegroundColor Cyan
    Write-Host "1. Go to Firebase Console: https://console.firebase.google.com/" -ForegroundColor White
    Write-Host "2. Select your project: season-9ede3" -ForegroundColor White
    Write-Host "3. Go to Project Settings > Your apps > Android app" -ForegroundColor White
    Write-Host "4. Click 'Add fingerprint' and paste the SHA-1 value above" -ForegroundColor White
    Write-Host "5. Download the new google-services.json file" -ForegroundColor White
    Write-Host "6. Replace android/app/google-services.json with the new file" -ForegroundColor White
} else {
    Write-Host "Debug keystore not found at: $debugKeystore" -ForegroundColor Red
    Write-Host "Please run 'flutter build apk --debug' first to generate the debug keystore." -ForegroundColor Yellow
}

