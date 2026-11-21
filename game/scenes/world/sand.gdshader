shader_type spatial;
// Le sable de l'île (0.1.11) : un sable cartoon qui a l'air de sable.
//  - la couleur de chaque facette vient du maillage (TerrainLogic.color : sable sec, mouillé,
//    fond, herbe), son canal alpha dit si la case a été travaillée à la pelle ;
//  - des grains (petits points clairs et sombres) et de grandes taches douces, en coordonnées
//    du monde (le motif ne glisse pas quand on reconstruit un morceau) ;
//  - des rides de vent sur le sable sec, des traces de pelle sur le sable travaillé ;
//  - une lumière en deux paliers adoucis (style cartoon), et des facettes à demi lissées
//    (`facet_amount`) : on voit encore le low poly sans les gros pans plats.
render_mode cull_disabled, specular_disabled;

uniform float facet_amount : hint_range(0.0, 1.0) = 0.15;
uniform float grain_strength : hint_range(0.0, 0.5) = 0.12;
uniform float grain_scale = 9.0;
uniform float blotch_strength : hint_range(0.0, 0.5) = 0.07;
uniform float ripple_strength : hint_range(0.0, 0.5) = 0.07;
uniform float ripple_scale = 3.2;
uniform float shovel_strength : hint_range(0.0, 0.5) = 0.06;
uniform vec3 shadow_tint : source_color = vec3(0.62, 0.55, 0.72);
uniform float sea_y = 0.0;
// Les couleurs du maillage sont choisies à l'œil : on les prend telles quelles, un peu moins
// fort que la lumière du soleil (le sable n'est plus « brûlé » en blanc-jaune). 0.1.12 : un peu
// plus clair et plus saturé (une plage tropicale).
uniform float exposure = 0.8;

varying vec3 world_pos;
varying vec4 facet_color;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Des grains de sable cartoon : de petits points ronds épars, clairs ou sombres (+1 / -1 / 0).
// Ils s'effacent au loin (sinon ils scintillent).
float speckles(vec2 p, float scale, float density) {
	vec2 q = p * scale;
	vec2 id = floor(q);
	vec2 f = fract(q);
	float h = hash21(id);
	vec2 c = vec2(hash21(id + 3.1), hash21(id + 7.7)) * 0.6 + 0.2;
	float r = 0.1 + hash21(id + 5.3) * 0.08;
	float d = length(f - c);
	float on = step(h, density) * (1.0 - smoothstep(r * 0.7, r, d));
	float sgn = hash21(id + 11.0) > 0.45 ? 1.0 : -1.0;
	float fade = clamp(1.6 - fwidth(q.x) * 6.0, 0.0, 1.0);
	return on * sgn * fade;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	facet_color = COLOR;
}

void fragment() {
	vec3 base = facet_color.rgb * exposure;
	vec2 p = world_pos.xz;
	// Les grains : deux tailles de points épars.
	float grain = speckles(p, grain_scale, 0.45) + speckles(p + 13.7, grain_scale * 0.45, 0.3) * 0.8;
	// De grandes taches douces (sable plus ou moins tassé).
	float blotch = value_noise(p * 0.45) - 0.5 + (value_noise(p * 1.7) - 0.5) * 0.5;
	float dry = smoothstep(sea_y + 0.08, sea_y + 0.3, world_pos.y);
	float worked = facet_color.a;
	// Les rides du vent : des vagues un peu tordues par le bruit, sur le sable sec non travaillé.
	float warp = value_noise(p * 0.6) * 2.4;
	float ripple = sin((p.x * 0.8 + p.y * 0.6) * ripple_scale + warp * 2.0);
	ripple = smoothstep(0.55, 0.95, ripple) * dry * (1.0 - worked);
	// Les traces de pelle : de petites bandes parallèles, dans chaque case travaillée.
	// (sur le dessus plat des cases seulement : pas de rayures dans les pentes).
	vec3 world_n = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float flat_top = smoothstep(0.97, 0.995, world_n.y);
	float marks = smoothstep(0.7, 0.95, sin(p.x * 9.0 + value_noise(p * 3.0) * 1.5)) * worked * dry * flat_top;
	vec3 col = base;
	col *= 1.0 + grain * grain_strength;
	col *= 1.0 + blotch * blotch_strength * 2.0;
	col *= 1.0 + ripple * ripple_strength * 1.6;
	col *= 1.0 - marks * shovel_strength * 1.6;
	// Le sable travaillé est un peu plus frais (un rien plus foncé et plus chaud).
	col *= mix(vec3(1.0), vec3(0.96, 0.93, 0.88), worked * dry);
	ALBEDO = col;
	ROUGHNESS = 1.0;
	// Des facettes à demi lissées : la normale du maillage (lissée) et celle de la facette.
	vec3 flat_n = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
	if (dot(flat_n, NORMAL) < 0.0) {
		flat_n = -flat_n;
	}
	NORMAL = normalize(mix(NORMAL, flat_n, facet_amount));
}

void light() {
	// Deux paliers adoucis (style cartoon) ; dans l'ombre, un reflet teinté plutôt que du gris.
	float ndl = dot(NORMAL, LIGHT);
	float lit = (smoothstep(-0.05, 0.15, ndl) * 0.55 + smoothstep(0.12, 0.4, ndl) * 0.45) * ATTENUATION;
	DIFFUSE_LIGHT += LIGHT_COLOR / PI * (vec3(lit) + shadow_tint * 0.12 * (1.0 - lit));
}
