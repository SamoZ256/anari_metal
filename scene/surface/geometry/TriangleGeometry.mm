#include "TriangleGeometry.h"

namespace anari_mtl {

template<typename T>
class Vector {
public:
    Vector() {}

    Vector(size_t aSize) : size(aSize) {
        data = malloc(size * sizeof(T));
    }

    Vector(size_t aSize, T value) : Vector(aSize) {
        for (uint32_t i = 0; i < size; i++)
            ((T*)data)[i] = value;
    }

    void* getData() {
        return data;
    }

    size_t getSize() {
        return size;
    }

    T& operator[](uint32_t index) {
        return ((T*)data)[index];
    }

private:
    void* data;
    size_t size;
};

float3 calculateNormal(const float3& v1, const float3& v2, const float3& v3) {
    return normalize(cross(v2 - v1, v3 - v1));
}

Vector<float3> calculateNormalsFromPositions(const std::vector<float3>& positions) {
    Vector<float3> normals(positions.size());
    for (uint32_t i = 0; i < positions.size() / 3; i++) {
        float3 normal = calculateNormal(positions[i * 3 + 0], positions[i * 3 + 1], positions[i * 3 + 2]);
        normals[i * 3 + 0] = normal;
        normals[i * 3 + 1] = normal;
        normals[i * 3 + 2] = normal;
    }

    return normals;
}

Vector<float3> calculateNormalsFromPositionsAndIndices(const std::vector<float3>& positions, const std::vector<uint32_t>& indices) {
    std::vector<uint16_t> normalRefCounts(positions.size(), 0);
    Vector<float3> normals(positions.size(), float3(0.0f));
    for (uint32_t i = 0; i < indices.size() / 3; i++) {
        uint32_t i0 = indices[i * 3 + 0];
        uint32_t i1 = indices[i * 3 + 1];
        uint32_t i2 = indices[i * 3 + 2];
        float3 normal = calculateNormal(positions[i0], positions[i1], positions[i2]);
        normals[i0] += normal;
        normals[i1] += normal;
        normals[i2] += normal;
        normalRefCounts[i0]++;
        normalRefCounts[i1]++;
        normalRefCounts[i2]++;
    }

    for (uint32_t i = 0; i < normals.getSize(); i++)
        normals[i] /= normalRefCounts[i];

    return normals;
}

void TriangleGeometry::commit() {
    Geometry::commit();

    POSITION_ATTR = getParamObject<Array>("vertex.position");
    NORMAL_ATTR = getParamObject<Array>("vertex.normal");
    if (!NORMAL_ATTR) {
        reportMessage(ANARI_SEVERITY_DEBUG, "attribute 'vertex.normal' of triangle geometry not set, calculating manually");
        Vector<float3> normals;
        std::vector<float3> positions((float3*)POSITION_ATTR->getData(), (float3*)POSITION_ATTR->getData() + POSITION_ATTR->getElementCount());
        if (INDEX_ATTR) {
            //TODO: use uint16_t in case it's required
            std::vector<uint32_t> indices((uint32_t*)INDEX_ATTR->getData(), (uint32_t*)INDEX_ATTR->getData() + INDEX_ATTR->getElementCount() * 3);
            normals = calculateNormalsFromPositionsAndIndices(positions, indices);
        } else {
            normals = calculateNormalsFromPositions(positions);
        }
        //for (uint32_t i = 0; i < normals.getSize(); i++)
        //    printf("Normal: %s\n", glm::to_string(normals[i]).c_str());
        NORMAL_ATTR = new Array(deviceState(), normals.getData(), ANARI_FLOAT32_VEC3, uint3(normals.getSize(), 1, 1));
    }
    //TANGENT_ATTR = getParamObject<Array>("vertex.tangent");
    COLOR_ATTR = getParamObject<Array>("vertex.color");
    ATTRIBUTE_ATTR(0) = getParamObject<Array>("vertex.attribute0"); //Texture coordinates
    ATTRIBUTE_ATTR(1) = getParamObject<Array>("vertex.attribute1");
    ATTRIBUTE_ATTR(2) = getParamObject<Array>("vertex.attribute2");
    ATTRIBUTE_ATTR(3) = getParamObject<Array>("vertex.attribute3");

    initMTLBuffers();
}

void* TriangleGeometry::getGeometryDescriptor() {
    MTLAccelerationStructureTriangleGeometryDescriptor* geometryDescriptor = [MTLAccelerationStructureTriangleGeometryDescriptor descriptor];
    geometryDescriptor.indexBuffer = INDEX_BUFFER;
    geometryDescriptor.indexType = MTLIndexTypeUInt32; //TODO: use UInt16 in case it's required
    geometryDescriptor.vertexBuffer = POSITION_BUFFER;
    geometryDescriptor.vertexStride = sizeof(float3);
    geometryDescriptor.triangleCount = INDEX_ATTR->getElementCount() / 3;

    return geometryDescriptor;
}

} //namespace anari_mtl
