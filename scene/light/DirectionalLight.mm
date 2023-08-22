#include "DirectionalLight.h"

namespace anari_mtl {

void DirectionalLight::commit() {
    Light::commit();

    uniforms.color = color;
    uniforms.direction = getParam<float3>("direction", normalize(float3(2.0f, -4.0f, 3.0f))); //TODO: set the default light direction to glm::vec3(0.0f, 0.0f, -1.0f)
}

void DirectionalLight::uploadToShader(id encoder) {
    [encoder setFragmentBytes:&uniforms length:sizeof(uniforms) atIndex:1];
}

} //namespace anari_mtl
