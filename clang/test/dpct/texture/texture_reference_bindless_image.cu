// UNSUPPORTED: cuda-12.0, cuda-12.1, cuda-12.2, cuda-12.3
// UNSUPPORTED: v12.0, v12.1, v12.2, v12.3
// RUN: dpct --format-range=none --use-experimental-features=bindless_images -out-root %T/texture/texture_reference_bindless_image %s --cuda-include-path="%cuda-path/include" -- -x cuda --cuda-host-only -std=c++14
// RUN: FileCheck --input-file %T/texture/texture_reference_bindless_image/texture_reference_bindless_image.dp.cpp --match-full-lines %s
// RUN: %if build_lit %{icpx -c -fsycl %T/texture/texture_reference_bindless_image/texture_reference_bindless_image.dp.cpp -o %T/texture/texture_reference_bindless_image/texture_reference_bindless_image.dp.o %}

// CHECK: dpct::experimental::bindless_image_wrapper<sycl::short2, 1> tex1;
static texture<short2, 1> tex1;
// CHECK: dpct::experimental::bindless_image_wrapper<sycl::float4, 2> tex2;
static texture<float4, 2> tex2;
// CHECK: dpct::experimental::bindless_image_wrapper<sycl::float4, 3> tex3;
static texture<float4, 3> tex3;

// CHECK: void kernel(sycl::ext::oneapi::experimental::sampled_image_handle tex1,
// CHECK-NEXT:             sycl::ext::oneapi::experimental::sampled_image_handle tex2,
// CHECK-NEXT:             sycl::ext::oneapi::experimental::sampled_image_handle tex3) {
__global__ void kernel() {
  // CHECK: sycl::ext::oneapi::experimental::read_image<sycl::short2>(tex1, (float)1);
  tex1D(tex1, 1);
  // CHECK: sycl::float4 f42 = sycl::ext::oneapi::experimental::read_image<sycl::float4>(tex2, sycl::float2(1.0f, 1.0f));
  float4 f42 = tex2D(tex2, 1.0f, 1.0f);
  // CHECK: sycl::ext::oneapi::experimental::read_mipmap<sycl::short2>(tex1, 1.0f, 2.0f);
  tex1DLod(tex1, 1.0f, 2.0f);
  // CHECK: sycl::ext::oneapi::experimental::read_mipmap<sycl::float4>(tex2, sycl::float2(1.0f, 2.0f), 3.0f);
  tex2DLod(tex2, 1.0f, 2.0f, 3.0f);
  // CHECK: sycl::ext::oneapi::experimental::read_mipmap<sycl::float4>(tex3, sycl::float4(1.0f, 2.0f, 3.0f, 0), 4.0f);
  tex3DLod(tex3, 1.0f, 2.0f, 3.0f, 4.0f);
}

int main() {
  int i;
  // CHECK: tex2.set(sycl::addressing_mode::repeat);
  tex2.addressMode[0] = cudaAddressModeWrap;
  // CHECK: auto addressMode = tex2.get_addressing_mode();
  auto addressMode = tex2.addressMode[0];
  // CHECK: tex2.set_channel_size(1, i);
  tex2.channelDesc.x = i;
  // CHECK: i = tex2.get_channel_size();
  i = tex2.channelDesc.x;
  // CHECK: tex2.set_channel_size(2, i);
  tex2.channelDesc.y = i;
  // CHECK: i = tex2.get_channel_size();
  i = tex2.channelDesc.y;
  // CHECK: tex2.set_channel_size(3, i);
  tex2.channelDesc.z = i;
  // CHECK: i = tex2.get_channel_size();
  i = tex2.channelDesc.z;
  // CHECK: tex2.set_channel_size(4, i);
  tex2.channelDesc.w = i;
  // CHECK: i = tex2.get_channel_size();
  i = tex2.channelDesc.w;
  // CHECK: tex2.set_channel_data_type(dpct::image_channel_data_type::fp);
  tex2.channelDesc.f = cudaChannelFormatKindFloat;
  // CHECK: auto f = tex2.get_channel_data_type();
  auto f = tex2.channelDesc.f;
  // CHECK: tex2.set_channel(dpct::image_channel::create<sycl::float4>());
  tex2.channelDesc = cudaCreateChannelDesc<float4>();
  // CHECK:  auto channelDesc = tex2.get_channel();
  auto channelDesc = tex2.channelDesc;
  // CHECK: tex2.set(sycl::filtering_mode::nearest);
  tex2.filterMode = cudaFilterModePoint;
  // CHECK: auto filterMode = tex2.get_filtering_mode();
  auto filterMode = tex2.filterMode;
  // CHECK: tex2.set(sycl::coordinate_normalization_mode::unnormalized);
  tex2.normalized = 0;
  // CHECK: i = tex2.is_coordinate_normalized();
  i = tex2.normalized;

  void *dataPtr;
  const size_t w = 4;
  const size_t h = 2;
  size_t pitch = sizeof(float4) * 4;
  float4 expect[h * w] = {
      {1, 2, 3, 4},
      {5, 6, 7, 8},
  };
  cudaMalloc(&dataPtr, sizeof(expect));
  cudaMemcpy(dataPtr, &expect, sizeof(expect), cudaMemcpyHostToDevice);
  // CHECK: tex2.attach(dataPtr, pitch * h);
  cudaBindTexture(0, tex2, dataPtr, pitch * h);
  // CHECK: tex2.attach(dataPtr, w, h, pitch);
  cudaBindTexture2D(0, tex2, dataPtr, w, h, pitch);
  // CHECK: dpct::experimental::image_mem_wrapper_ptr pArr;
  cudaArray_t pArr;
  // CHECK: tex2.attach(pArr);
  cudaBindTextureToArray(tex2, pArr);
  // CHECK: q_ct1.submit(
  // CHECK-NEXT: [&](sycl::handler &cgh) {
  // CHECK-NEXT:   auto tex1_handle = tex1.get_handle();
  // CHECK-NEXT:   auto tex2_handle = tex2.get_handle();
  // CHECK-NEXT:   auto tex3_handle = tex3.get_handle();
  // CHECK-EMPTY:
  // CHECK-NEXT:   cgh.parallel_for(
  // CHECK-NEXT:     sycl::nd_range<3>(sycl::range<3>(1, 1, 1), sycl::range<3>(1, 1, 1)),
  // CHECK-NEXT:     [=](sycl::nd_item<3> item_ct1) {
  // CHECK-NEXT:       kernel(tex1_handle, tex2_handle, tex3_handle);
  // CHECK-NEXT:     });
  // CHECK-NEXT: });
  kernel<<<1, 1>>>();
  // CHECK: tex2.detach();
  cudaUnbindTexture(tex2);

  return 0;
}
