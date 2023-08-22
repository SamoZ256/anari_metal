#include "Frame.h"

#include "../metal_helper/MetalHelper.h"

namespace anari_mtl {

Frame::Frame(AnariMetalGlobalState* s) : helium::BaseFrame(s), state(s) {
    s->objectCounts.frames++;
}

Frame::~Frame() {
    deviceState()->objectCounts.frames--;

    if (mtlColorTexture)
        [mtlColorTexture release];
    if (mtlDepthTexture)
        [mtlDepthTexture release];
}

void Frame::commit() {
    world = getParamObject<World>("world");
    if (!world)
        reportMessage(ANARI_SEVERITY_ERROR, "frame requires a 'world' parameter");
    camera = getParamObject<Camera>("camera");
    if (!camera)
        reportMessage(ANARI_SEVERITY_ERROR, "frame requires a 'camera' parameter");
    renderer = getParamObject<Renderer>("renderer");
    if (!renderer)
        reportMessage(ANARI_SEVERITY_ERROR, "frame requires a 'renderer' parameter");
    size = getParam<uint2>("size", uint2(16));
    if (size.x == 0 || size.y == 0)
        reportMessage(ANARI_SEVERITY_ERROR, "size of frame cannot be 0");
    colorFormat = getParam("channel.color", ANARI_UNKNOWN);
    depthFormat = getParam("channel.depth", ANARI_UNKNOWN);
}

void Frame::renderFrame() {
    deviceState()->commitBuffer.flush();

    MTLTextureDescriptor* textureDescriptor = [[MTLTextureDescriptor alloc] init];
    textureDescriptor.textureType = MTLTextureType2D;
    textureDescriptor.width = size.x;
    textureDescriptor.height = size.y;
    textureDescriptor.depth = 1;
    textureDescriptor.storageMode = MTLStorageModePrivate;
    textureDescriptor.usage = MTLTextureUsageRenderTarget;
    if (colorFormat != ANARI_UNKNOWN && !mtlColorTexture) {
        textureDescriptor.pixelFormat = MTLPixelFormatRGBA8Unorm_sRGB; //TODO: set according to parameters
        mtlColorTexture = [deviceState()->mtlDevice newTextureWithDescriptor:textureDescriptor];
    }
    depthFormat = 1;
    if (depthFormat != ANARI_UNKNOWN && !mtlDepthTexture) {
        textureDescriptor.pixelFormat = MTLPixelFormatDepth32Float; //TODO: set according to parameters
        mtlDepthTexture = [deviceState()->mtlDevice newTextureWithDescriptor:textureDescriptor];
    }
    renderer->renderFrame(world, camera, mtlColorTexture, mtlDepthTexture);
}

void* Frame::map(std::string_view channel, uint32_t *width, uint32_t *height, ANARIDataType *pixelType) {
    id<MTLTexture> textureToMap;
    if (channel == "channel.color") {
        if (!mtlColorTexture) {
            reportMessage(ANARI_SEVERITY_ERROR, "cannot map the color channel of frame which does not have a color texture or hasn't been rendered to");
            return nullptr;
        }
        textureToMap = mtlColorTexture;
    } else if (channel == "channel.depth") {
        if (!mtlDepthTexture) {
            reportMessage(ANARI_SEVERITY_ERROR, "cannot map the depth channel of frame which does not have a depth texture or hasn't been rendered to");
            return nullptr;
        }
        textureToMap = mtlDepthTexture;
    } else {
        reportMessage(ANARI_SEVERITY_ERROR, "unknown frame channel to map");
        return nullptr;
    }

    mtlMappedBuffer = [deviceState()->mtlDevice newBufferWithLength:size.x * size.y * bytesPerPixel options:MTLResourceStorageModeShared];
    helper::copyTextureToBuffer(deviceState()->mtlCommandQueue, textureToMap, mtlMappedBuffer, uint3(size.x, size.y, 1), bytesPerPixel, 0);

    *width = size.x;
    *height = size.y;
    *pixelType = ANARI_UFIXED8_RGBA_SRGB; //TODO: return the actual pixel type

    return [mtlMappedBuffer contents];
}

void Frame::unmap(std::string_view channel) {
    if (!mtlMappedBuffer) {
        reportMessage(ANARI_SEVERITY_WARNING, "cannot unmap a frame that has not been previously mapped");
        return;
    }
    [mtlMappedBuffer release];
    mtlMappedBuffer = nullptr;
}

} //namespace anari_mtl

ANARI_METAL_TYPEFOR_DEFINITION(anari_mtl::Frame*);
