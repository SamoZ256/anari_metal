#include "Material.h"

#include "Matte.h"
#include "PBM.h"

namespace anari_mtl {

Material::Material(AnariMetalGlobalState* s) : Object(ANARI_MATERIAL, s) {
    s->objectCounts.materials++;
}

Material::~Material() {
    deviceState()->objectCounts.materials--;
}

Material* Material::createInstance(std::string_view type, AnariMetalGlobalState* s) {
    if (type == "matte")
        return new Matte(s);
    else if (type == "physicallyBased")
        return new PBM(s);
    else
        return (Material*)new UnknownObject(ANARI_MATERIAL, s);
}

void Material::commit() {
    std::string alphaModeStr = getParamString("alphaMode", "opaque");
    if (alphaModeStr == "opaque") {
        alphaMode = AlphaMode::Opaque;
    } else if (alphaModeStr == "mask") {
        alphaMode = AlphaMode::Mask;
    } else if (alphaModeStr == "blend") {
        alphaMode = AlphaMode::Blend;
    } else {
        reportMessage(ANARI_SEVERITY_WARNING, "Unknown alpha mode '%s', switching to 'opaque'", alphaModeStr.c_str());
        alphaMode = AlphaMode::Opaque;
    }
    alphaCutoff = getParam<float>("alphaCutoff", 0.5f);
}

void Material::uploadToShader(id encoder) {
    //TODO
}

} //namespace anari_mtl
