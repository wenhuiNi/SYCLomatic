// Option: --use-dpcpp-extensions=intel_device_math
#include "cuda_bf16.h"

__global__ void test(int i) {
  // Start
  __int2bfloat16_rz(i /*int*/);
  // End
}
