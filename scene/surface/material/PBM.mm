#include "PBM.h"

namespace anari_mtl {

void PBM::commit() {
    uniforms.albedo = float4(1.0f, 1.0f, 1.0f, 1.0f);
    getParam("baseColor", ANARI_FLOAT32_VEC3, &uniforms.albedo);
    getParam("baseColor", ANARI_FLOAT32_VEC4, &uniforms.albedo);
    //TODO: support this
    //colorAttribute = attributeFromString(getParamString("baseColor", "none"));
    albedoSampler = getParamObject<Sampler>("baseColor");

    opacity = getParam<float>("opacity", 1.0f);
    //TODO: support this
    //opacityAttribute = attributeFromString(getParamString("opacity", "none"));
    //TODO: uncomment
    //opacitySampler = getParamObject<Sampler>("opacity");

    uniforms.metallic = getParam<float>("metallic", 1.0f);
    uniforms.roughness = getParam<float>("roughness", 1.0f);
}

void PBM::uploadToShader(id encoder) {
    Material::uploadToShader(encoder);

    [encoder setFragmentBytes:&uniforms length:sizeof(uniforms) atIndex:2];
    if (albedoSampler)
        albedoSampler->bindToShader(encoder, 0);
}

} //namespace anari_mtl
