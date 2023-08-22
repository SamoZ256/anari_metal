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

} //namespace helper

} //namespace anari_mtl
