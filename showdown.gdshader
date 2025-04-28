shader_type canvas_item;

render_mode blend_add;

uniform vec2 center = vec2(0.5, 0.5);
uniform float line_density = 30.0;
uniform float speed = 1.0;
uniform float thickness = 0.02;
uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float fade = 1.5;

void fragment() {
    vec2 uv = UV;
    vec2 dir = uv - center;
    float angle = atan(dir.y, dir.x);
    float dist = length(dir);
    float lines = fract((angle / (2.0 * 3.14159)) * line_density - TIME * speed);
    float mask = smoothstep(0.5 - thickness, 0.5, lines) * (1.0 - smoothstep(0.5, 0.5 + thickness, lines));
    float fade_out = pow(dist, fade);

    COLOR = line_color * mask * fade_out;
}