@echo off
echo ================================
echo  Book Review Application Setup
echo ================================
echo.
echo This script will compile and run the Book Review Application.
echo Please ensure you have Java 17 or higher installed.
echo.
pause

echo.
echo Step 1: Checking Java installation...
java -version
if errorlevel 1 (
    echo ERROR: Java is not installed or not found in PATH.
    echo Please install Java 17 or higher and ensure it's in your PATH.
    pause
    exit /b 1
)

echo.
echo Step 2: Compiling the application...
call mvnw.cmd clean compile -q
if errorlevel 1 (
    echo ERROR: Failed to compile the application.
    echo Please check the error messages above.
    pause
    exit /b 1
)

echo.
echo Step 3: Starting the Book Review Application...
echo The application will start on http://localhost:8080
echo Press Ctrl+C to stop the application.
echo.
call mvnw.cmd spring-boot:run
