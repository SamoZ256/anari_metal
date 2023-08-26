#pragma once

#include "../Object.h"

namespace anari_mtl {

class Camera : public Object {
protected:
    float3 up;
    float3 position;
    float3 direction;

    float4x4 projection;
    float4x4 view;
    float4x4 viewProj;

public:
    Camera(AnariMetalGlobalState* s);

    ~Camera() override;

    static Camera* createInstance(std::string_view type, AnariMetalGlobalState *s);

    virtual void commit() override;

    const float4x4& getViewProj() {
        return viewProj;
    }

    const float3& getPosition() {
        return position;
    }

    float3 getRight() {
        return cross(direction, up);
    }

    const float3& getUp() {
        return up;
    }

    const float3& getForward() {
        return direction;
    }
};

} //namespace anari_mtl

ANARI_METAL_TYPEFOR_SPECIALIZATION(anari_mtl::Camera*, ANARI_CAMERA);
