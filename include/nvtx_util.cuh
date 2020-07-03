#pragma once
/**
 * Utility class / namespace for handling of NVTX profiling markers/ranges, wrapped in macros to avoid performance impact if not enabled.
 * 
 * Macro `USE_NVTX` must be defined to be enabled.
 * Use USE_NVTX_ macros to use. 
 */

 #if defined(USE_NVTX)
    // Include the appropriate header if enabled
    #if USE_NVTX >= 3
        #include "nvtx3/nvToolsExt.h"
    #else
        #include "nvToolsExt.h"
    #endif
#endif


// If nvtx is enabled, include header, defined namespace / class and macros.
#if defined(USE_NVTX)

    // Scope some things into a namespace
    namespace nvtx {

        // Colour palette (ARGB): colour brewer qualitative 8-class Dark2
        const uint32_t palette[] = { 0xff1b9e77, 0xffd95f02, 0xff7570b3, 0xffe7298a, 0xff66a61e, 0xffe6ab02, 0xffa6761d, 0xff666666};

        const uint32_t colourCount = sizeof(palette)/sizeof(uint32_t);


        // inline method to push an nvtx range
        inline void push(const char * str){
            // Static variable to track the next colour to be used with auto rotation.
            static uint32_t nextColourIdx = 0;

            // Get the wrapped colour index
            uint32_t colourIdx = nextColourIdx % colourCount;
            // Build/populate the struct of nvtx event attributes
            nvtxEventAttributes_t eventAttrib = {0};
            // Generic values
            eventAttrib.version = NVTX_VERSION;
            eventAttrib.size = NVTX_EVENT_ATTRIB_STRUCT_SIZE;
            eventAttrib.colorType = NVTX_COLOR_ARGB;
            eventAttrib.messageType = NVTX_MESSAGE_TYPE_ASCII;
            // Selected colour and string
            eventAttrib.color = palette[colourIdx];
            eventAttrib.message.ascii = str;
            // Push the custom event.
            nvtxRangePushEx(&eventAttrib);
            // nvtxRangePushA(str);
            nextColourIdx++;
        }

        // inline method to pop an nvtx range
        inline void pop(){
            nvtxRangePop();
        }

        // Class to auto-pop nvtx range when scope exits.
        class NVTXRange {
         public: 
            // Constructor, which pushes a named range marker
            NVTXRange(const char * str){
                nvtx::push(str);
            }
            // Destructor which pops a marker off the nvtx stack (might not atually correspond to the same marker in practice.)
            ~NVTXRange(){
                nvtx::pop();
            }
        };
    };
    // Macro to construct the range object for use in a scope-based setting.
    #define NVTX_RANGE(str) nvtx::NVTXRange uniq_name_using_macros(str)

    // Macro to push an arbitrary nvtx marker
    #define NVTX_PUSH(str) nvtx::push(str)

    // Macro to pop an arbitrary nvtx marker
    #define NVTX_POP() nvtx::pop()
#else
    // Empty macros for when NVTX is not enabled.
    #define NVTX_RANGE(str)
    #define NVTX_PUSH(str)
    #define NVTX_POP()
#endif
