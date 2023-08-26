#include "Surface.h"

#include "metal_helper/MetalHelper.h"

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

void Surface::render(id encoder, const float4x4& modelMatrix, bool useMaterial) {
    if (useMaterial)
        material->uploadToShader(encoder);
    geometry->render(encoder, modelMatrix);
}

void Surface::getRenderables(std::vector<Renderable>& renderables, const float4x4& parentModelMatrix) {
    renderables.push_back({this, parentModelMatrix, PipelineConfig{geometry->hasColors(), geometry->hasTexCoords()}});
}

Bounds Surface::getBounds(const float4x4& parentModelMatrix) {
    return geometry->getBounds(parentModelMatrix);
}

void Surface::buildAccelerationStructureAndAddGeometryToList(void* list) {
    geometry->buildAccelerationStructureAndAddToList(list);
}

void Surface::createInstanceAccelerationStructureDescriptor(void* instanceDescriptor) {
    helper::createInstanceAccelerationStructureDescriptor(*((MTLAccelerationStructureInstanceDescriptor*)instanceDescriptor), geometry->getUUID(), identity);
}

NSMutableArray<id<MTLResource>>* Surface::getResources(float4* color, bool* hasColorTexture) {
    NSMutableArray* resources = @[ geometry->getIndexBuffer(), geometry->getNormalBuffer() ];
    id texCoordBuffer = geometry->getTexCoordBuffer();
    if (texCoordBuffer)
        [resources addObject:texCoordBuffer];
    id colorTexture = material->getColorTexture();
    if (colorTexture) {
        [resources addObject:colorTexture];
        if (hasColorTexture)
            *hasColorTexture = true;
    } else {
        if (color)
            *color = material->getColor();
        if (hasColorTexture)
            *hasColorTexture = false;
    }

    return resources;
}

} //namespace anari_mtl
