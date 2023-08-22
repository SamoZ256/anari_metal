#include "MetalHelper.h"

namespace anari_mtl {

namespace helper {

void copyBufferToBuffer(id<MTLCommandQueue> commandQueue, id<MTLBuffer> source, id<MTLBuffer> destination, size_t srcOffset, size_t dstOffset, size_t size) {
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    id<MTLBlitCommandEncoder> encoder = [commandBuffer blitCommandEncoder];

    [encoder copyFromBuffer:source sourceOffset:srcOffset toBuffer:destination destinationOffset:dstOffset size:size];

    [encoder endEncoding];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    [encoder release];
    [commandBuffer release];
}

void copyTextureToBuffer(id<MTLCommandQueue> commandQueue, id<MTLTexture> source, id<MTLBuffer> destination, uint3 size, size_t bytesPerPixel, size_t dstOffset) {
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    id<MTLBlitCommandEncoder> encoder = [commandBuffer blitCommandEncoder];

    [encoder copyFromTexture:source sourceSlice:0 sourceLevel:0 sourceOrigin:MTLOriginMake(0, 0, 0) sourceSize:MTLSizeMake(size.x, size.y, size.z) toBuffer:destination destinationOffset:dstOffset destinationBytesPerRow:size.x * bytesPerPixel destinationBytesPerImage:size.x * size.y * size.z * bytesPerPixel];

    [encoder endEncoding];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    [encoder release];
    [commandBuffer release];
}

void copyBufferToTexture(id<MTLCommandQueue> commandQueue, id<MTLBuffer> source, id<MTLTexture> destination, uint3 size, size_t bytesPerPixel, size_t srcOffset) {
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    id<MTLBlitCommandEncoder> encoder = [commandBuffer blitCommandEncoder];

    [encoder copyFromBuffer:source sourceOffset:srcOffset sourceBytesPerRow:size.x * bytesPerPixel sourceBytesPerImage:size.x * size.y * size.z * bytesPerPixel sourceSize:MTLSizeMake(size.x, size.y, size.z) toTexture:destination destinationSlice:0 destinationLevel:0 destinationOrigin:MTLOriginMake(0, 0, 0)];

    [encoder endEncoding];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    [encoder release];
    [commandBuffer release];
}

MTLPixelFormat getMTLPixelFormatFromANARIDataType(ANARIDataType dataType, bool depthFormat) {
    if (depthFormat) {
        switch (dataType) {
        //TODO: check which one of these 2 sould be used
        case ANARI_UFIXED16:
        case ANARI_FLOAT16:
            return MTLPixelFormatDepth16Unorm;
        case ANARI_FLOAT32:
            return MTLPixelFormatDepth32Float;
        default:
            return MTLPixelFormatInvalid;
        }
    } else {
        switch (dataType) {
        //Integer formats
        case ANARI_INT8:
            return MTLPixelFormatR8Sint;
        case ANARI_INT8_VEC2:
            return MTLPixelFormatRG8Sint;
        case ANARI_INT8_VEC3:
            return MTLPixelFormatInvalid;
        case ANARI_INT8_VEC4:
            return MTLPixelFormatRGBA8Sint;
        case ANARI_UINT8:
            return MTLPixelFormatR8Uint;
        case ANARI_UINT8_VEC2:
            return MTLPixelFormatRG8Uint;
        case ANARI_UINT8_VEC3:
            return MTLPixelFormatInvalid;
        case ANARI_UINT8_VEC4:
            return MTLPixelFormatRGBA8Uint;
        case ANARI_INT16:
            return MTLPixelFormatR16Sint;
        case ANARI_INT16_VEC2:
            return MTLPixelFormatRG16Sint;
        case ANARI_INT16_VEC3:
            return MTLPixelFormatInvalid;
        case ANARI_INT16_VEC4:
            return MTLPixelFormatRGBA16Sint;
        case ANARI_UINT16:
            return MTLPixelFormatR16Uint;
        case ANARI_UINT16_VEC2:
            return MTLPixelFormatRG16Uint;
        case ANARI_UINT16_VEC3:
            return MTLPixelFormatInvalid;
        case ANARI_UINT16_VEC4:
            return MTLPixelFormatRGBA16Uint;
        case ANARI_INT32:
            return MTLPixelFormatR32Sint;
        case ANARI_INT32_VEC2:
            return MTLPixelFormatRG32Sint;
        case ANARI_INT32_VEC3:
            return MTLPixelFormatInvalid;
        case ANARI_INT32_VEC4:
            return MTLPixelFormatRGBA32Sint;
        case ANARI_UINT32:
            return MTLPixelFormatR32Uint;
        case ANARI_UINT32_VEC2:
            return MTLPixelFormatRG32Uint;
        case ANARI_UINT32_VEC3:
            return MTLPixelFormatInvalid;
        case ANARI_UINT32_VEC4:
            return MTLPixelFormatRGBA32Uint;
        case ANARI_INT64:
        case ANARI_INT64_VEC2:
        case ANARI_INT64_VEC3:
        case ANARI_INT64_VEC4:
        case ANARI_UINT64:
        case ANARI_UINT64_VEC2:
        case ANARI_UINT64_VEC3:
        case ANARI_UINT64_VEC4:
            return MTLPixelFormatInvalid;

        //Normalized formats
        case ANARI_FIXED8:
            return MTLPixelFormatR8Snorm;
        case ANARI_FIXED8_VEC2:
            return MTLPixelFormatRG8Snorm;
        case ANARI_FIXED8_VEC3:
            return MTLPixelFormatInvalid;
        case ANARI_FIXED8_VEC4:
            return MTLPixelFormatRGBA8Snorm;
        case ANARI_UFIXED8:
            return MTLPixelFormatR8Unorm;
        case ANARI_UFIXED8_VEC2:
            return MTLPixelFormatRG8Unorm;
        case ANARI_UFIXED8_VEC3:
            return MTLPixelFormatInvalid;
        case ANARI_UFIXED8_VEC4:
            return MTLPixelFormatRGBA8Unorm;
        case ANARI_FIXED16:
            return MTLPixelFormatR16Snorm;
        case ANARI_FIXED16_VEC2:
            return MTLPixelFormatRG16Snorm;
        case ANARI_FIXED16_VEC3:
            return MTLPixelFormatInvalid;
        case ANARI_FIXED16_VEC4:
            return MTLPixelFormatRGBA16Snorm;
        case ANARI_UFIXED16:
            return MTLPixelFormatR16Unorm;
        case ANARI_UFIXED16_VEC2:
            return MTLPixelFormatRG16Unorm;
        case ANARI_UFIXED16_VEC3:
            return MTLPixelFormatInvalid;
        case ANARI_UFIXED16_VEC4:
            return MTLPixelFormatRGBA16Unorm;
        case ANARI_FIXED32:
        case ANARI_FIXED32_VEC2:
        case ANARI_FIXED32_VEC3:
        case ANARI_FIXED32_VEC4:
        case ANARI_UFIXED32:
        case ANARI_UFIXED32_VEC2:
        case ANARI_UFIXED32_VEC3:
        case ANARI_UFIXED32_VEC4:
        case ANARI_FIXED64:
        case ANARI_FIXED64_VEC2:
        case ANARI_FIXED64_VEC3:
        case ANARI_FIXED64_VEC4:
        case ANARI_UFIXED64:
        case ANARI_UFIXED64_VEC2:
        case ANARI_UFIXED64_VEC3:
        case ANARI_UFIXED64_VEC4:
            return MTLPixelFormatInvalid;
        
        //Floating-point formats
        case ANARI_FLOAT16:
            return MTLPixelFormatR16Float;
        case ANARI_FLOAT16_VEC2:
            return MTLPixelFormatRG16Float;
        case ANARI_FLOAT16_VEC3:
            return MTLPixelFormatInvalid;
        case ANARI_FLOAT16_VEC4:
            return MTLPixelFormatRGBA16Float;
        case ANARI_FLOAT32:
            return MTLPixelFormatR32Float;
        case ANARI_FLOAT32_VEC2:
            return MTLPixelFormatRG32Float;
        case ANARI_FLOAT32_VEC3:
            return MTLPixelFormatInvalid;
        case ANARI_FLOAT32_VEC4:
            return MTLPixelFormatRGBA32Float;
        case ANARI_FLOAT64:
        case ANARI_FLOAT64_VEC2:
        case ANARI_FLOAT64_VEC3:
        case ANARI_FLOAT64_VEC4:
            return MTLPixelFormatInvalid;
        
        //Fixed sRGB formats
        case ANARI_UFIXED8_RGBA_SRGB:
            return MTLPixelFormatRGBA8Unorm_sRGB;
        case ANARI_UFIXED8_RGB_SRGB:
            return MTLPixelFormatInvalid;
        case ANARI_UFIXED8_RA_SRGB:
            return MTLPixelFormatInvalid;
        case ANARI_UFIXED8_R_SRGB:
            return MTLPixelFormatR8Unorm_sRGB;
        default:
            return MTLPixelFormatInvalid;
        }
    }
}

} //namespace helper

} //namespace anari_mtl
