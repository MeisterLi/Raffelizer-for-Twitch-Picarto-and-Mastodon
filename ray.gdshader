shader_type canvas_item;

uniform float thickness = 0.015;
uniform float jaggedness = 30.0;
uniform float speed = 2.0;
uniform vec4 lightning_color : source_color = vec4(0.8, 0.9, 1.0, 1.0);

float noise(vec2 uv) {
    return abs(sin(uv.x * jaggedness + TIME * speed));
}

void fragment() {
    vec2 uv = UV;
    uv.y = 1.0 - uv.y;

    float lightning_center = 0.5 + (noise(vec2(uv.y, uv.x)) - 0.5) * 0.2;

    float dist = abs(uv.x - lightning_center);

    float core = smoothstep(thickness, 0.0, dist);

    COLOR = lightning_color * core;
}