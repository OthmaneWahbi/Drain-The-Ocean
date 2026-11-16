shader_type canvas_item;
// Le filtre « sous l'eau » : l'image ondule un peu, prend une teinte bleu-vert et s'assombrit
// sur les bords (technique classique de post-traitement plein écran).

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec4 tint : source_color = vec4(0.05, 0.35, 0.45, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.45;
uniform float wobble = 0.004;

void fragment() {
	vec2 uv = SCREEN_UV;
	uv += vec2(sin(uv.y * 28.0 + TIME * 2.1), cos(uv.x * 23.0 + TIME * 1.7)) * wobble;
	vec3 c = textureLod(screen_tex, uv, 1.5).rgb;
	c = mix(c, tint.rgb, strength);
	float vignette = smoothstep(1.05, 0.35, length(SCREEN_UV - vec2(0.5)));
	COLOR = vec4(c * mix(0.55, 1.0, vignette), 1.0);
}
