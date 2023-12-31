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
    float depth [[color(3)]];
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
    out.depth = in.position.z;

    return out;
}
)V0G0N";

const char* deferredShaderSource = R"V0G0N(
#include <metal_stdlib>
using namespace metal;
using namespace raytracing;

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

template<typename T>
inline T interpolateVertexAttribute(thread T *attributes, float2 uv) {
    // Look up the value for each vertex.
    const T T0 = attributes[0];
    const T T1 = attributes[1];
    const T T2 = attributes[2];

    // Compute the sum of the vertex attributes weighted by the barycentric coordinates.
    // The barycentric coordinates sum to one.
    return (1.0f - uv.x - uv.y) * T0 + uv.x * T1 + uv.y * T2;
}

__attribute__((always_inline))
float3 transformDirection(float3 p, float4x4 transform) {
    return (transform * float4(p, 0.0f)).xyz;
}

struct Triangle {
    float2 texCoords[3];
    float3 normals[3];
};

struct TriangleResources {
    device uint32_t* indices;
    device packed_float3* vertexNormals;
    device packed_float2* vertexTexCoords;
    texture2d<float> albedoTexture;
    float4 albedo;
    bool hasAlbedoTexture;
};

fragment float4 fragmentDeferred(VertexOut in [[stage_in]],
                                float4 albedoMetallic [[color(1)]],
                                float4 normalRoughness [[color(2)]],
                                float depth [[color(3)]],
                                constant float3& viewPos [[buffer(0)]],
                                constant Light& light [[buffer(1)]],
                                constant float4x4& invViewProj [[buffer(2)]],
                                constant MTLAccelerationStructureInstanceDescriptor* instances [[buffer(3)]],
                                instance_acceleration_structure accelerationStructure [[buffer(4)]],
                                device TriangleResources* resources [[buffer(5)]]) {
    sampler basicSampler;

    float2 normPosition = float2(in.texCoord) * 2.0 - 1.0;
    normPosition.y = -normPosition.y;
    float4 worldPosition = invViewProj * float4(normPosition, depth, 1.0);
    worldPosition.xyz /= worldPosition.w;
    float3 viewDir = normalize(viewPos - worldPosition.xyz);

    float3 F0 = mix(float3(0.04), albedoMetallic.rgb, albedoMetallic.a);

    float3 color = albedoMetallic.rgb * 0.4 + calculateDirectionalLightingForPBM(light, viewDir, albedoMetallic.rgb, normalRoughness.xyz, F0, normalRoughness.a);

    //Raytracing
    ray r;
    r.origin = worldPosition.xyz;
    r.direction = reflect(normalRoughness.xyz, viewDir);
    r.min_distance = 0.001;
    r.max_distance = INFINITY;

    intersector<triangle_data, instancing> intersectr;
    intersectr.assume_geometry_type(geometry_type::triangle);
    intersectr.force_opacity(forced_opacity::opaque);
    typename intersector<triangle_data, instancing>::result_type intersection;

    intersectr.accept_any_intersection(false);

    intersection = intersectr.intersect(r, accelerationStructure, 1);

    if (intersection.type == intersection_type::none) {
        //TODO: sample background
    } else {
        float3 reflectionWorldPos = r.origin + r.direction * intersection.distance;

        unsigned int instanceIndex = intersection.instance_id;
        unsigned primitiveIndex = intersection.primitive_id;
        unsigned int geometryIndex = instances[instanceIndex].accelerationStructureIndex;
        float2 barycentric_coords = intersection.triangle_barycentric_coord;

        float4x4 model(1.0);
        for (int column = 0; column < 4; column++)
            for (int row = 0; row < 3; row++)
                model[column][row] = instances[instanceIndex].transformationMatrix[column][row];

        device TriangleResources& triangleResources = resources[geometryIndex];
        //bool hasAnyTexture = triangleResources.hasAlbedoTexture;
        
        Triangle triangle;
        
        //if (hasAnyTexture) {
        //    triangle.texCoords[0] = triangleResources.vertexTexCoords[triangleResources.indices[primitiveIndex * 3 + 0]];
        //    triangle.texCoords[1] = triangleResources.vertexTexCoords[triangleResources.indices[primitiveIndex * 3 + 1]];
        //    triangle.texCoords[2] = triangleResources.vertexTexCoords[triangleResources.indices[primitiveIndex * 3 + 2]];
        //}

        triangle.normals[0] = triangleResources.vertexNormals[triangleResources.indices[primitiveIndex * 3 + 0]];
        triangle.normals[1] = triangleResources.vertexNormals[triangleResources.indices[primitiveIndex * 3 + 1]];
        triangle.normals[2] = triangleResources.vertexNormals[triangleResources.indices[primitiveIndex * 3 + 2]];
        
        // Interpolate the vertex normal at the intersection point.
        float3 reflectionNormal = interpolateVertexAttribute(triangle.normals, barycentric_coords);
        reflectionNormal = normalize(transformDirection(reflectionNormal, model));
        float2 reflectionTexCoord = interpolateVertexAttribute(triangle.texCoords, barycentric_coords);
        float3 reflectionAlbedo = reflectionNormal;//triangleResources.albedo.rgb;
        //if (triangleResources.hasAlbedoTexture)
        //    triangleResources.albedoTexture.sample(basicSampler, reflectionTexCoord).rgb;
        float3 reflectionF0 = mix(float3(0.04), reflectionAlbedo, 1.0); //TODO: use the metallic from texture
        float reflectionRoughness = 1.0; //TODO: use the roughness from texture

        float3 reflectionColor = reflectionAlbedo * 0.4 + calculateDirectionalLightingForPBM(light, r.direction, reflectionAlbedo, reflectionNormal, reflectionF0, reflectionRoughness);

        color += reflectionColor;
    }

    return float4(color, 1.0);
}
)V0G0N";

namespace anari_mtl {

HybridPipeline::HybridPipeline(id aDevice) : Pipeline(aDevice, gbufferShaderSource) {}

HybridPipeline::~HybridPipeline() {
    //TODO: release all the objects
}

void HybridPipeline::createPipeline(PipelineState* renderPipelineState, const PipelineConfig& config, id colorAttachment, id depthAttachment, id albedoMetallicAttachment, id normalRoughnessAttachment, id depthAsColorAttachment) {
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
    renderPipelineDescriptor.colorAttachments[3].pixelFormat = [depthAsColorAttachment pixelFormat];
    if (depthAttachment)
        renderPipelineDescriptor.depthAttachmentPixelFormat = [depthAttachment pixelFormat];
    renderPipelineDescriptor.vertexDescriptor = (MTLVertexDescriptor*)mtlVertexDescriptor;

    NSError* error = nullptr;
    renderPipelineState->pipelineState = [device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor error:&error];
    if (!renderPipelineState->pipelineState)
        printf("[error] failed to create MTLRenderPipelineState, reason: %s\n", [[error localizedDescription] UTF8String]);
}

void HybridPipeline::bindDeferred(id encoder, id colorAttachment, id depthAttachment, id albedoMetallicAttachment, id normalRoughnessAttachment, id depthAsColorAttachment) {
    if (!deferredPipelineState) {
        deferredPipelineState = new PipelineState{};

        NSError* error = nullptr;
        deferredLibrary = [device newLibraryWithSource:[NSString stringWithCString:deferredShaderSource 
                                    encoding:[NSString defaultCStringEncoding]] options:0 error:&error];
        if (!deferredLibrary)
            printf("[error] failed to create MTLLibrary, reason: %s\n", [[error localizedDescription] UTF8String]);

        //TODO: handle errors
        deferredPipelineState->vertexFunction = [deferredLibrary newFunctionWithName:@"vertexTriangle"];
        deferredPipelineState->fragmentFunction = [deferredLibrary newFunctionWithName:@"fragmentDeferred"];
        if (deferredPipelineState->fragmentFunction == nil)
            printf("%s\n", [[error localizedDescription] UTF8String]);

        MTLRenderPipelineDescriptor* renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        renderPipelineDescriptor.vertexFunction = deferredPipelineState->vertexFunction;
        renderPipelineDescriptor.fragmentFunction = deferredPipelineState->fragmentFunction;
        renderPipelineDescriptor.inputPrimitiveTopology = MTLPrimitiveTopologyClassTriangle;
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = [colorAttachment pixelFormat];
        renderPipelineDescriptor.colorAttachments[1].pixelFormat = [albedoMetallicAttachment pixelFormat];
        renderPipelineDescriptor.colorAttachments[2].pixelFormat = [normalRoughnessAttachment pixelFormat];
        renderPipelineDescriptor.colorAttachments[3].pixelFormat = [depthAsColorAttachment pixelFormat];
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
