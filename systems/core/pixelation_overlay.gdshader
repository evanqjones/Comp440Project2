shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float pixel_block_size : hint_range(1.0, 16.0, 1.0) = 3.0;

void fragment() {
	float block_size = max(pixel_block_size, 1.0);
	vec2 pixel_step = SCREEN_PIXEL_SIZE;
	vec2 block_step = pixel_step * block_size;
	vec2 sample_uv = (floor(SCREEN_UV / block_step) + vec2(0.5)) * block_step;
	sample_uv = clamp(sample_uv, pixel_step * 0.5, vec2(1.0) - pixel_step * 0.5);
	COLOR = textureLod(screen_texture, sample_uv, 0.0);
}
