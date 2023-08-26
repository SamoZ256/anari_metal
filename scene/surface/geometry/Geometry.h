#pragma once

#include "../../../array/Array.h"

#define GEOMETRY_ATTRIBUTES_ARRAY_COUNT 16

#define POSITION_I 0
#define NORMAL_I 1
#define TANGENT_I 2
#define COLOR_I 3
#define ATTRIBUTE_I(attrIndex) (GEOMETRY_ATTRIBUTES_ARRAY_COUNT - attrIndex - 2)
#define INDEX_I (GEOMETRY_ATTRIBUTES_ARRAY_COUNT - 1)

#define BUFFER_BINDING_INDEX(attrI) (30 - attrI)

#define POSITION_ATTR attributes[POSITION_I]
#define NORMAL_ATTR attributes[NORMAL_I]
#define TANGENT_ATTR attributes[TANGENT_I]
#define COLOR_ATTR attributes[COLOR_I]
#define ATTRIBUTE_ATTR(attrIndex) attributes[ATTRIBUTE_I(attrIndex)]
#define INDEX_ATTR attributes[INDEX_I]

#define POSITION_BUFFER mtlBuffers[POSITION_I]
#define NORMAL_BUFFER mtlBuffers[NORMAL_I]
#define TANGENT_BUFFER mtlBuffers[TANGENT_I]
#define COLOR_BUFFER mtlBuffers[COLOR_I]
#define ATTRIBUTE_BUFFER(attrIndex) mtlBuffers[ATTRIBUTE_I(attrIndex)]
#define INDEX_BUFFER mtlBuffers[INDEX_I]

namespace anari_mtl {

class Geometry : public Object {
public:
    Geometry(AnariMetalGlobalState* s);

    ~Geometry() override;

    static Geometry* createInstance(std::string_view type, AnariMetalGlobalState* s);

    void commit() override;

    void render(id encoder, const float4x4& modelMatrix, bool useMaterial = true) override;

    Bounds getBounds(const float4x4& parentModelMatrix) override;

    virtual void buildAccelerationStructureAndAddToList(void* list) = 0;

    long getUUID() {
        return uuid;
    }

    //Attributes
    bool hasColors() {
        return COLOR_ATTR;
    }

    bool hasTexCoords() {
        return ATTRIBUTE_ATTR(0);
    }

protected:
    unsigned long uuid;

    Array* attributes[GEOMETRY_ATTRIBUTES_ARRAY_COUNT] = {nullptr};
    Array* oldAttributes[GEOMETRY_ATTRIBUTES_ARRAY_COUNT] = {nullptr};
    id mtlBuffers[GEOMETRY_ATTRIBUTES_ARRAY_COUNT] = {nullptr};

    id mtlAccelerationStructure;
    bool builtAccelerationStructure = false;

    void initMTLBuffers();

    //void addToList(void* list, id accelerationStructure);
};

} //namespace anari_mtl

ANARI_METAL_TYPEFOR_SPECIALIZATION(anari_mtl::Geometry*, ANARI_GEOMETRY);
