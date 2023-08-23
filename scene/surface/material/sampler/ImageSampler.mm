#include "ImageSampler.h"

#include "../../../../metal_helper/MetalHelper.h"

namespace anari_mtl {

ImageSampler::~ImageSampler() {
    if (mtlTexture)
        [mtlTexture release];
}

void ImageSampler::commit() {
    Sampler::commit();

    array = getParamObject<Array>("image");
    //TODO: handle this differently
    if (!array)
        reportMessage(ANARI_SEVERITY_ERROR, "'image' parameter of Sampler not set");

    initMTLSamplerState();
    initMTLTexture();
}

void ImageSampler::bindToShader(id encoder, uint8_t index) {
    Sampler::bindToShader(encoder, index);

    [encoder setFragmentTexture:mtlTexture atIndex:index];
}

void ImageSampler::initMTLTexture() {
    //TODO: release and set to nullptr if changed

    if (!mtlTexture) {
        helper::PixelFormat pixelFormat = helper::getMTLPixelFormatFromANARIDataType(array->getDataType(), false, false, true);
        void* data;
        size_t bytesPerPixel;
        size_t size;
        if (pixelFormat.channelCountChangedTo4) {
            reportMessage(ANARI_SEVERITY_DEBUG, "Image sampler has an RGB data type, translating to RGBA");
            size_t elementComponentSize = anari::sizeOf(array->getDataType()) / 3;
            bytesPerPixel = elementComponentSize * 4;
            size = array->getElementCount() * bytesPerPixel;
            data = malloc(size);
            for (uint32_t i = 0; i < array->getElementCount(); i++) {
                memcpy((char*)data + i * bytesPerPixel, array->getAtIndex(i), anari::sizeOf(array->getDataType()));
                *(float*)((char*)data + i * bytesPerPixel + 3 * elementComponentSize) = 1.0f;
            }
        } else {
            data = const_cast<void*>(array->getData());
            bytesPerPixel = anari::sizeOf(array->getDataType());
            size = array->getSize();
        }

        id<MTLBuffer> buffer = [deviceState()->mtlDevice newBufferWithBytes:data length:size options:MTLResourceStorageModeShared];

        MTLTextureType textureType;
        switch (imageType) {
        case ImageType::_1D:
            textureType = MTLTextureType1D;
            break;
        case ImageType::_2D:
            textureType = MTLTextureType2D;
            break;
        case ImageType::_3D:
            textureType = MTLTextureType3D;
            break;
        }

        MTLTextureDescriptor* textureDescriptor = [[MTLTextureDescriptor alloc] init];
        textureDescriptor.textureType = textureType;
        textureDescriptor.pixelFormat = pixelFormat.mtlPixelFormat;
        textureDescriptor.width = array->getDimensions().x;
        textureDescriptor.height = array->getDimensions().y;
        textureDescriptor.depth = array->getDimensions().z;
        textureDescriptor.storageMode = MTLStorageModePrivate;
        textureDescriptor.usage = MTLTextureUsageShaderRead;

        mtlTexture = [deviceState()->mtlDevice newTextureWithDescriptor:textureDescriptor];

        helper::copyBufferToTexture(deviceState()->mtlCommandQueue, buffer, mtlTexture, array->getDimensions(), bytesPerPixel, 0); //TODO: bytesPerPixel
    }
}

} //namespace anari_mtl
