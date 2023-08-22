#include "Matte.h"

namespace anari_mtl {

void Matte::commit() {
    Material::commit();

    uniforms.color = float4(1.0f, 1.0f, 1.0f, 1.0f);
    getParam("color", ANARI_FLOAT32_VEC3, &uniforms.color);
    getParam("color", ANARI_FLOAT32_VEC4, &uniforms.color);
    //TODO: support this
    //colorAttribute = attributeFromString(getParamString("color", "none"));
    colorSampler = getParamObject<Sampler>("color");

    opacity = getParam<float>("opacity", 1.0f);
    //TODO: support this
    //opacityAttribute = attributeFromString(getParamString("opacity", "none"));
    //TODO: uncomment
    //opacitySampler = getParamObject<Sampler>("opacity");

    //TODO: do not get these parameters
    uniforms.metallic = getParam<float>("metallic", 1.0f);
    uniforms.roughness = getParam<float>("roughness", 1.0f);
}

void Matte::uploadToShader(id encoder) {
    Material::uploadToShader(encoder);

    [encoder setFragmentBytes:&uniforms length:sizeof(uniforms) atIndex:2];
    if (colorSampler)
        colorSampler->bindToShader(encoder, 0);
}

} //namespace anari_mtl
