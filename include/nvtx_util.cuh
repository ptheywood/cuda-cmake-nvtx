#pragma once
#include <stdio.h>

#if defined(NVTX)
    #include <nvToolsExt.h>
#endif

void printNVTXStatus(){
    #if defined(NVTX)
        printf("NVTX is ON\n");
    #else 
        printf("NVTX is OFF\n");
    #endif
}


#if defined(NVTX)
    class NVTXRange {
     public: 
        NVTXRange(const char * str){
            nvtxRangePushA(str);
        }

        ~NVTXRange(){
            nvtxRangePop();
        }
    };
    #define NVTX_RANGE(str) NVTXRange uniq_name_using_macros(str)

    #define NVTX_PUSH(str) nvtxRangePushA(str)
    #define NVTX_POP() nvtxRangePop()
#else
    #define NVTX_RANGE(str)

    #define NVTX_PUSH(str)
    #define NVTX_POP()
#endif
