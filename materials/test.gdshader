shader_type spatial;

uniform sampler2D albedo;
uniform sampler2D normal;
uniform sampler2D roughness;
uniform vec2 uv_scale = vec2(5, 5);

void fragment() {
	

	vec3 world_normal = (inverse(MODEL_MATRIX) * vec4(NORMAL, 0)).xyz;
	ALBEDO = world_normal;
//	if (world_normal.y > 0.0) {
//		ALBEDO = texture(albedo, UV*uv_scale).rgb;
//		NORMAL_MAP = texture(normal, UV*uv_scale).rgb;
//		ROUGHNESS = texture(roughness, UV*uv_scale).r;
//	} else {
//		ALPHA = 0.0;
//	}
	
}
