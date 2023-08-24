#include "HybridPipeline.h"

//TODO: replace this include?
#include "../scene/World.h"

const char* gbufferShaderSource = R"V0G0N(
#include <metal_stdlib>
using namespace metal;

//Function constants
constant bool hasColors [[function_constant(0)]];
constant bool hasTexCoords [[function_constant(1)]];

struct VertexIn {
    float3 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
    float3 normal [[attribute(2)]];
    float4 color [[attribute(3)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 worldPosition;
    float2 texCoord;
    float4 color;
    float3 normal;
};

vertex VertexOut vertexMain(VertexIn in [[stage_in]],
                            constant float4x4& viewProj [[buffer(0)]],
                            constant float4x4& model [[buffer(1)]]) {
    VertexOut out;
    out.position = model * float4(in.position, 1.0);
    out.worldPosition = float3(out.position);
    out.position = viewProj * out.position;
    out.texCoord = (hasTexCoords ? in.texCoord : float2(0.0));
    out.color = (hasColors ? in.color : float4(1.0));
    out.normal = in.normal;

    return out;
}

struct FragmentOut {
    float4 albedoMetallic [[color(1)]];
    float4 normalRoughness [[color(2)]];
};

struct Material {
    float4 albedo;
    float metallic;
    float roughness;
};

fragment FragmentOut fragmentMain(VertexOut in [[stage_in]],
                             constant Material& material [[buffer(2)]],
                             texture2d<float> albedoTexture [[texture(0)]],
                             sampler albedoSampler [[sampler(0)]]) {
    float3 albedo = in.color.rgb * material.albedo.rgb * material.albedo.a;
    if (hasTexCoords) {
        float4 sampledAlbedo = albedoTexture.sample(albedoSampler, in.texCoord);
        //if (sampledAlbedo.a < 0.5)
        //    discard_fragment();
        albedo *= sampledAlbedo.rgb;
    }
    float3 F0 = mix(float3(0.04), albedo, material.metallic);

    FragmentOut out;
    out.albedoMetallic = float4(albedo, material.metallic);
    out.normalRoughness = float4(in.normal, 1.0);

    return out;
}
)V0G0N";

const char* deferredShaderSource = R"V0G0N(
#include <metal_stdlib>
using namespace metal;

//Constants
constant float PI = 3.14159265359;

struct VertexOut {
    float4 position [[position]];
    half2 texCoord;
};

constant half2 triangleTexCoords[] = {
    half2( 0.0,  1.0),
    half2( 0.0, -1.0),
    half2( 2.0,  1.0)
};

vertex VertexOut vertexTriangle(uint vid [[vertex_id]]) {
    VertexOut out;
    out.texCoord = triangleTexCoords[vid];
    out.position = float4(float2(out.texCoord * 2.0 - 1.0), 1.0, 1.0);
    out.position.y = -out.position.y;

    return out;
}

struct Light {
    packed_float3 color;
    packed_float3 direction;
};

//PBR functions
float DistributionGGX(float3 N, float3 H, float roughness) {
    float a      = roughness*roughness;
    float a2     = a*a;
    float NdotH  = max(dot(N, H), 0.0);
    float NdotH2 = NdotH*NdotH;

    float num   = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;

    return num / denom;
}

float GeometrySchlickGGX(float NdotV, float roughness) {
    float r = roughness + 1.0;
    float k = r*r / 8.0;

    float num   = NdotV;
    float denom = NdotV * (1.0 - k) + k;

    return num / denom;
}

float GeometrySmith(float3 N, float3 V, float3 L, float roughness) {
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx2  = GeometrySchlickGGX(NdotV, roughness);
    float ggx1  = GeometrySchlickGGX(NdotL, roughness);

    return ggx1 * ggx2;
}

float3 fresnelSchlick(float cosTheta, float3 F0, float roughness) {
    return F0 + (max(float3(1.0 - roughness), F0) - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

//Direct light
float3 calculateDirectionalLightingForPBM(constant Light& light, float3 viewDir, float3 albedo, float3 normal, float3 F0, float roughness) {
    float3 L = normalize(-light.direction);
    float3 H = normalize(viewDir + L);
    float cosTheta = max(dot(normal, L), 0.0);
    float3 radiance = float3(1.0) * cosTheta;

    //NDF and G
    float NDF = DistributionGGX(normal, H, roughness);
    float G = GeometrySmith(normal, viewDir, L, roughness);
    float3 F = fresnelSchlick(max(dot(H, viewDir), 0.0), F0, roughness);

    //Specular
    float3 numerator = NDF * G * F;
    float denominator = 4.0 * max(dot(normal, viewDir), 0.0) * max(dot(normal, L), 0.0) + 0.0001;
    float3 spec = numerator / denominator;

    float3 kS = F;
    float3 kD = float3(1.0) - kS;

    kD *= roughness;

    float NdotL = max(dot(normal, L), 0.0);

    return (kD * albedo / PI + spec) * radiance * NdotL * light.color * 2.0;
}

fragment float4 fragmentDeferred(VertexOut in [[stage_in]],
                                float4 albedoMetallic [[color(1)]],
                                float4 normalRoughness [[color(2)]],
                                constant float3& viewPos [[buffer(0)]],
                                constant Light& light [[buffer(1)]],
                                constant float4x4& invViewProj [[buffer(2)]]/*,
                                texture2d<float> depthTexture [[texture(2)]]*/) {
    float4 worldPosition = float4(1.0);//invViewProj * float4(in.position, depthTexture.read(uint2(coord)), 1.0);
    float3 viewDir = normalize(viewPos - worldPosition.xyz);

    float3 F0 = mix(float3(0.04), albedoMetallic.rgb, albedoMetallic.a);

    return float4(albedoMetallic.rgb * 0.4 + calculateDirectionalLightingForPBM(light, viewDir, albedoMetallic.rgb, normalRoughness.xyz, F0, normalRoughness.a), 1.0);
}
)V0G0N";

namespace anari_mtl {

HybridPipeline::HybridPipeline(id aDevice) : Pipeline(aDevice, gbufferShaderSource) {}

HybridPipeline::~HybridPipeline() {
    //TODO: release all the objects
}

void HybridPipeline::createPipeline(PipelineState* renderPipelineState, const PipelineConfig& config, id colorAttachment, id depthAttachment, id albedoMetallicAttachment, id normalRoughnessAttachment) {
    std::vector<ConstantValue> constantValues = {
        {(void*)&config.hasColors, 0},
        {(void*)&config.hasTexCoords, 1}
    };
    renderPipelineState->vertexFunction = createFunction("vertexMain", constantValues);
    renderPipelineState->fragmentFunction = createFunction("fragmentMain", constantValues);

    MTLRenderPipelineDescriptor* renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    renderPipelineDescriptor.vertexFunction = renderPipelineState->vertexFunction;
    renderPipelineDescriptor.fragmentFunction = renderPipelineState->fragmentFunction;
    renderPipelineDescriptor.inputPrimitiveTopology = MTLPrimitiveTopologyClassTriangle;
    renderPipelineDescriptor.colorAttachments[0].pixelFormat = [colorAttachment pixelFormat];
    renderPipelineDescriptor.colorAttachments[1].pixelFormat = [albedoMetallicAttachment pixelFormat];
    renderPipelineDescriptor.colorAttachments[2].pixelFormat = [normalRoughnessAttachment pixelFormat];
    if (depthAttachment)
        renderPipelineDescriptor.depthAttachmentPixelFormat = [depthAttachment pixelFormat];
    renderPipelineDescriptor.vertexDescriptor = (MTLVertexDescriptor*)mtlVertexDescriptor;

    NSError* error = nullptr;
    renderPipelineState->pipelineState = [device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor error:&error];
    if (!renderPipelineState->pipelineState)
        printf("[error] failed to create MTLRenderPipelineState, reason: %s\n", [[error localizedDescription] UTF8String]);
}

void HybridPipeline::bindDeferred(id encoder, id colorAttachment, id albedoMetallicAttachment, id normalRoughnessAttachment, id depthAttachment) {
    if (!deferredPipelineState) {
        deferredPipelineState = new PipelineState{};

        NSError* error = nullptr;
        deferredLibrary = [device newLibraryWithSource:[NSString stringWithCString:deferredShaderSource 
                                    encoding:[NSString defaultCStringEncoding]] options:0 error:&error];
        if (!deferredLibrary)
            printf("[error] failed to create MTLLibrary, reason: %s\n", [[error localizedDescription] UTF8String]);

        //TODO: handle errors
        MTLFunctionDescriptor* functionDescriptor = [[MTLFunctionDescriptor alloc] init];
        [functionDescriptor setName:@"vertexTriangle"];
        error = nullptr;
        deferredPipelineState->vertexFunction = [deferredLibrary newFunctionWithDescriptor:functionDescriptor error:&error];
        if (deferredPipelineState->vertexFunction == nil)
            printf("%s\n", [[error localizedDescription] UTF8String]);
        [functionDescriptor setName:@"fragmentDeferred"];
        error = nullptr;
        deferredPipelineState->fragmentFunction = [deferredLibrary newFunctionWithDescriptor:functionDescriptor error:&error];
        if (deferredPipelineState->fragmentFunction == nil)
            printf("%s\n", [[error localizedDescription] UTF8String]);

        MTLRenderPipelineDescriptor* renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        renderPipelineDescriptor.vertexFunction = deferredPipelineState->vertexFunction;
        renderPipelineDescriptor.fragmentFunction = deferredPipelineState->fragmentFunction;
        renderPipelineDescriptor.inputPrimitiveTopology = MTLPrimitiveTopologyClassTriangle;
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = [colorAttachment pixelFormat];
        renderPipelineDescriptor.colorAttachments[1].pixelFormat = [albedoMetallicAttachment pixelFormat];
        renderPipelineDescriptor.colorAttachments[2].pixelFormat = [normalRoughnessAttachment pixelFormat];
        if (depthAttachment)
            renderPipelineDescriptor.depthAttachmentPixelFormat = [depthAttachment pixelFormat];

        error = nullptr;
        deferredPipelineState->pipelineState = [device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor error:&error];
        if (!deferredPipelineState->pipelineState)
            printf("[error] failed to create MTLRenderPipelineState, reason: %s\n", [[error localizedDescription] UTF8String]);
    }

    [encoder setRenderPipelineState:deferredPipelineState->pipelineState];
}

} //namespace anari_mtl
