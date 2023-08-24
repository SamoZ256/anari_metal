#include "DefaultRenderer.h"

namespace anari_mtl {

DefaultRenderer::~DefaultRenderer() {
    if (pipeline)
        delete pipeline;
    if (mainDepthStencilState)
        [mainDepthStencilState release];
    if (commandBuffer)
        [commandBuffer release];
}

void DefaultRenderer::commit() {
    //Empty
}

void DefaultRenderer::renderFrame(World* world, Camera* camera, id colorTexture, id depthTexture) {
    if (commandBuffer)
        [commandBuffer release];
    commandBuffer = [deviceState()->mtlCommandQueue commandBuffer];

    if (!pipeline)
        pipeline = new ForwardPipeline(deviceState()->mtlDevice);

    if (!mainDepthStencilState && depthTexture) {
        MTLDepthStencilDescriptor* depthStencilDescriptor = [[MTLDepthStencilDescriptor alloc] init];
        depthStencilDescriptor.depthCompareFunction = MTLCompareFunctionLess;
        depthStencilDescriptor.depthWriteEnabled = YES;
        mainDepthStencilState = [deviceState()->mtlDevice newDepthStencilStateWithDescriptor:depthStencilDescriptor];
    }

    MTLRenderPassDescriptor* renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    if (colorTexture) {
        renderPassDescriptor.colorAttachments[0].texture = colorTexture;
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(clearColor.x, clearColor.y, clearColor.z, clearColor.w);
        if (depthTexture) {
            renderPassDescriptor.depthAttachment.texture = depthTexture;
            renderPassDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
            renderPassDescriptor.depthAttachment.storeAction = MTLStoreActionStore;
            renderPassDescriptor.depthAttachment.clearDepth = 1.0f;
        }
    }

    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:(MTLRenderPassDescriptor*)renderPassDescriptor];

    if (depthTexture)
        [encoder setDepthStencilState:mainDepthStencilState];

    const float4x4& viewProj = camera->getViewProj();
    [encoder setVertexBytes:&viewProj length:sizeof(float4x4) atIndex:0];
    const float3& viewPos = camera->getPosition();
    [encoder setFragmentBytes:&viewPos length:sizeof(float3) atIndex:0];

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
        pipeline->bind(encoder, renderable.config, colorTexture, depthTexture, nullptr, nullptr);
        renderable.object->render(encoder, renderable.modelMatrix);
    }

    pipeline->unbind();

    [encoder endEncoding];
    [commandBuffer commit];

    [encoder release];
}

} //namespace anari_mtl
