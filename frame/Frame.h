#pragma once

#include "../renderer/Renderer.h"

//helium
#include "helium/BaseFrame.h"

namespace anari_mtl {

struct Frame : public helium::BaseFrame {
public:
    Frame(AnariMetalGlobalState* s);

    ~Frame() override;

    void commit() override;

    AnariMetalGlobalState* deviceState() const {
        return state;
    }

    bool getProperty(const std::string_view &name, ANARIDataType type, void *ptr, uint32_t flags) override {
        //TODO

        return false;
    }

    void renderFrame() override;

    void* map(std::string_view channel, uint32_t *width, uint32_t *height, ANARIDataType *pixelType) override;

    void unmap(std::string_view channel) override;

    int frameReady(ANARIWaitMask m) override {
        //TODO

        return 0;
    }

    void discard() override {
        //TODO
    }

private:
    AnariMetalGlobalState* state;

    World* world;
    Camera* camera;
    Renderer* renderer;

    ANARIDataType colorFormat;
    ANARIDataType depthFormat;
    uint2 size;

    size_t bytesPerPixel = 4; //TODO: set this according to pixel format

    id mtlColorTexture = nullptr;
    id mtlDepthTexture = nullptr;

    id mtlMappedBuffer = nullptr;
};

} //namespace anari_mtl

ANARI_METAL_TYPEFOR_SPECIALIZATION(anari_mtl::Frame*, ANARI_FRAME);
