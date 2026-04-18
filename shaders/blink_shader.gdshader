shader_type canvas_item;

uniform vec4 flash_color : source_color = vec4(1.0);
uniform float flash_pct : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 original_color = texture(TEXTURE, UV);
    vec4 mixed_color = mix(original_color, flash_color, flash_pct);

    COLOR = mixed_color;
    COLOR.a = original_color.a;
}
