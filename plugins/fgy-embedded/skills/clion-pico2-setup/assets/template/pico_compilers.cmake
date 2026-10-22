# pico_compilers.cmake
#
# Minimal helper to select the Arm bare‑metal toolchain when CMake
# is *not* already told which compiler to use (i.e. in plain CLI builds).
# It intentionally does NOT set CPU flags; the Pico SDK takes care of that.

# Allow override via env or cache
set(ARM_GCC_PATH "$ENV{ARM_GCC_PATH}" CACHE PATH "Prefix of Arm GCC (contains bin/arm-none-eabi-gcc)")

# Prefer finding the actual compiler binary rather than guessing based on /usr vs /usr/local.
# This avoids the common Linux case where /usr/local exists but the toolchain is in /usr/bin.
if(NOT ARM_GCC_PATH OR NOT EXISTS "${ARM_GCC_PATH}")
    find_program(ARM_NONE_EABI_GCC arm-none-eabi-gcc
        HINTS
            /opt/homebrew/bin
            /usr/bin
            /usr/local/bin
    )
    if(ARM_NONE_EABI_GCC)
        # Convert ".../<prefix>/bin/arm-none-eabi-gcc" -> "<prefix>"
        get_filename_component(_gcc_bin_dir "${ARM_NONE_EABI_GCC}" DIRECTORY)
        get_filename_component(ARM_GCC_PATH "${_gcc_bin_dir}" DIRECTORY)
    endif()
endif()

# Tell CMake which compilers to use, but only if they aren't set yet.
# This is safe with IDEs: CLion normally sets these already via its toolchain.
if(NOT CMAKE_C_COMPILER)
    set(CMAKE_C_COMPILER   "${ARM_GCC_PATH}/bin/arm-none-eabi-gcc" CACHE FILEPATH "" FORCE)
endif()
if(NOT CMAKE_CXX_COMPILER)
    set(CMAKE_CXX_COMPILER "${ARM_GCC_PATH}/bin/arm-none-eabi-g++" CACHE FILEPATH "" FORCE)
endif()
if(NOT CMAKE_ASM_COMPILER)
    set(CMAKE_ASM_COMPILER "${ARM_GCC_PATH}/bin/arm-none-eabi-gcc" CACHE FILEPATH "" FORCE)
endif()

# Make CMake's try‑compile test build a static library instead of linking an exe,
# which avoids the usual bare‑metal "undefined reference to _exit/_sbrk/..." issues.
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
