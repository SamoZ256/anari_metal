#include "Geometry.h"

#include "TriangleGeometry.h"

#include "../../../metal_helper/MetalHelper.h"

namespace anari_mtl {

Geometry::Geometry(AnariMetalGlobalState* s) : Object(ANARI_GEOMETRY, s) {
    s->objectCounts.geometries++;
}

Geometry::~Geometry() {
    deviceState()->objectCounts.geometries--;
}

void Geometry::commit() {
    INDEX_ATTR = getParamObject<Array>("primitive.index");
    //TODO: uncomment
    //ATTRIBUTE_ATTR(0) = getParamObject<Array>("primitive.attribute0");
    //ATTRIBUTE_ATTR(1) = getParamObject<Array>("primitive.attribute1");
    //ATTRIBUTE_ATTR(2) = getParamObject<Array>("primitive.attribute2");
    //ATTRIBUTE_ATTR(3) = getParamObject<Array>("primitive.attribute3");
}

Geometry* Geometry::createInstance(std::string_view type, AnariMetalGlobalState* s) {
    if (type == "triangle")
        return new TriangleGeometry(s);
    else
        return (Geometry*)new UnknownObject(ANARI_GEOMETRY, s);
}

void Geometry::initMTLBuffers() {
    bool hasChanged = false;
    for (uint8_t i = 0; i < GEOMETRY_ATTRIBUTES_ARRAY_COUNT; i++) {
        if (attributes[i] != oldAttributes[i]) {
            hasChanged = true;
            break;
        }
    }
    if (!hasChanged)
        return;
    
    for (uint8_t i = 0; i < GEOMETRY_ATTRIBUTES_ARRAY_COUNT; i++) {
        if (mtlBuffers[i])
            [mtlBuffers[i] release];
        mtlBuffers[i] = nullptr;
    }

    for (uint8_t i = 0; i < GEOMETRY_ATTRIBUTES_ARRAY_COUNT; i++) {
        if (attributes[i]) {
            //HACK: using private storage mode causes segfault when allocating too big buffer (20mb >), probably running out of private memory?
            mtlBuffers[i] = [deviceState()->mtlDevice newBufferWithBytes:attributes[i]->getData() length:attributes[i]->getSize() options:MTLResourceStorageModeShared];
        }
        oldAttributes[i] = attributes[i];
    }
}

void Geometry::render(id encoder, const float4x4& modelMatrix, bool useMaterial) {
    [encoder setVertexBytes:&modelMatrix length:sizeof(float4x4) atIndex:1];
    [encoder setVertexBuffer:POSITION_BUFFER offset:0 atIndex:BUFFER_BINDING_INDEX(POSITION_I)];
    if (ATTRIBUTE_ATTR(0))
        [encoder setVertexBuffer:ATTRIBUTE_BUFFER(0) offset:0 atIndex:BUFFER_BINDING_INDEX(ATTRIBUTE_I(0))];
    [encoder setVertexBuffer:NORMAL_BUFFER offset:0 atIndex:BUFFER_BINDING_INDEX(NORMAL_I)];
    if (COLOR_ATTR)
        [encoder setVertexBuffer:COLOR_BUFFER offset:0 atIndex:BUFFER_BINDING_INDEX(COLOR_I)];
    if (INDEX_ATTR)
        [encoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:INDEX_ATTR->getSize() / sizeof(uint32_t) indexType:MTLIndexTypeUInt32 indexBuffer:INDEX_BUFFER indexBufferOffset:0]; //TODO: set index type based on the array type
    else
        [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:POSITION_ATTR->getElementCount()];
    //TODO: bind other attribute buffers
}

Bounds Geometry::getBounds(const float4x4& parentModelMatrix) {
    Bounds bounds;
    for (uint32_t i = 0; i < POSITION_ATTR->getElementCount(); i++) {
        float3 vert = mul(parentModelMatrix, float4(POSITION_ATTR->getAtIndexAs<float3>(i), 1.0f)).xyz();
        bounds.min = min(bounds.min, vert);
        bounds.max = max(bounds.max, vert);
    }

    return bounds;
}

} //namespace anari_mtl
