Write-Host "Cleaning Flutter project..." -ForegroundColor Green
flutter clean

Write-Host "Getting dependencies..." -ForegroundColor Green  
flutter pub get

Write-Host "Starting Flutter app..." -ForegroundColor Green
flutter run
