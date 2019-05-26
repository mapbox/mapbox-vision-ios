#include <metal_stdlib>
using namespace metal;

constant half4 segColors[14] = {
    { 120.0 / 255, 120.0 / 255, 120.0 / 255, 1 },    // Other
    { 100.0 / 255, 255.0 / 255, 130.0 / 255, 1 },    // Road
    { 255.0 / 255, 236.0 / 255, 0.0   / 255, 1 },    // RoadMarkupVertical
    { 73.0  / 255, 45.0  / 255, 255.0 / 255, 1 },    // FlatNonRoad
    { 0.0   / 255, 255.0 / 255, 255.0 / 255, 1 },    // Sky
    { 139.0 / 255, 87.0  / 255, 42.0  / 255, 1 },    // Building
    { 208.0 / 255, 2.0   / 255, 27.0  / 255, 1 },    // Car
    { 144.0 / 255, 19.0  / 255, 254.0 / 255, 1 },    // Motorcycle
    { 189.0 / 255, 16.0  / 255, 224.0 / 255, 1 },    // Person
    { 74.0  / 255, 144.0 / 255, 226.0 / 255, 1 },    // RoadMarkupOther
    { 255.0 / 255, 159.0 / 255, 0.0   / 255, 1 },    // Curb
    { 255.0 / 255, 0.0   / 255, 0.0   / 255, 1 },    // Double yellow
    { 255.0 / 255, 0.0   / 255, 162.0 / 255, 1 },    // Traffic sign
    { 255.0 / 255, 255.0 / 255, 255.0 / 255, 1 }     // Traffic light
};

kernel void blend(texture2d<half, access::sample> sourceTexture [[texture(0)]],
                  texture2d<uint, access::sample> maskTexture [[texture(1)]],
                  texture2d<half, access::write> outTexture [[texture(2)]],
                  ushort3 gid [[thread_position_in_grid]])
{
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }
    
    constexpr sampler sourceSampler(coord::pixel, address::clamp_to_edge, filter::nearest);
    
    const half x = half(gid.x);
    const half y = half(gid.y);
    const half z = half(gid.z);
    
    const half4 s = sourceTexture.sample(sourceSampler, {x, y}, z);
    
    const half mx = x / half(sourceTexture.get_width());
    const half my = y / half(sourceTexture.get_height());
    
    constexpr sampler maskSampler(coord::normalized, address::clamp_to_edge, filter::nearest);
    
    const uint m = maskTexture.sample(maskSampler, { mx, my }).r;
    
    const half4 value = (segColors[m] * 0.6) + (s * 0.4);
    outTexture.write(value, gid.xy, gid.z);
}
