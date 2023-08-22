#include "Light.h"

#include "DirectionalLight.h"

namespace anari_mtl {

Light::Light(AnariMetalGlobalState* s) : Object(ANARI_LIGHT, s) {
    s->objectCounts.lights++;
}

Light::~Light() {
    deviceState()->objectCounts.lights--;
}

Light* Light::createInstance(std::string_view type, AnariMetalGlobalState* s) {
    if (type == "directional")
        return new DirectionalLight(s);
    else
        return (Light*)new UnknownObject(ANARI_LIGHT, s);
}

void Light::commit() {
    color = getParam<float3>("color", float3(1.0f));
}

} //namespace anari_mtl

ANARI_METAL_TYPEFOR_DEFINITION(anari_mtl::Light*);
