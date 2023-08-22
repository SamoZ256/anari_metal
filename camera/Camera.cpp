#include "Camera.h"

#include "PerspectiveCamera.h"
//#include "OrthographicCamera.h"

//#include <glm/glm.hpp>
//#include <glm/gtc/matrix_transform.hpp>

namespace anari_mtl {

Camera::Camera(AnariMetalGlobalState* s) : Object(ANARI_CAMERA, s) {
    s->objectCounts.cameras++;
}

Camera::~Camera() {
    deviceState()->objectCounts.cameras--;
}

Camera* Camera::createInstance(std::string_view type, AnariMetalGlobalState *s) {
    if (type == "perspective")
        return new PerspectiveCamera(s);
    //else if (type == "orthographic")
    //  return new OrthographicCamera(s);
    else
        return (Camera*)new UnknownObject(ANARI_CAMERA, s);
}

void Camera::commit() {
    position = getParam<float3>("position", float3(0.0f));
    direction = normalize(getParam<float3>("direction", float3(0.0f, 0.0f, 1.0f)));
    up = normalize(getParam<float3>("up", float3(0.0f, 1.0f, 0.0f)));
    view = lookat_matrix(position, position + direction, up, neg_z);
    /*
    for (uint8_t y = 0; y < 4; y++) {
        for (uint8_t x = 0; x < 4; x++) {
            printf("%f, ", view[y][x]);
        }
        printf("\n");
    }
    printf("\n");
    glm::mat4 mat = glm::lookAt(glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(0.0f, 0.0f, 0.0f) + glm::vec3(0.0f, 0.0f, 1.0f), glm::vec3(0.0f, 1.0f, 0.0f));
    for (uint8_t y = 0; y < 4; y++) {
        for (uint8_t x = 0; x < 4; x++) {
            printf("%f, ", mat[y][x]);
        }
        printf("\n");
    }
    printf("\n");
    */
    markUpdated();
}

} //namespace anari_mtl
