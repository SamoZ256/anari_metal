#pragma once

#include "AnariMetalGlobalState.h"
#include "renderer/ForwardPipeline.h"

//helium
#include "helium/BaseObject.h"

//std
#include <string_view>

//math
#include "AnariMetalMath.h"

namespace anari_mtl {

struct Object;

struct Renderable {
    Object* object;
    float4x4 modelMatrix;
    ForwardPipelineConfig config;
};

struct Bounds {
    float3 min;
    float3 max;
};

struct Object : public helium::BaseObject {
    Object(ANARIDataType type, AnariMetalGlobalState *s);
    virtual ~Object() = default;

    virtual bool getProperty(const std::string_view &name,
        ANARIDataType type,
        void *ptr,
        uint32_t flags);

    virtual void commit() {}

    virtual bool isValid() const;

    AnariMetalGlobalState *deviceState() const;

    virtual void render(id encoder, const float4x4& modelMatrix) {
        reportMessage(ANARI_SEVERITY_WARNING, "this object (%p, %u) is not renderable", this, type());
    }

    virtual void getRenderables(std::vector<Renderable>& renderables, const float4x4& parentModelMatrix) {
        reportMessage(ANARI_SEVERITY_WARNING, "this object (%p, %u) is not renderable or renderable list", this, type());
    }

    virtual Bounds getBounds(const float4x4& parentModelMatrix) {
        reportMessage(ANARI_SEVERITY_WARNING, "this object (%p, %u) does not have bounds", this, type());

        return {};
    }
};

struct UnknownObject : public Object {
    UnknownObject(ANARIDataType type, AnariMetalGlobalState *s);
    ~UnknownObject() override;
    bool isValid() const override;
};

} //namespace anari_mtl

#define ANARI_METAL_TYPEFOR_SPECIALIZATION(type, anari_type)                  \
  namespace anari {                                                            \
  ANARI_TYPEFOR_SPECIALIZATION(type, anari_type);                              \
  }

#define ANARI_METAL_TYPEFOR_DEFINITION(type)                                  \
  namespace anari {                                                            \
  ANARI_TYPEFOR_DEFINITION(type);                                              \
  }

ANARI_METAL_TYPEFOR_SPECIALIZATION(anari_mtl::Object *, ANARI_OBJECT);
