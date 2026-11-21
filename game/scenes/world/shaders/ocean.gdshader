shader_type spatial;
// 0.1.1 : style low poly cartoon. Les facettes viennent des dérivées écran (dFdx/dFdy) : chaque
// triangle a une seule normale, comme un modèle low poly. Les couleurs de profondeur sont en
// paliers doux et l'écume est une bande nette qui ondule.
// L'océan : vagues de Gerstner (GPU Gems 1, chap. 1), couleur selon l'épaisseur d'eau lue dans
// le tampon de profondeur (turquoise près du sable, bleu profond au large), écume au bord du
// rivage et reflet de Fresnel. Vu d'en dessous (le joueur plonge), la surface est un miroir
// argenté bleuté. Les vagues s'effacent avec la distance : au loin, un simple plan.
render_mode blend_mix, cull_disabled, depth_draw_always, specular_schlick_ggx;

uniform vec4 shallow_color : source_color = vec4(0.25, 0.85, 0.80, 1.0);
uniform vec4 mid_color : source_color = vec4(0.08, 0.55, 0.75, 1.0);
uniform vec4 deep_color : source_color = vec4(0.04, 0.25, 0.55, 1.0);
// Nombre de paliers de couleur (style cartoon) ; 0 = dégradé continu.
uniform float color_bands = 5.0;
// 1 = facettes low poly, 0 = surface lisse.
uniform float faceted = 1.0;
uniform vec4 foam_color : source_color = vec4(0.95, 0.98, 1.0, 1.0);
uniform vec4 under_color : source_color = vec4(0.35, 0.62, 0.72, 1.0);
// Épaisseur d'eau (m) à laquelle la couleur devient la couleur du large.
uniform float depth_scale = 6.0;
// Épaisseur d'eau (m) sous laquelle on dessine l'écume.
uniform float foam_depth = 0.35;
// Trois vagues : direction (x, z), raideur (0-1), longueur d'onde (m).
uniform vec4 wave_a = vec4(1.0, 0.3, 0.07, 14.0);
uniform vec4 wave_b = vec4(-0.4, 1.0, 0.05, 9.0);
uniform vec4 wave_c = vec4(0.7, -0.8, 0.04, 5.0);
// Au-delà de cette distance à la caméra, plus de vagues.
uniform float wave_fade_distance = 70.0;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest, repeat_disable;
// 0.1.13 : la carte des terres de l'île (1 = l'eau n'y monte jamais) : on n'y dessine pas l'eau,
// pour qu'un trou creusé près du niveau de la mer ne montre pas les vagues.
uniform sampler2D land_mask : filter_linear, repeat_disable;
uniform float land_mask_half_m = 72.0;

varying vec3 world_pos;

vec3 gerstner(vec4 wave, vec2 p, inout vec3 tangent, inout vec3 binormal) {
	float steep = wave.z;
	float k = 2.0 * PI / wave.w;
	float c = sqrt(9.8 / k);
	vec2 d = normalize(wave.xy);
	float f = k * (dot(d, p) - c * TIME);
	float a = steep / k;
	tangent += vec3(-d.x * d.x * steep * sin(f), d.x * steep * cos(f), -d.x * d.y * steep * sin(f));
	binormal += vec3(-d.x * d.y * steep * sin(f), d.y * steep * cos(f), -d.y * d.y * steep * sin(f));
	return vec3(d.x * a * cos(f), a * sin(f), d.y * a * cos(f));
}

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float fade = 1.0 - smoothstep(wave_fade_distance * 0.6, wave_fade_distance, distance(w.xz, CAMERA_POSITION_WORLD.xz));
	vec3 tangent = vec3(1.0, 0.0, 0.0);
	vec3 binormal = vec3(0.0, 0.0, 1.0);
	vec3 offset = gerstner(wave_a, w.xz, tangent, binormal);
	offset += gerstner(wave_b, w.xz, tangent, binormal);
	offset += gerstner(wave_c, w.xz, tangent, binormal);
	VERTEX += offset * fade;
	vec3 n = normalize(cross(binormal, tangent));
	NORMAL = normalize(mix(vec3(0.0, 1.0, 0.0), n, fade));
	world_pos = w + offset * fade;
}

void fragment() {
	vec2 muv = world_pos.xz / (2.0 * land_mask_half_m) + 0.5;
	if (muv.x > 0.0 && muv.x < 1.0 && muv.y > 0.0 && muv.y < 1.0 && texture(land_mask, muv).r > 0.5) {
		discard;
	}
	if (!FRONT_FACING) {
		// Sous l'eau, on regarde la surface d'en dessous.
		ALBEDO = under_color.rgb;
		ALPHA = 0.85;
		ROUGHNESS = 0.2;
		NORMAL = -NORMAL;
	} else {
		float depth = texture(depth_tex, SCREEN_UV).r;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
		vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
#else
		vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
#endif
		vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
		view.xyz /= view.w;
		float thickness = clamp(-view.z - (-VERTEX.z), 0.0, 1000.0);
		float t = clamp(thickness / depth_scale, 0.0, 1.0);
		if (color_bands > 0.0) {
			// Des paliers adoucis : on voit les « marches » de profondeur, sans arête dure.
			float k = t * color_bands;
			t = (floor(k) + smoothstep(0.75, 1.0, fract(k))) / color_bands;
		}
		vec3 col = t < 0.5 ? mix(shallow_color.rgb, mid_color.rgb, t * 2.0) : mix(mid_color.rgb, deep_color.rgb, t * 2.0 - 1.0);
		// Facettes : une normale par triangle.
		vec3 flat_n = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
		if (dot(flat_n, VIEW) < 0.0) {
			flat_n = -flat_n;
		}
		NORMAL = normalize(mix(NORMAL, flat_n, faceted));
		// Écume : une bande nette qui ondule au bord du rivage, et une seconde plus fine au large.
		float ripple = 0.5 + 0.5 * sin(world_pos.x * 1.7 + world_pos.z * 1.3 + TIME * 2.0);
		float edge = foam_depth * (0.7 + 0.6 * ripple);
		float foam = 1.0 - step(edge, thickness);
		float ring = (1.0 - step(0.06, abs(thickness - edge * 2.2))) * 0.7;
		col = mix(col, foam_color.rgb, max(foam, ring) * 0.9);
		float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
		ALBEDO = col;
		ALPHA = clamp(mix(0.6, 0.95, t) + fresnel * 0.3 + foam + ring, 0.0, 1.0);
		ROUGHNESS = 0.18;
		METALLIC = 0.0;
		SPECULAR = 0.6;
	}
}
