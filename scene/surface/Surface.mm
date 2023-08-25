#include "Surface.h"

namespace anari_mtl {

id <MTLAccelerationStructure> createMTLAccelerationStructure(id<MTLDevice> device, id<MTLCommandQueue> commandQueue, MTLAccelerationStructureDescriptor *descriptor) {
    MTLAccelerationStructureSizes accelSizes = [device accelerationStructureSizesWithDescriptor:descriptor];

    id <MTLAccelerationStructure> accelerationStructure = [device newAccelerationStructureWithSize:accelSizes.accelerationStructureSize];

    id <MTLBuffer> scratchBuffer = [device newBufferWithLength:accelSizes.buildScratchBufferSize options:MTLResourceStorageModePrivate];

    id <MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];

    id <MTLAccelerationStructureCommandEncoder> commandEncoder = [commandBuffer accelerationStructureCommandEncoder];

    id <MTLBuffer> compactedSizeBuffer = [device newBufferWithLength:sizeof(uint32_t) options:MTLResourceStorageModeShared];

    [commandEncoder buildAccelerationStructure:accelerationStructure
                                    descriptor:descriptor
                                 scratchBuffer:scratchBuffer
                           scratchBufferOffset:0];

    [commandEncoder writeCompactedAccelerationStructureSize:accelerationStructure
                                                   toBuffer:compactedSizeBuffer
                                                     offset:0];

    [commandEncoder endEncoding];
    [commandBuffer commit];

    [commandBuffer waitUntilCompleted];

    uint32_t compactedSize = *(uint32_t*)compactedSizeBuffer.contents;

    id <MTLAccelerationStructure> compactedAccelerationStructure = [device newAccelerationStructureWithSize:compactedSize];

    commandBuffer = [commandQueue commandBuffer];

    commandEncoder = [commandBuffer accelerationStructureCommandEncoder];

    [commandEncoder copyAndCompactAccelerationStructure:accelerationStructure
                                toAccelerationStructure:compactedAccelerationStructure];

    [commandEncoder endEncoding];
    [commandBuffer commit];

    return compactedAccelerationStructure;
}

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

id Surface::buildAccelerationStructure() {
    if (!builtAccelerationStructure) {
        //TODO: make this a geometry descriptor, not triangle geometry descriptor
        MTLAccelerationStructureTriangleGeometryDescriptor* geometryDescriptor = (MTLAccelerationStructureTriangleGeometryDescriptor*)geometry->getGeometryDescriptor();
        
        MTLPrimitiveAccelerationStructureDescriptor *accelDescriptor = [MTLPrimitiveAccelerationStructureDescriptor descriptor];
        accelDescriptor.geometryDescriptors = @[geometryDescriptor];

        id<MTLAccelerationStructure> accelerationStructure = createMTLAccelerationStructure(deviceState()->mtlDevice, deviceState()->mtlCommandQueue, accelDescriptor);

        builtAccelerationStructure = true;
    }

    return mtlAccelerationStructure;
}

} //namespace anari_mtl
