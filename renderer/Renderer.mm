#include "Renderer.h"

#include "DefaultRenderer.h"
#include "HybridRenderer.h"

namespace anari_mtl {

Renderer::Renderer(AnariMetalGlobalState* s) : Object(ANARI_RENDERER, s) {
    s->objectCounts.renderers++;
}

Renderer::~Renderer() {
    deviceState()->objectCounts.renderers--;
}

Renderer* Renderer::createInstance(std::string_view type, AnariMetalGlobalState* s) {
    if (type == "default")
        return new DefaultRenderer(s);
    else if (type == "hybrid")
        return new HybridRenderer(s);
    else
        return (Renderer*)new UnknownObject(ANARI_RENDERER, s);
}

void Renderer::commit() {
    clearColor = getParam<float4>("background", float4(0.0f, 0.0f, 0.0f, 1.0f));
}

void Renderer::cleanup() {
    //TODO
}

bool Renderer::ready() {
    if (!commandBuffer) {
        reportMessage(ANARI_SEVERITY_WARNING, "renderer that hasn't rendered yet is always ready");
        return true;
    }
    return ([commandBuffer status] == MTLCommandBufferStatusCompleted);
}

void Renderer::wait() {
    if (!commandBuffer) {
        reportMessage(ANARI_SEVERITY_WARNING, "cannot wait on a renderer that has not rendered anything yet");
        return;
    }
    [commandBuffer waitUntilCompleted];
}

} //namespace anari_mtl

ANARI_METAL_TYPEFOR_DEFINITION(anari_mtl::Renderer*);
