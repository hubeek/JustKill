@echo off
setlocal enabledelayedexpansion

echo Building jkill using direct native-image (bypassing Maven plugin)...

REM Check if source is in Maven structure
if not exist "src\main\java\nl\appall\jkill\Jkill.java" (
    echo Moving to Maven structure...
    mkdir src\main\java 2>nul
    if exist "nl\appall\jkill\Jkill.java" (
        move nl src\main\java\
        echo Moved nl\ to src\main\java\
    ) else (
        echo Error: Cannot find Jkill.java in expected locations
        exit /b 1
    )
)

REM Use Maven to compile and get dependencies
echo Using Maven to compile Java and resolve dependencies...
call mvn clean compile dependency:copy-dependencies

REM Check if compilation was successful
if not exist "target\classes\nl\appall\jkill\Jkill.class" (
    echo Error: Maven compilation failed.
    exit /b 1
)

echo Compilation successful. Checking dependencies...

REM Find the picocli dependency
set "PICOCLI_JAR="
for /f "delims=" %%i in ('dir /s /b target\dependency\picocli-*.jar') do (
    set "PICOCLI_JAR=%%i"
    goto :found_picocli
)

:found_picocli
if not defined PICOCLI_JAR (
    echo Error: picocli JAR not found in dependencies.
    echo Available JARs:
    dir target\dependency\*.jar
    exit /b 1
)

echo Using picocli JAR: %PICOCLI_JAR%

REM Check if native-image is available
where native-image >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: native-image command not found.
    echo Your JAVA_HOME: %JAVA_HOME%
    echo Please install native-image: gu install native-image
    exit /b 1
)

echo native-image version:
native-image --version

REM Test the JAR first
echo Testing JAR before building native image...
java -cp "target\classes;%PICOCLI_JAR%" nl.appall.jkill.Jkill --help

if %errorlevel% neq 0 (
    echo Error: JAR test failed. Cannot proceed with native-image.
    exit /b 1
)

echo JAR test successful. Building native executable...

REM Build native image with verbose output
native-image ^
    -cp "target\classes;%PICOCLI_JAR%" ^
    --no-fallback ^
    -H:Name=jkill ^
    -H:Class=nl.appall.jkill.Jkill ^
    -H:Path=target ^
    --verbose

REM Check if build was successful
if %errorlevel% neq 0 (
    echo Native image build failed. Trying without --no-fallback...
    native-image ^
        -cp "target\classes;%PICOCLI_JAR%" ^
        -H:Name=jkill ^
        -H:Class=nl.appall.jkill.Jkill ^
        -H:Path=target ^
        --verbose
)

REM Test the executable
if exist "target\jkill.exe" (
    echo Build successful! Testing executable...
    target\jkill.exe --help
    echo.
    echo Success! The executable is located at:
    echo   target\jkill.exe
    echo.
    echo You may want to add it to your PATH or copy it to a directory in your PATH.
) else (
    echo Error: Executable not created.
    exit /b 1
)

exit /b 0