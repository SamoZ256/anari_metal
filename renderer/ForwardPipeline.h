#pragma once

#include "../AnariMetalGlobalState.h"

#define FORWARD_PIPELINE_CONFIG_COUNT 4
#define FORWARD_PIPELINE_HASH_T uint8_t

namespace anari_mtl {

struct PipelineState {
    id mainVertexFunction;
    id mainFragmentFunction;
    id pipelineState;
};

struct ForwardPipelineConfig {
    bool hasColors;
    bool hasTexCoords;

    FORWARD_PIPELINE_HASH_T getHash() const {
        return (hasColors & 0x1) | (hasTexCoords & 0x1) << 1;
    }
};

//TODO: include data type
struct ConstantValue {
    void* data;
    uint8_t index;
};

class ForwardPipeline {
public:
    ForwardPipeline(id aDevice);

    ~ForwardPipeline();

    void bind(id encoder, const ForwardPipelineConfig& config, id colorAttachment, id depthAttachment = nullptr);

    void unbind() {
        isBound = false;
    }

private:
    id device;
    id mainLibrary;
    void* mtlVertexDescriptor;
    PipelineState* renderPipelineStates[FORWARD_PIPELINE_CONFIG_COUNT] = {nullptr};

    bool isBound = false;
    FORWARD_PIPELINE_HASH_T boundHash;

    id createFunction(const std::string& name, const std::vector<ConstantValue>& constantValue);
};

} //namespace anari_mtl
