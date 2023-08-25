#include "Instance.h"

namespace anari_mtl {

Instance::Instance(AnariMetalGlobalState* s) : Object(ANARI_INSTANCE, s) {
    s->objectCounts.instances++;
}

Instance::~Instance() {
    deviceState()->objectCounts.instances--;
}

void Instance::commit() {
    group = getParamObject<Group>("group");
    if (!group)
        reportMessage(ANARI_SEVERITY_ERROR, "instance requires a 'group' parameter");
    modelMatrix = getParam<float4x4>("transform", identity);
    //printf("Matrix: %s, has transform param: %u\n", glm::to_string(modelMatrix).c_str(), hasParam("transform"));
}

void Instance::getRenderables(std::vector<Renderable>& renderables, const float4x4& parentModelMatrix) {
    group->getRenderables(renderables, mul(parentModelMatrix, modelMatrix));
}

Bounds Instance::getBounds(const float4x4& parentModelMatrix) {
    return group->getBounds(mul(parentModelMatrix, modelMatrix));
}

void Instance::buildAccelerationStructure(void* instanceDescriptor) {
    if (!builtAccelerationStructure) {
        NSMutableArray* accelerationStructures = (NSMutableArray*)group->buildAccelerationStructures();

        /*
        NSUInteger geometryIndex = 255;//[scene.geometries indexOfObject:instance.geometry]
        for (uint32_t i = 0; i < scene.geometries.size(); i++) {
            if (scene.geometries[i] == instance->geometry) {
                geometryIndex = i;
                break;
            }
        }

        // Map the instance to its acceleration structure.
        instanceDescriptors[instanceIndex].accelerationStructureIndex = (uint32_t)geometryIndex;
        instanceDescriptors[instanceIndex].options = MTLAccelerationStructureInstanceOptionOpaque;
        instanceDescriptors[instanceIndex].intersectionFunctionTableOffset = 0;
        instanceDescriptors[instanceIndex].mask = 1;

        for (int column = 0; column < 4; column++)
            for (int row = 0; row < 3; row++)
                instanceDescriptors[instanceIndex].transformationMatrix.columns[column][row] = instance->transform[column][row];
        */

        builtAccelerationStructure = true;
    }
}

} //namespace anari_mtl

ANARI_METAL_TYPEFOR_DEFINITION(anari_mtl::Instance*);
