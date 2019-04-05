//
//  Shaders.metal
//  VisionSDK
//
//  Created by Denis Koronchik on 8/22/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position  [[attribute(0)]];
    float3 normal    [[attribute(1)]];
    float2 texCoords [[attribute(2)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 worldNormal;
    float3 worldPosition;
    float2 texCoords;
};

struct DefaultVertexUniforms {
    float4x4 viewProjectionMatrix;
    float4x4 modelMatrix;
    float3x3 normalMatrix;
};

struct ArrowVertexUniforms {
    float4x4 viewProjectionMatrix;
    float4x4 modelMatrix;
    float3x3 normalMatrix;
    float3   p0;
    float3   p1;
    float3   p2;
    float3   p3;
};

struct Light {
    float3 color;
    float3 worldPosition;
};

struct DefaultFragmentUniforms {
    float3 cameraWorldPosition;
    float3 ambientLightColor;
    float3 specularColor;
    float3 baseColor;
    float opacity;
    float specularPower;
    Light light;
};

struct LaneFragmentUniforms {
    float4 baseColor;
};

struct TextureMappingVertex {
    float4 position [[position]];
    float2 textureCoordinates;
};

struct TextureMappingVertexIn {
    float3 position [[attribute(0)]];
    float2 textureCoordinates [[attribute(1)]];
};

vertex TextureMappingVertex map_texture_vertex(TextureMappingVertexIn vertexIn [[stage_in]]) {
    TextureMappingVertex outVertex;
    outVertex.position = float4(vertexIn.position.xyz, 1.0);
    outVertex.textureCoordinates = vertexIn.textureCoordinates;
    return outVertex;
}


vertex VertexOut default_vertex_main(VertexIn vertexIn [[stage_in]], constant DefaultVertexUniforms &uniforms [[buffer(1)]])
{
    VertexOut vertexOut;
    float4 worldPosition = uniforms.modelMatrix * float4(vertexIn.position, 1);
    vertexOut.position = uniforms.viewProjectionMatrix * worldPosition;
    vertexOut.worldPosition = worldPosition.xyz;
    vertexOut.worldNormal = uniforms.normalMatrix * vertexIn.normal;
    vertexOut.texCoords = vertexIn.texCoords;
    return vertexOut;
}

vertex VertexOut arrow_vertex_main(VertexIn vertexIn [[stage_in]], constant ArrowVertexUniforms &uniforms [[buffer(1)]])
{
    VertexOut vertexOut;
    
    float3 const p0 = uniforms.p0;
    float3 const p1 = uniforms.p1;
    float3 const p2 = uniforms.p2;
    float3 const p3 = uniforms.p3;
    
    float const t = (1 - vertexIn.texCoords.y);
    float const t_2 = t * t;
    float const t_3 = t_2 * t;
    float const t1 = 1 - t;
    float const t1_2 = t1 * t1;
    float const t1_3 = t1_2 * t1;
    
    float3 const basePoint = p0 * t1_3 + p1 * (3 * t * t1_2) + p2 * (3 * t_2 * t1) + p3 * t_3;
    float3 const baseDirection = 3 * (p1 - p0) * t1_2 + 6 * (p2 - p1) * t1 * t + 3 * (p3 - p2) * t_2;
    
    float3 const offsetVector = normalize(float3(baseDirection.z, 0, -baseDirection.x));
    float3 const smoothedPos = basePoint - offsetVector * vertexIn.position.x;
    
    float4 const worldPosition = uniforms.modelMatrix * float4(smoothedPos.x, vertexIn.position.y, smoothedPos.z, 1);
    
    vertexOut.position = uniforms.viewProjectionMatrix * worldPosition;
    vertexOut.worldPosition = worldPosition.xyz;
    vertexOut.worldNormal = uniforms.normalMatrix * vertexIn.normal;
    vertexOut.texCoords = vertexIn.texCoords;
    return vertexOut;
}

float3 calculateLight(VertexOut fragmentIn, constant DefaultFragmentUniforms &uniforms) {
    float3 baseColor = uniforms.baseColor.xyz;
    float3 specularColor = uniforms.specularColor;
    
    float3 N = normalize(fragmentIn.worldNormal);
    float3 V = normalize(uniforms.cameraWorldPosition - fragmentIn.worldPosition);
    
    float3 L = normalize(uniforms.light.worldPosition - fragmentIn.worldPosition.xyz);
    float3 diffuseIntensity = saturate(dot(N, L));
    float3 H = normalize(L + V);
    float specularBase = saturate(dot(N, H));
    float specularIntensity = powr(specularBase, uniforms.specularPower);
    float3 finalColor = uniforms.ambientLightColor * baseColor +
    diffuseIntensity * uniforms.light.color * baseColor +
    specularIntensity * uniforms.light.color * specularColor;
    
    return finalColor;
}

fragment float4 default_fragment_main(VertexOut fragmentIn [[stage_in]],
                                      constant DefaultFragmentUniforms &uniforms [[buffer(0)]],
                                      sampler baseColorSampler [[sampler(0)]])
{
    return float4(calculateLight(fragmentIn, uniforms), uniforms.opacity);
}

fragment float4 lane_fragment_main(VertexOut fragmentIn [[stage_in]],
                                      constant DefaultFragmentUniforms &uniforms [[buffer(0)]],
                                      sampler baseColorSampler [[sampler(0)]])
{
    return float4(calculateLight(fragmentIn, uniforms), uniforms.opacity * fragmentIn.texCoords.y);
}

fragment half4 display_texture_fragment(TextureMappingVertex mappingVertex [[ stage_in ]],
                              texture2d<float, access::sample> texture [[ texture(0) ]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    
    return half4(texture.sample(s, mappingVertex.textureCoordinates));
}
