shader_type canvas_item;
// THROWAWAY SPIKE: tones the background down so the stage and fighters stand out, by fading it
// toward a light haze (like distance in real life) instead of darkening it.

// 1 = original colors, 0 = grey.
uniform float saturation : hint_range(0.0, 1.0) = 0.7;
// 0 = no haze, 1 = all haze color.
uniform float haze : hint_range(0.0, 1.0) = 0.35;
uniform vec4 haze_color : source_color = vec4(0.82, 0.87, 0.93, 1.0);

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float grey = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	color.rgb = mix(vec3(grey), color.rgb, saturation);
	color.rgb = mix(color.rgb, haze_color.rgb, haze);
	COLOR = color;
}
