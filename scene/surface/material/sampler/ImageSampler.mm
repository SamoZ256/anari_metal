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
        id<MTLBuffer> buffer = [deviceState()->mtlDevice newBufferWithBytes:array->getData() length:array->getSize() options:MTLResourceStorageModeShared];

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
        textureDescriptor.pixelFormat = MTLPixelFormatRGBA8Unorm_sRGB; //TODO: only use sRGB in case of albedo
        textureDescriptor.width = array->getDimensions().x;
        textureDescriptor.height = array->getDimensions().y;
        textureDescriptor.depth = array->getDimensions().z;
        textureDescriptor.storageMode = MTLStorageModePrivate;
        textureDescriptor.usage = MTLTextureUsageShaderRead;

        mtlTexture = [deviceState()->mtlDevice newTextureWithDescriptor:textureDescriptor];

        helper::copyBufferToTexture(deviceState()->mtlCommandQueue, buffer, mtlTexture, array->getDimensions(), anari::sizeOf(array->getDataType()), 0); //TODO: bytesPerPixel
    }
}

} //namespace anari_mtl
