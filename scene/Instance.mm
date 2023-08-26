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

void Instance::buildAccelerationStructureAndAddGeometryToList(void* list) {
    group->buildAccelerationStructureAndAddGeometryToList(list);
}

void Instance::createInstanceAccelerationStructureDescriptor(void* instanceDescriptor) {
    //TODO: implement this
    //for (every geometry)
    //  helper::createInstanceAccelerationStructureDescriptor(*((MTLAccelerationStructureInstanceDescriptor*)instanceDescriptor), geometry->getUUID(), modelMatrix);
}

} //namespace anari_mtl

ANARI_METAL_TYPEFOR_DEFINITION(anari_mtl::Instance*);
