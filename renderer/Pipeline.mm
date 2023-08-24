#include "Pipeline.h"

//TODO: replace this include?
#include "../scene/World.h"

namespace anari_mtl {

Pipeline::Pipeline(id aDevice, const char* shaderSource) : device(aDevice) {
    NSError* error = nullptr;
    mainLibrary = [device newLibraryWithSource:[NSString stringWithCString:shaderSource 
                                encoding:[NSString defaultCStringEncoding]] options:0 error:&error];
    if (!mainLibrary)
        printf("[error] failed to create MTLLibrary, reason: %s\n", [[error localizedDescription] UTF8String]);

    MTLVertexDescriptor* vertexDescriptor = [[MTLVertexDescriptor alloc] init];
    //TODO: do this for other attributes as well
    vertexDescriptor.layouts[BUFFER_BINDING_INDEX(POSITION_I)].stride = sizeof(float3);
    vertexDescriptor.layouts[BUFFER_BINDING_INDEX(POSITION_I)].stepRate = 1;
    vertexDescriptor.layouts[BUFFER_BINDING_INDEX(POSITION_I)].stepFunction = MTLVertexStepFunctionPerVertex;
    vertexDescriptor.attributes[0].format = MTLVertexFormatFloat3;
    vertexDescriptor.attributes[0].bufferIndex = BUFFER_BINDING_INDEX(POSITION_I);
    vertexDescriptor.attributes[0].offset = 0;
    vertexDescriptor.layouts[BUFFER_BINDING_INDEX(ATTRIBUTE_I(0))].stride = sizeof(float2);
    vertexDescriptor.layouts[BUFFER_BINDING_INDEX(ATTRIBUTE_I(0))].stepRate = 1;
    vertexDescriptor.layouts[BUFFER_BINDING_INDEX(ATTRIBUTE_I(0))].stepFunction = MTLVertexStepFunctionPerVertex;
    vertexDescriptor.attributes[1].format = MTLVertexFormatFloat2;
    vertexDescriptor.attributes[1].bufferIndex = BUFFER_BINDING_INDEX(ATTRIBUTE_I(0));
    vertexDescriptor.attributes[1].offset = 0;
    vertexDescriptor.layouts[BUFFER_BINDING_INDEX(NORMAL_I)].stride = sizeof(float3);
    vertexDescriptor.layouts[BUFFER_BINDING_INDEX(NORMAL_I)].stepRate = 1;
    vertexDescriptor.layouts[BUFFER_BINDING_INDEX(NORMAL_I)].stepFunction = MTLVertexStepFunctionPerVertex;
    vertexDescriptor.attributes[2].format = MTLVertexFormatFloat3;
    vertexDescriptor.attributes[2].bufferIndex = BUFFER_BINDING_INDEX(NORMAL_I);
    vertexDescriptor.attributes[2].offset = 0;
    vertexDescriptor.layouts[BUFFER_BINDING_INDEX(COLOR_I)].stride = sizeof(float4);
    vertexDescriptor.layouts[BUFFER_BINDING_INDEX(COLOR_I)].stepRate = 1;
    vertexDescriptor.layouts[BUFFER_BINDING_INDEX(COLOR_I)].stepFunction = MTLVertexStepFunctionPerVertex;
    vertexDescriptor.attributes[3].format = MTLVertexFormatFloat4;
    vertexDescriptor.attributes[3].bufferIndex = BUFFER_BINDING_INDEX(COLOR_I);
    vertexDescriptor.attributes[3].offset = 0;

    mtlVertexDescriptor = vertexDescriptor;
}

Pipeline::~Pipeline() {
    for (PIPELINE_HASH_T i = 0; i < PIPELINE_CONFIG_COUNT; i++) {
        if (renderPipelineStates[i]) {
            [renderPipelineStates[i]->mainVertexFunction release];
            [renderPipelineStates[i]->mainFragmentFunction release];
            [renderPipelineStates[i]->pipelineState release];
        }
    }
}

void Pipeline::bind(id encoder, const PipelineConfig& config, id colorAttachment, id depthAttachment, id albedoMetallicTexture, id normalRoughnessTexture) {
    PIPELINE_HASH_T hash = config.getHash();
    if (!(isBound && hash == boundHash)) {
        auto& renderPipelineState = renderPipelineStates[hash];
        if (!renderPipelineState) {
            renderPipelineState = new PipelineState{};

            createPipeline(renderPipelineState, config, colorAttachment, depthAttachment, albedoMetallicTexture, normalRoughnessTexture);
        }

        [encoder setRenderPipelineState:renderPipelineState->pipelineState];
    }

    isBound = true;
    boundHash = hash;
}

id Pipeline::createFunction(const std::string& name, const std::vector<ConstantValue>& constantValue) {
    MTLFunctionDescriptor* functionDescriptor = [[MTLFunctionDescriptor alloc] init];
    [functionDescriptor setName:[NSString stringWithCString:name.c_str() encoding:[NSString defaultCStringEncoding]]];

    MTLFunctionConstantValues* constantValues = [[MTLFunctionConstantValues alloc] init];
    for (auto& constantValue : constantValue) {
        [constantValues setConstantValue:constantValue.data
                                    type:MTLDataTypeBool
                                    atIndex:constantValue.index];
    }

    functionDescriptor.constantValues = constantValues;

    NSError* error;
    id<MTLFunction> function = [mainLibrary newFunctionWithDescriptor:functionDescriptor error:&error];
    if (!function)
        printf("[error] failed to create '%s' function\n", name.c_str());
    
    return function;
}

} //namespace anari_mtl
