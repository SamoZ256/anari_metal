#include "Surface.h"

namespace anari_mtl {

Surface::Surface(AnariMetalGlobalState* s) : Object(ANARI_SURFACE, s) {
    s->objectCounts.surfaces++;
}

Surface::~Surface() {
    deviceState()->objectCounts.surfaces--;
}

void Surface::commit() {
    geometry = getParamObject<Geometry>("geometry");
    material = getParamObject<Material>("material");

    if (!material)
        reportMessage(ANARI_SEVERITY_WARNING, "missing 'material' on ANARISurface");

    if (!geometry)
        reportMessage(ANARI_SEVERITY_WARNING, "missing 'geometry' on ANARISurface");
}

void Surface::render(id encoder, const float4x4& modelMatrix) {
    material->uploadToShader(encoder);
    geometry->render(encoder, modelMatrix);
}

void Surface::getRenderables(std::vector<Renderable>& renderables, const float4x4& parentModelMatrix) {
    renderables.push_back({this, parentModelMatrix, ForwardPipelineConfig{geometry->hasColors(), geometry->hasTexCoords()}});
}

Bounds Surface::getBounds(const float4x4& parentModelMatrix) {
    return geometry->getBounds(parentModelMatrix);
}

} //namespace anari_mtl
