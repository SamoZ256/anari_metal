#include "Geometry.h"

namespace anari_mtl {

class TriangleGeometry : public Geometry {
public:
    TriangleGeometry(AnariMetalGlobalState* s) : Geometry(s) {}

    void commit() override;

    void* getGeometryDescriptor() override;
};

} //namespace anari_mtl
