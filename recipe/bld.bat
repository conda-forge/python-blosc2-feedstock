@echo ON
# set CC=clang-cl
# set CXX=clang-cl
set CMAKE_GENERATOR_TOOLSET=ClangCL

%PYTHON% -m pip install . -vv
if %ERRORLEVEL% neq 0 exit 1
