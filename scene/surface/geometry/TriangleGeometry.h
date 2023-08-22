#include "Geometry.h"

namespace anari_mtl {

class TriangleGeometry : public Geometry {
private:

public:
    TriangleGeometry(AnariMetalGlobalState* s) : Geometry(s) {}

    void commit() override;
};

} //namespace anari_mtl
