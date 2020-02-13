#pragma once

#include <stdio.h>

#include <nvrtc.h>
#include <string>

void test_rtc(){
    printf("Testing RTC\n");

    std::string type_name;
    nvrtcGetTypeName<float>(&type_name);
    std::string s = std::string("f3<") + type_name + ">";
    printf("%s\n", s.c_str());
}
