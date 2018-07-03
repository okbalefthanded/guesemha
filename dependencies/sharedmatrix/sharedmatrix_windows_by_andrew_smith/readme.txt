Recommendations on how to install on Windows:

First, you need boost libraries. 
Second, cd to the sharedmatrix_windows... folder 
Third, copy the struct 'mxArray_tag' from sharedmatrix.h file into SharedMemory.hpp 
Fourth, add the line 
#define BOOST_DATE_TIME_NO_LIB 
before the first boost #include in SharedMemory.hpp