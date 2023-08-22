#include "Sampler.h"

#include "ImageSampler.h"

namespace anari_mtl {

Sampler::Sampler(AnariMetalGlobalState* s) : Object(ANARI_SAMPLER, s) {
    s->objectCounts.samplers++;
}

Sampler::~Sampler() {
    deviceState()->objectCounts.samplers++;

    if (mtlSamplerState)
        [mtlSamplerState release];
}

Sampler* Sampler::createInstance(std::string_view type, AnariMetalGlobalState* s) {
    if (type == "image1D")
        return new ImageSampler(s, ImageType::_1D);
    else if (type == "image2D")
        return new ImageSampler(s, ImageType::_2D);
    else if (type == "image3D")
        return new ImageSampler(s, ImageType::_3D);
    else
        return (Sampler*)new UnknownObject(ANARI_SAMPLER, s);
}

void Sampler::commit() {
    //TODO
}

void Sampler::bindToShader(id encoder, uint8_t index) {
    [encoder setFragmentSamplerState:mtlSamplerState atIndex:index];
}

void Sampler::initMTLSamplerState() {
    //TODO: release and set to nullptr if changed

    if (!mtlSamplerState) {
        MTLSamplerDescriptor* samplerDescriptor = [[MTLSamplerDescriptor alloc] init];
        samplerDescriptor.magFilter = MTLSamplerMinMagFilterLinear; //TODO: set this based on parameters
        samplerDescriptor.minFilter = MTLSamplerMinMagFilterLinear;
        samplerDescriptor.rAddressMode = MTLSamplerAddressModeClampToEdge; //TODO: set this based on parameters
        samplerDescriptor.sAddressMode = MTLSamplerAddressModeClampToEdge;
        samplerDescriptor.tAddressMode = MTLSamplerAddressModeClampToEdge;
        mtlSamplerState = [deviceState()->mtlDevice newSamplerStateWithDescriptor:samplerDescriptor];
    }
}

} //namespace anari_mtl

ANARI_METAL_TYPEFOR_DEFINITION(anari_mtl::Sampler*);
