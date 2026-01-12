@echo off
echo Building Flutter web app...
flutter build web --release

if %errorlevel% neq 0 (
    echo Build failed!
    pause
    exit /b 1
)

echo Copying build to docs...
if exist docs rmdir /s /q docs
xcopy build\web docs /E /I /H /Y

echo Adding docs to git...
git add docs

echo Checking for changes...
git status --porcelain | findstr "docs/" >nul
if %errorlevel% neq 0 (
    echo No changes in docs folder.
    goto end
)

echo Committing docs...
git commit -m "Deploy to GitHub Pages - %date% %time%"

echo Pushing to GitHub...
git push origin master

echo Deployment completed successfully!
goto end

:end
echo Done.
pause