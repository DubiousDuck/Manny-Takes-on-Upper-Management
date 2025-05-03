shader_type canvas_item;

// Controlling effect mode
uniform int effect_mode = 0; //0 = outline, 1 = flash, 2 = teleport

// Controlling outline
uniform vec4 line_color : source_color = vec4(1);
uniform float line_thickness : hint_range(0, 10) = 1.0;

// Controlling flash effect
uniform vec4 color: source_color;
uniform float flash_state: hint_range(0.0, 1.0, 0.1);
uniform float transparency: hint_range(0.0, 1.0, 0.1);

//For teleporting effect
uniform float progress : hint_range(0.0, 1.0);
uniform float noise_desnity = 60;
uniform float beam_size : hint_range(0.01, 0.15);
uniform vec4 teleport_color : source_color = vec4(0.0, 1.02, 1.2, 1.0);

// We are generating our own noise here. You could experiment with the
// built in SimplexNoise or your own noise texture for other effects.
vec2 random(vec2 uv){
    uv = vec2( dot(uv, vec2(127.1,311.7) ),
               dot(uv, vec2(269.5,183.3) ) );
    return -1.0 + 2.0 * fract(sin(uv) * 43758.5453123);
}

float noise(vec2 uv) {
    vec2 uv_index = floor(uv);
    vec2 uv_fract = fract(uv);

    vec2 blur = smoothstep(0.0, 1.0, uv_fract);

    return mix( mix( dot( random(uv_index + vec2(0.0,0.0) ), uv_fract - vec2(0.0,0.0) ),
                     dot( random(uv_index + vec2(1.0,0.0) ), uv_fract - vec2(1.0,0.0) ), blur.x),
                mix( dot( random(uv_index + vec2(0.0,1.0) ), uv_fract - vec2(0.0,1.0) ),
                     dot( random(uv_index + vec2(1.0,1.0) ), uv_fract - vec2(1.0,1.0) ), blur.x), blur.y) * 0.5 + 0.5;
}

void fragment() {
	// outline effect
	vec2 size = TEXTURE_PIXEL_SIZE * line_thickness;

	float outline = texture(TEXTURE, UV + vec2(-size.x, 0)).a;
	outline += texture(TEXTURE, UV + vec2(0, size.y)).a;
	outline += texture(TEXTURE, UV + vec2(size.x, 0)).a;
	outline += texture(TEXTURE, UV + vec2(0, -size.y)).a;
	outline += texture(TEXTURE, UV + vec2(-size.x, size.y)).a;
	outline += texture(TEXTURE, UV + vec2(size.x, size.y)).a;
	outline += texture(TEXTURE, UV + vec2(-size.x, -size.y)).a;
	outline += texture(TEXTURE, UV + vec2(size.x, -size.y)).a;
	outline = min(outline, 1.0);

	vec4 pixelColor = texture(TEXTURE, UV);

	COLOR = mix(pixelColor, line_color, outline - pixelColor.a);

	// flash effect
	if (effect_mode == 1){
		vec4 pixelColor = texture(TEXTURE, UV);
		COLOR = mix(pixelColor, color, flash_state);
		COLOR.a *= pixelColor.a * transparency; //preserves parent material transparency
	}

	//teleport effect
	if (progress > 0.0){
		vec4 tex = texture(TEXTURE, UV);

		float noise = noise(UV * noise_desnity) * UV.y;

		float d1 = step(progress, noise);
		float d2 = step(progress - beam_size, noise);

		vec3 beam = vec3(d2 - d1) * teleport_color.rgb;

		tex.rgb += beam;
		tex.a *= d2;

		COLOR = tex;
	}
}
