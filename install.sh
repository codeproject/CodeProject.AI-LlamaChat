#!/bin/bash

# Development mode setup script ::::::::::::::::::::::::::::::::::::::::::::::
#
#                            LlamaChat
#
# This script is called from the LlamaChat directory using: 
#
#    bash ../../CodeProject.AI-Server/src/setup.sh
#
# The setup.sh script will find this install.sh file and execute it.
#
# For help with install scripts, notes on variables and methods available, tips,
# and explanations, see /src/modules/install_script_help.md

if [ "$1" != "install" ]; then
    read -t 3 -p "This script is only called from: bash ../../CodeProject.AI-Server/src/setup.sh"
    echo
    exit 1 
fi

if [ "${edgeDevice}" = "Raspberry Pi" ] || [ "${edgeDevice}" = "Orange Pi" ] || 
   [ "${edgeDevice}" = "Radxa ROCK" ]   || [ "${edgeDevice}" = "Jetson" ]; then
    moduleInstallErrors="Unable to install on Pi, ROCK or Jetson hardware."
fi

if [ "$moduleInstallErrors" = "" ]; then

    # https://stackoverflow.com/a/66377202
    if [ "${os}" = "linux" ]; then

        if [ ! -f /usr/lib/libc.musl-x86_64.so.1 ]; then

            if [ ! -d /usr/local/musl/lib/ ]; then
                if [ ! -f musl-1.2.2.tar.gz ]; then
                    write "Downloading libc musl..." "$color_info"
                    curl https://musl.libc.org/releases/musl-1.2.2.tar.gz -o musl-1.2.2.tar.gz
                    writeLine "Done." "$color_success"
                fi
                if [ ! -d musl-1.2.2 ]; then
                    write "Extracting musl..." "$color_info"
                    tar -xvf musl-1.2.2.tar.gz
                    writeLine "Done." "$color_success"
                fi

                cd musl-1.2.2
                if [ "$verbosity" = "quiet" ]; then
                    ./configure > /dev/null
                    make  > /dev/null
                    sudo make install  > /dev/null
                else
                    write "Configuring..." "$color_info"
                    ./configure > /dev/null
                    write "building..." "$color_info"
                    make > /dev/null
                    write "Installing..." "$color_info"
                    sudo make install
                    writeLine "Done." "$color_success"
                fi
                cd ..

                write "Cleanup..." "$color_info"
                rm -rf musl-1.2.2
                rm musl-1.2.2.tar.gz
                writeLine "Done." "$color_success"
            fi 

            sudo ln -s /usr/local/musl/lib/libc.so /usr/lib/libc.musl-x86_64.so.1
        fi
    fi

    if [ "${os}" = "macos" ] && [ "${architecture}" = "arm64" ]; then

        # Wouldn't it be nice if this just worked?
        # installPythonPackagesByName "llama-cpp-python" "Simple Python bindings for the llama.cpp library"

        pushd "${virtualEnvDirPath}/bin" >/dev/null
        ./pip3 uninstall llama-cpp-python -y 

        checkForTool "cmake"
        checkForTool "ninja"
        #checkForTool "gcc@11"
        #checkForTool "g++@11"

        # For Python >= 3.8
        # METAL causes a warning "llama.cpp/ggml.c:1509:5: warning: implicit conversion increases 
        # floating-point precision: 'float' to 'ggml_float' (aka 'double') [-Wdouble-promotion]
        #  GGML_F16_VEC_REDUCE(sumf, sum);" which then borks the entire llama.cpp build. Turn off
        # metal to get this overly pedantic codee to build. macOS just gets no love.

        if [ "${architecture}" = "arm64" ]; then
            if [ "$verbosity" = "loud" ]; then
                # CMAKE_ARGS="-DLLAMA_METAL=on" FORCE_CMAKE=1 "${venvPythonCmdPath}" -m pip install -U git+https://github.com/abetlen/llama-cpp-python.git --no-cache-dir
                CMAKE_ARGS="-DLLAMA_METAL=off -DLLAMA_CLBLAST=on" FORCE_CMAKE=1 "${venvPythonCmdPath}" -m pip install llama-cpp-python
            else
                CMAKE_ARGS="-DLLAMA_METAL=off -DLLAMA_CLBLAST=on" FORCE_CMAKE=1 "${venvPythonCmdPath}" -m pip install llama-cpp-python > /dev/null
            fi
        else
            if [ "$verbosity" = "loud" ]; then
                # "${venvPythonCmdPath}" -m pip install llama-cpp-python
                # CMAKE_ARGS="-DLLAMA_METAL=off -DLLAMA_CLBLAS=on" FORCE_CMAKE=1 "${venvPythonCmdPath}" -m pip install llama-cpp-python
                CMAKE_ARGS="-DLLAMA_METAL=off" FORCE_CMAKE=1 "${venvPythonCmdPath}" -m pip install llama-cpp-python
            else
                CMAKE_ARGS="-DLLAMA_METAL=off" FORCE_CMAKE=1 "${venvPythonCmdPath}" -m pip install llama-cpp-python > /dev/null
            fi
        fi

        popd >/dev/null
    fi

    HF_HUB_DISABLE_SYMLINKS_WARNING=1

    # codellama
    # sourceUrl="https://huggingface.co/TheBloke/CodeLlama-7B-GGUF/resolve/main/"
    # fileToGet="codellama-7b.Q4_K_M.gguf"
      
    # Mistral
    # sourceUrl="https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/"
    # fileToGet=mistral-7b-instruct-v0.2.Q4_K_M.gguf

    # Phi-3
    sourceUrl="https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/"
    fileToGet="Phi-3-mini-4k-instruct-q4.gguf"

    if [ "$verbosity" = "loud" ]; then writeLine "Looking for model: ${moduleDirPath}/models/${fileToGet}"; fi

    if [ ! -f "${moduleDirPath}/models/${fileToGet}" ]; then
        
        cacheDirPath="${downloadDirPath}/${modulesDir}/${assetsDir}/${moduleDirName}/${fileToGet}"
        
        if [ "$verbosity" = "loud" ]; then writeLine  "Looking for cache: ${cacheDirPath}"; fi
        if [ ! -f "${cacheDirPath}" ]; then
            mkdir -p "${downloadDirPath}/${modulesDir}/${moduleDirName}"
            mkdir -p "${moduleDirPath}/models"
            wget $wgetFlags -P "${downloadDirPath}/${modulesDir}/${moduleDirName}" "${sourceUrl}${fileToGet}"
        elif [ "$verbosity" = "loud" ]; then
            writeLine "File is cached" 
        fi

        if [ -f "${cacheDirPath}" ]; then 
            mkdir -p "${moduleDirPath}/models"
            cp "${cacheDirPath}" "${moduleDirPath}/models/"
        fi

    else
        writeLine "${fileToGet} already downloaded." "$color_success"
    fi
    
fi