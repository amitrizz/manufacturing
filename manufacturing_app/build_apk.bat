@echo off
set "JAVA_HOME=C:\Program Files\Java\jdk-17"
set "PATH=C:\Program Files\Java\jdk-17\bin;%PATH%"
set "ANDROID_HOME=C:\Users\Lenovo\AppData\Local\Android\Sdk"
set "ANDROID_SDK_ROOT=C:\Users\Lenovo\AppData\Local\Android\Sdk"
echo Using JAVA_HOME: %JAVA_HOME%
echo Using ANDROID_HOME: %ANDROID_HOME%
call D:\flutter\bin\flutter.bat build apk --release
