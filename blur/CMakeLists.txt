cmake_minimum_required(VERSION 2.8)
project(blur)
find_package(OpenCV REQUIRED)
find_package(CUDA REQUIRED)
cuda_add_executable(blur blur.cu)
target_link_libraries(blur ${OpenCV_LIBS})
