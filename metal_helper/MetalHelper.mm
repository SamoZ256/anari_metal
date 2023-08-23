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

PixelFormat getMTLPixelFormatFromANARIDataType(ANARIDataType dataType, bool depthFormat, bool allowSizeChange, bool allowChannelCountChange) {
    PixelFormat pixelFormat;
    if (depthFormat) {
        switch (dataType) {
        //TODO: check which one of these 2 sould be used
        case ANARI_UFIXED16:
        case ANARI_FLOAT16:
            pixelFormat.mtlPixelFormat = MTLPixelFormatDepth16Unorm;
            break;
        case ANARI_FLOAT32:
            pixelFormat.mtlPixelFormat = MTLPixelFormatDepth32Float;
            break;
        default:
            pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        }
    } else {
        switch (dataType) {
        //Integer formats
        case ANARI_INT8:
            pixelFormat.mtlPixelFormat = MTLPixelFormatR8Sint;
            break;
        case ANARI_INT8_VEC2:
            pixelFormat.mtlPixelFormat = MTLPixelFormatRG8Sint;
            break;
        case ANARI_INT8_VEC3:
            if (allowChannelCountChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA8Sint;
                pixelFormat.channelCountChangedTo4 = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_INT8_VEC4:
            pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA8Sint;
            break;
        case ANARI_UINT8:
            pixelFormat.mtlPixelFormat = MTLPixelFormatR8Uint;
            break;
        case ANARI_UINT8_VEC2:
            pixelFormat.mtlPixelFormat = MTLPixelFormatRG8Uint;
            break;
        case ANARI_UINT8_VEC3:
            if (allowChannelCountChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA8Uint;
                pixelFormat.channelCountChangedTo4 = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_UINT8_VEC4:
            pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA8Uint;
            break;
        case ANARI_INT16:
            pixelFormat.mtlPixelFormat = MTLPixelFormatR16Sint;
            break;
        case ANARI_INT16_VEC2:
            pixelFormat.mtlPixelFormat = MTLPixelFormatRG16Sint;
            break;
        case ANARI_INT16_VEC3:
            if (allowChannelCountChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA16Sint;
                pixelFormat.channelCountChangedTo4 = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_INT16_VEC4:
            pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA16Sint;
            break;
        case ANARI_UINT16:
            pixelFormat.mtlPixelFormat = MTLPixelFormatR16Uint;
            break;
        case ANARI_UINT16_VEC2:
            pixelFormat.mtlPixelFormat = MTLPixelFormatRG16Uint;
            break;
        case ANARI_UINT16_VEC3:
            if (allowChannelCountChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA16Uint;
                pixelFormat.channelCountChangedTo4 = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_UINT16_VEC4:
            pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA16Uint;
            break;
        case ANARI_INT32:
            pixelFormat.mtlPixelFormat = MTLPixelFormatR32Sint;
            break;
        case ANARI_INT32_VEC2:
            pixelFormat.mtlPixelFormat = MTLPixelFormatRG32Sint;
            break;
        case ANARI_INT32_VEC3:
            if (allowChannelCountChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA32Sint;
                pixelFormat.channelCountChangedTo4 = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_INT32_VEC4:
            pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA32Sint;
            break;
        case ANARI_UINT32:
            pixelFormat.mtlPixelFormat = MTLPixelFormatR32Uint;
            break;
        case ANARI_UINT32_VEC2:
            pixelFormat.mtlPixelFormat = MTLPixelFormatRG32Uint;
            break;
        case ANARI_UINT32_VEC3:
            if (allowChannelCountChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA32Uint;
                pixelFormat.channelCountChangedTo4 = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_UINT32_VEC4:
            pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA32Uint;
            break;
        case ANARI_INT64:
            if (allowSizeChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatR32Sint;
                pixelFormat.sizeChanged = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_INT64_VEC2:
            if (allowSizeChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatRG32Sint;
                pixelFormat.sizeChanged = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_INT64_VEC3:
            if (allowSizeChange && allowChannelCountChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA32Sint;
                pixelFormat.sizeChanged = true;
                pixelFormat.channelCountChangedTo4 = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_INT64_VEC4:
            if (allowSizeChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA32Sint;
                pixelFormat.sizeChanged = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_UINT64:
            if (allowSizeChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatR32Uint;
                pixelFormat.sizeChanged = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_UINT64_VEC2:
            if (allowSizeChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatRG32Uint;
                pixelFormat.sizeChanged = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_UINT64_VEC3:
            if (allowSizeChange && allowChannelCountChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA32Uint;
                pixelFormat.sizeChanged = true;
                pixelFormat.channelCountChangedTo4 = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_UINT64_VEC4:
            if (allowSizeChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA32Uint;
                pixelFormat.sizeChanged = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;

        //Normalized formats
        case ANARI_FIXED8:
            pixelFormat.mtlPixelFormat = MTLPixelFormatR8Snorm;
            break;
        case ANARI_FIXED8_VEC2:
            pixelFormat.mtlPixelFormat = MTLPixelFormatRG8Snorm;
            break;
        case ANARI_FIXED8_VEC3:
            if (allowChannelCountChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA8Snorm;
                pixelFormat.channelCountChangedTo4 = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_FIXED8_VEC4:
            pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA8Snorm;
            break;
        case ANARI_UFIXED8:
            pixelFormat.mtlPixelFormat = MTLPixelFormatR8Unorm;
            break;
        case ANARI_UFIXED8_VEC2:
            pixelFormat.mtlPixelFormat = MTLPixelFormatRG8Unorm;
            break;
        case ANARI_UFIXED8_VEC3:
            if (allowChannelCountChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA8Unorm;
                pixelFormat.channelCountChangedTo4 = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_UFIXED8_VEC4:
            pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA8Unorm;
            break;
        case ANARI_FIXED16:
            pixelFormat.mtlPixelFormat = MTLPixelFormatR16Snorm;
            break;
        case ANARI_FIXED16_VEC2:
            pixelFormat.mtlPixelFormat = MTLPixelFormatRG16Snorm;
            break;
        case ANARI_FIXED16_VEC3:
            if (allowChannelCountChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA16Snorm;
                pixelFormat.channelCountChangedTo4 = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_FIXED16_VEC4:
            pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA16Snorm;
            break;
        case ANARI_UFIXED16:
            pixelFormat.mtlPixelFormat = MTLPixelFormatR16Unorm;
            break;
        case ANARI_UFIXED16_VEC2:
            pixelFormat.mtlPixelFormat = MTLPixelFormatRG16Unorm;
            break;
        case ANARI_UFIXED16_VEC3:
            if (allowChannelCountChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA16Unorm;
                pixelFormat.channelCountChangedTo4 = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_UFIXED16_VEC4:
            pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA16Unorm;
            break;
        case ANARI_FIXED32:
            if (allowSizeChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatR16Snorm;
                pixelFormat.sizeChanged = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_FIXED32_VEC2:
            if (allowSizeChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatRG16Snorm;
                pixelFormat.sizeChanged = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_FIXED32_VEC3:
            if (allowSizeChange && allowChannelCountChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA16Snorm;
                pixelFormat.sizeChanged = true;
                pixelFormat.channelCountChangedTo4 = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_FIXED32_VEC4:
            if (allowSizeChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA16Snorm;
                pixelFormat.sizeChanged = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_UFIXED32:
            if (allowSizeChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatR16Unorm;
                pixelFormat.sizeChanged = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_UFIXED32_VEC2:
            if (allowSizeChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatRG16Unorm;
                pixelFormat.sizeChanged = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_UFIXED32_VEC3:
            if (allowSizeChange && allowChannelCountChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA16Unorm;
                pixelFormat.sizeChanged = true;
                pixelFormat.channelCountChangedTo4 = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_UFIXED32_VEC4:
            if (allowSizeChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA16Unorm;
                pixelFormat.sizeChanged = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_FIXED64:
            if (allowSizeChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatR16Snorm;
                pixelFormat.sizeChanged = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_FIXED64_VEC2:
            if (allowSizeChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatRG16Snorm;
                pixelFormat.sizeChanged = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_FIXED64_VEC3:
            if (allowSizeChange && allowChannelCountChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA16Snorm;
                pixelFormat.sizeChanged = true;
                pixelFormat.channelCountChangedTo4 = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_FIXED64_VEC4:
            if (allowSizeChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA16Snorm;
                pixelFormat.sizeChanged = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_UFIXED64:
            if (allowSizeChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatR16Unorm;
                pixelFormat.sizeChanged = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_UFIXED64_VEC2:
            if (allowSizeChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatRG16Unorm;
                pixelFormat.sizeChanged = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_UFIXED64_VEC3:
            if (allowSizeChange && allowChannelCountChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA16Unorm;
                pixelFormat.sizeChanged = true;
                pixelFormat.channelCountChangedTo4 = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_UFIXED64_VEC4:
            if (allowSizeChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA16Unorm;
                pixelFormat.sizeChanged = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        
        //Floating-point formats
        case ANARI_FLOAT16:
            pixelFormat.mtlPixelFormat = MTLPixelFormatR16Float;
            break;
        case ANARI_FLOAT16_VEC2:
            pixelFormat.mtlPixelFormat = MTLPixelFormatRG16Float;
            break;
        case ANARI_FLOAT16_VEC3:
            if (allowChannelCountChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA16Float;
                pixelFormat.channelCountChangedTo4 = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_FLOAT16_VEC4:
            pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA16Float;
            break;
        case ANARI_FLOAT32:
            pixelFormat.mtlPixelFormat = MTLPixelFormatR32Float;
            break;
        case ANARI_FLOAT32_VEC2:
            pixelFormat.mtlPixelFormat = MTLPixelFormatRG32Float;
            break;
        case ANARI_FLOAT32_VEC3:
            if (allowChannelCountChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA32Float;
                pixelFormat.channelCountChangedTo4 = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_FLOAT32_VEC4:
            pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA32Float;
            break;
        case ANARI_FLOAT64:
            if (allowSizeChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatR32Float;
                pixelFormat.sizeChanged = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_FLOAT64_VEC2:
            if (allowSizeChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatRG32Float;
                pixelFormat.sizeChanged = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_FLOAT64_VEC3:
            if (allowSizeChange && allowChannelCountChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA32Float;
                pixelFormat.sizeChanged = true;
                pixelFormat.channelCountChangedTo4 = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_FLOAT64_VEC4:
            if (allowSizeChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA32Float;
                pixelFormat.sizeChanged = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        
        //Fixed sRGB formats
        case ANARI_UFIXED8_RGBA_SRGB:
            pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA8Unorm_sRGB;
            break;
        case ANARI_UFIXED8_RGB_SRGB:
            if (allowChannelCountChange) {
                pixelFormat.mtlPixelFormat = MTLPixelFormatRGBA8Unorm_sRGB;
                pixelFormat.channelCountChangedTo4 = true;
            } else
                pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_UFIXED8_RA_SRGB:
            pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        case ANARI_UFIXED8_R_SRGB:
            pixelFormat.mtlPixelFormat = MTLPixelFormatR8Unorm_sRGB;
            break;
        default:
            pixelFormat.mtlPixelFormat = MTLPixelFormatInvalid;
            break;
        }
    }

    return pixelFormat;
}

} //namespace helper

} //namespace anari_mtl
