#include "HybridRenderer.h"

namespace anari_mtl {

HybridRenderer::~HybridRenderer() {
    if (pipeline)
        delete pipeline;
    if (gbufferDepthStencilState)
        [gbufferDepthStencilState release];
    if (deferredDepthStencilState)
        [deferredDepthStencilState release];
    if (commandBuffer)
        [commandBuffer release];
    //TODO: release textures
}

void HybridRenderer::commit() {
    //Empty
}

void HybridRenderer::renderFrame(World* world, Camera* camera, id colorTexture, id depthTexture) {
    if (commandBuffer)
        [commandBuffer release];
    commandBuffer = [deviceState()->mtlCommandQueue commandBuffer];

    MTLTextureDescriptor* textureDescriptor = [[MTLTextureDescriptor alloc] init];
    textureDescriptor.textureType = MTLTextureType2D;
    textureDescriptor.width = [colorTexture width];
    textureDescriptor.height = [colorTexture height];
    textureDescriptor.depth = 1;
    textureDescriptor.storageMode = MTLStorageModeMemoryless;
    textureDescriptor.usage = MTLTextureUsageRenderTarget;
    if (!albedoMetallicTexture) {
        textureDescriptor.pixelFormat = MTLPixelFormatRGBA16Unorm;
        albedoMetallicTexture = [deviceState()->mtlDevice newTextureWithDescriptor:textureDescriptor];
    }
    if (!normalRoughnessTexture) {
        textureDescriptor.pixelFormat = MTLPixelFormatRGBA8Snorm;
        normalRoughnessTexture = [deviceState()->mtlDevice newTextureWithDescriptor:textureDescriptor];
    }

    if (!pipeline)
        pipeline = new HybridPipeline(deviceState()->mtlDevice);

    if (depthTexture) {
        if (!gbufferDepthStencilState) {
            MTLDepthStencilDescriptor* depthStencilDescriptor = [[MTLDepthStencilDescriptor alloc] init];
            depthStencilDescriptor.depthCompareFunction = MTLCompareFunctionLess;
            depthStencilDescriptor.depthWriteEnabled = YES;
            gbufferDepthStencilState = [deviceState()->mtlDevice newDepthStencilStateWithDescriptor:depthStencilDescriptor];
        }
        if (!deferredDepthStencilState) {
            MTLDepthStencilDescriptor* depthStencilDescriptor = [[MTLDepthStencilDescriptor alloc] init];
            depthStencilDescriptor.depthCompareFunction = MTLCompareFunctionNotEqual;
            depthStencilDescriptor.depthWriteEnabled = NO;
            deferredDepthStencilState = [deviceState()->mtlDevice newDepthStencilStateWithDescriptor:depthStencilDescriptor];
        }
    }

    MTLRenderPassDescriptor* renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    if (colorTexture) {
        renderPassDescriptor.colorAttachments[0].texture = colorTexture;
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(clearColor.x, clearColor.y, clearColor.z, clearColor.w);
    }
    renderPassDescriptor.colorAttachments[1].texture = albedoMetallicTexture;
    renderPassDescriptor.colorAttachments[1].loadAction = MTLLoadActionDontCare;
    renderPassDescriptor.colorAttachments[1].storeAction = MTLStoreActionDontCare;
    renderPassDescriptor.colorAttachments[2].texture = normalRoughnessTexture;
    renderPassDescriptor.colorAttachments[2].loadAction = MTLLoadActionDontCare;
    renderPassDescriptor.colorAttachments[2].storeAction = MTLStoreActionDontCare;
    if (depthTexture) {
        renderPassDescriptor.depthAttachment.texture = depthTexture;
        renderPassDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
        renderPassDescriptor.depthAttachment.storeAction = MTLStoreActionStore;
        renderPassDescriptor.depthAttachment.clearDepth = 1.0f;
    }

    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:(MTLRenderPassDescriptor*)renderPassDescriptor];

    if (depthTexture)
        [encoder setDepthStencilState:gbufferDepthStencilState];

    const float4x4& viewProj = camera->getViewProj();
    [encoder setVertexBytes:&viewProj length:sizeof(float4x4) atIndex:0];

    std::vector<Renderable> renderables;

    Array* instances = world->getInstances();
    if (instances) {
        for (uint32_t i = 0; i < instances->getElementCount(); i++) {
            Object* instance = instances->getObjectAtIndex(i);
            instance->getRenderables(renderables, identity);
        }
    }

    Array* surfaces = world->getSurfaces();
    if (surfaces) {
        for (uint32_t i = 0; i < surfaces->getElementCount(); i++) {
            Object* surface = surfaces->getObjectAtIndex(i);
            surface->getRenderables(renderables, identity);
        }
    }

    for (auto& renderable : renderables) {
        pipeline->bind(encoder, renderable.config, colorTexture, depthTexture, albedoMetallicTexture, normalRoughnessTexture);
        renderable.object->render(encoder, renderable.modelMatrix);
    }

    pipeline->unbind();

    pipeline->bindDeferred(encoder, colorTexture, albedoMetallicTexture, normalRoughnessTexture, depthTexture);
    if (depthTexture)
        [encoder setDepthStencilState:deferredDepthStencilState];

    const float3& viewPos = camera->getPosition();
    [encoder setFragmentBytes:&viewPos length:sizeof(float3) atIndex:0];
    float4x4 invViewProj = inverse(viewProj);
    [encoder setFragmentBytes:&invViewProj length:sizeof(float4x4) atIndex:2];

    Array* lights = world->getLights();
    if (lights) {
        if (lights->getElementCount() != 1)
            reportMessage(ANARI_SEVERITY_WARNING, "world should have exactly 1 light");
        for (uint32_t i = 0; i < lights->getElementCount(); i++) {
            Light* light = dynamic_cast<Light*>(lights->getObjectAtIndex(i));
            if (!light) {
                reportMessage(ANARI_SEVERITY_ERROR, "object in array of lights is not a light");
                break;
            }
            light->uploadToShader(encoder);
        }
    }

    //Draw a triangle covering the whole screen
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];

    [encoder endEncoding];
    [commandBuffer commit];

    [encoder release];
}

} //namespace anari_mtl
