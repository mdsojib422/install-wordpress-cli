@echo off
REM Batch script to install WordPress on localhost with user input for project name and other details

REM -------------------------------------
REM Step 1: Prompt User for Input
REM -------------------------------------

echo ==================================================
echo        WordPress Installation Setup
echo ==================================================

SET MYSQL_BIN="C:\Program Files\Ampps\mysql\bin\mysql.exe"

REM Prompt for Project Name
echo.
echo Please enter your project name (e.g., wordpress, mysite):
set /p PROJECT_NAME=Project Name: 

REM Validate Project Name (optional)
if "%PROJECT_NAME%"=="" (
    echo Project name cannot be empty. Exiting...
    pause
    exit /b 1
)

REM Prompt for WordPress Site Title
echo.
echo Please enter the name for your WordPress site:
set /p WP_TITLE=Site Title: 

REM Prompt for Database Username (default: root)
echo.
echo Please enter your database username (default is 'root'):
set /p DB_USER=Database Username [root]: 
if "%DB_USER%"=="" set DB_USER=root

REM Prompt for Database Password (leave blank for default 'mysql')
echo.
echo Please enter your database password (leave blank for default 'mysql'):
set /p DB_PASSWORD=Database Password: 
if "%DB_PASSWORD%"=="" set DB_PASSWORD=mysql

REM Prompt for WordPress Admin Username
echo.
echo Please enter your WordPress admin username:
set /p WP_ADMIN=Admin Username: 
if "%WP_ADMIN%"=="" set WP_ADMIN=admin

REM Prompt for WordPress Admin Password
echo.
echo Please enter your WordPress admin password:
set /p WP_ADMIN_PASSWORD=Admin Password: 
if "%WP_ADMIN_PASSWORD%"=="" set WP_ADMIN_PASSWORD=admin

REM Prompt for WordPress Admin Email
echo.
echo Please enter your WordPress admin email:
set /p WP_ADMIN_EMAIL=Admin Email: 
if "%WP_ADMIN_EMAIL%"=="" set WP_ADMIN_EMAIL=admin@gmail.com

REM -------------------------------------
REM Step 2: Set Derived Variables
REM -------------------------------------

REM Define the WordPress URL based on the Project Name
SET WP_URL=http://localhost/%PROJECT_NAME%
SET WP_ADMIN_URL=http://localhost/%PROJECT_NAME%/wp-admin

REM Define the WordPress Directory Path using the Project Name
SET WPC=C:\Program Files\Ampps\www\%PROJECT_NAME%

REM Optionally, define the Database Name based on the Project Name for consistency
SET DB_NAME=%PROJECT_NAME%_db

REM -------------------------------------
REM Step 3: Download and Extract WordPress
REM -------------------------------------

echo.
echo Downloading WordPress...
curl -O https://wordpress.org/latest.zip

REM Check if download was successful
if errorlevel 1 (
    echo Failed to download WordPress. Please check your internet connection.
    pause
    exit /b 1
)

echo Extracting WordPress...
powershell -Command "Expand-Archive -Path latest.zip -DestinationPath . -Force"

REM Remove the downloaded zip file
del latest.zip

REM -------------------------------------
REM Step 4: Move WordPress to the Desired Directory
REM -------------------------------------

echo.
echo Moving WordPress files to %WPC%...

REM Check if the target directory already exists
if exist "%WPC%" (
    echo The directory %WPC% already exists. Please choose a different project name or remove the existing directory.
    pause
    exit /b 1
)

REM Create the project directory if it doesn't exist
if not exist "%WPC%" mkdir "%WPC%"

REM Move all files and folders from the wordpress folder to the project directory
echo Moving all WordPress files and folders to %WPC%...
xcopy wordpress\* "%WPC%\" /s /e /h /y

REM Remove the empty 'wordpress' folder
rmdir /s /q wordpress

REM -------------------------------------
REM Step 5: Create MySQL Database
REM -------------------------------------

echo.
echo Creating MySQL database '%DB_NAME%'...

REM Create the database
if "%DB_PASSWORD%"=="" (
    %MYSQL_BIN% -u %DB_USER% -e "CREATE DATABASE IF NOT EXISTS %DB_NAME%;"
) else (
    %MYSQL_BIN% -u %DB_USER% -p%DB_PASSWORD% -e "CREATE DATABASE IF NOT EXISTS %DB_NAME%;"
)

REM Check if the database creation was successful
if errorlevel 1 (
    echo Failed to create the database. Please check your MySQL credentials.
    pause
    exit /b 1
)

REM -------------------------------------
REM Step 6: Configure wp-config.php
REM -------------------------------------

echo.
echo Configuring wp-config.php...

REM Copy the sample config to wp-config.php
copy "%WPC%\wp-config-sample.php" "%WPC%\wp-config.php"

REM Replace placeholders with actual database credentials
powershell -Command ^
    "(Get-Content '%WPC%\wp-config.php') -replace 'database_name_here', '%DB_NAME%' | Set-Content '%WPC%\wp-config.php'"

powershell -Command ^
    "(Get-Content '%WPC%\wp-config.php') -replace 'username_here', '%DB_USER%' | Set-Content '%WPC%\wp-config.php'"

powershell -Command ^
    "(Get-Content '%WPC%\wp-config.php') -replace 'password_here', '%DB_PASSWORD%' | Set-Content '%WPC%\wp-config.php'"

REM (Optional) Set the database host if different
SET DB_HOST=localhost

REM -------------------------------------
REM Step 7: Install WordPress Using WP-CLI
REM -------------------------------------

echo.
echo Installing WordPress using WP-CLI...

REM Run the WP-CLI installation command
php D:\YHS_DEVPACK\wp-cli.phar core install --url=%WP_URL% --title="%WP_TITLE%" --admin_user=%WP_ADMIN% --admin_password="%WP_ADMIN_PASSWORD%" --admin_email=%WP_ADMIN_EMAIL% --path="%WPC%"

REM Check if the installation was successful
if errorlevel 1 (
    echo WordPress installation failed. Please check the WP-CLI output for details.
    pause
    exit /b 1
)

echo.
echo ==================================================
echo      WordPress has been successfully installed!
echo      Admin Url: %WP_ADMIN_URL%
echo      Admin Username: %WP_ADMIN%
echo      Admin Email: %WP_ADMIN_EMAIL%
echo ==================================================
start %WP_ADMIN_URL%
pause
