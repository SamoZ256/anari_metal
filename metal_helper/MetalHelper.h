#pragma once

//metal
#import <Metal/Metal.h>

//glm
#include "../AnariMetalMath.h"

namespace anari_mtl {

namespace helper {

void copyBufferToBuffer(id<MTLCommandQueue> commandQueue, id<MTLBuffer> source, id<MTLBuffer> destination, size_t srcOffset, size_t dstOffset, size_t size);

void copyTextureToBuffer(id<MTLCommandQueue> commandQueue, id<MTLTexture> source, id<MTLBuffer> destination, uint3 size, size_t bytesPerPixel, size_t dstOffset);

void copyBufferToTexture(id<MTLCommandQueue> commandQueue, id<MTLBuffer> source, id<MTLTexture> destination, uint3 size, size_t bytesPerPixel, size_t srcOffset);

MTLPixelFormat getMTLPixelFormatFromANARIDataType(ANARIDataType dataType, bool depthFormat = false);

} //namespace helper

} //namespace anari_mtl
