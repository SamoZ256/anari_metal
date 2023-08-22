#include "PerspectiveCamera.h"

namespace anari_mtl {

void PerspectiveCamera::commit() {
    Camera::commit();

    float fovy = 0.0f;
    if (!getParam("fovy", ANARI_FLOAT32, &fovy))
        fovy = anari::radians(60.f);
    float aspect = getParam<float>("aspect", 1.0f);
    //printf("Fov: %f, aspect: %f\n", fovy, aspect);

    projection = perspective_matrix(fovy, aspect, 0.1f, 1000.0f, neg_z, zero_to_one); //TODO: check if this is correct

    viewProj = mul(projection, view);
}

} //namespace anari_mtl
