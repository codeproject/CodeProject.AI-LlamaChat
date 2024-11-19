:: Installation script :::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
::                           LlamaChat
::
:: This script is only called from ..\..\CodeProject.AI-Server\src\setup.bat in
:: Dev setup, or ..\..\src\setup.bat in production
::
:: For help with install scripts, notes on variables and methods available, tips,
:: and explanations, see /src/modules/install_script_help.md

@if "%1" NEQ "install" (
    echo This script is only called from ..\..\src\setup.bat
    @pause
    @goto:eof
)

REM Backwards compatibility with Server 2.6.5
if "!utilsScript!" == "" if "!sdkScriptsDirPath!" NEQ "" set utilsScript=%sdkScriptsDirPath%\utils.bat

set HF_HUB_DISABLE_SYMLINKS_WARNING=1

REM Download the model file at installation so we can run without a connection to the Internet.

REM Mistral
REM set fileToGet=mistral-7b-instruct-v0.2.Q4_K_M.gguf
REM set sourceUrl=https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/

REM Phi-3
set sourceUrl=https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/
set fileToGet=Phi-3-mini-4k-instruct-q4.gguf

if not exist "!moduleDirPath!/models/!fileToGet!" (
    set destination=!downloadDirPath!\!modulesDir!\!moduleDirName!\!fileToGet!

    if not exist "!downloadDirPath!\!modulesDir!\!moduleDirName!" mkdir "!downloadDirPath!\!modulesDir!\!moduleDirName!"
    if not exist "!moduleDirPath!\models" mkdir "!moduleDirPath!\models"

    call "!utilsScript!" WriteLine "Downloading !fileToGet!" "!color_info!"

    powershell -command "Start-BitsTransfer -Source '!sourceUrl!!fileToGet!' -Destination '!destination!'"
    if errorlevel 1 (
        powershell -Command "Get-BitsTransfer | Remove-BitsTransfer"
        powershell -command "Start-BitsTransfer -Source '!sourceUrl!!fileToGet!' -Destination '!destination!'"
    )
    if errorlevel 1 (
        powershell -Command "Invoke-WebRequest '!sourceUrl!!fileToGet!' -OutFile '!destination!'"
        if errorlevel 1 (
            call "!utilsScript!" WriteLine "Download failed. Sorry." "!color_error!"
            set moduleInstallErrors=Unable to download !fileToGet!
        )
    )

    if exist "!destination!" (
        call "!utilsScript!" WriteLine "Moving !fileToGet! into the models folder." "!color_info!"
        move "!destination!" "!moduleDirPath!/models/" > nul
    ) else (
        call "!utilsScript!" WriteLine "Download failed. Sad face." "!color_warn!"
    )
) else (
    call "!utilsScript!" WriteLine "!fileToGet! already downloaded." "!color_success!"
)

REM set moduleInstallErrors=
