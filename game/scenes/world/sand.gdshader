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

uniform float level_cell_m = 1.0;
uniform float level_line_strength : hint_range(0.0, 1.0) = 0.18;
uniform float facet_amount : hint_range(0.0, 1.0) = 0.08;
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
// 0.1.13 : le même sable sur un objet (la motte, le tas sur la pelle) : une couleur fixe (`tint`,
// le maillage n'a pas de couleurs) et le motif lié à l'objet (il ne « glisse » pas quand l'objet
// bouge), sans rides ni traces de pelle.
uniform bool on_object = false;
uniform vec4 tint = vec4(1.0);
uniform float object_pattern_scale = 4.0;
// 0.1.16 : la motte ou le tas sur la pelle est de la terre (1) ou du sable (0).
uniform float object_earth = 0.0;
// 0.1.16 : le sol aplani, plus beau : du sable tassé, lisse et un peu plus clair, en dalles de
// 1 m à joints fins (un creux sombre et un bord éclairé), chaque dalle un rien différente ; la
// terre aplanie est ratissée (sillons parallèles).
uniform float level_tile_vary = 0.035;
uniform float level_bevel = 0.07;

varying vec3 world_pos;
varying vec4 facet_color;
// 0.1.16 : x = terre (1) ou sable (0), y = herbe (terre jamais travaillée).
varying vec2 soil;

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
	soil = UV;
	if (on_object) {
		// Le motif suit l'objet ; ni rides ni traces de pelle, et du sable sec.
		world_pos = vec3(VERTEX.x + VERTEX.y * 0.7, 10.0, VERTEX.z - VERTEX.y * 0.4) * object_pattern_scale;
		facet_color = vec4(tint.rgb, 0.0);
		soil = vec2(object_earth, 0.0);
	}
}

void fragment() {
	vec3 base = facet_color.rgb * exposure;
	vec2 p = world_pos.xz;
	float earth = clamp(soil.x, 0.0, 1.0);
	float grass = clamp(soil.y, 0.0, 1.0);
	float dry = smoothstep(sea_y + 0.08, sea_y + 0.3, world_pos.y);
	float worked = facet_color.a;
	vec3 world_n = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float flat_top = smoothstep(0.97, 0.995, world_n.y);
	// Le sol aplani (case nivelée, dessus plat) : 0 … 1.
	float level = smoothstep(0.6, 0.95, worked) * flat_top;
	// Les grains : deux tailles de points épars (moins sur le sol tassé ; des mottes sur la terre).
	float grain = speckles(p, grain_scale, 0.45) + speckles(p + 13.7, grain_scale * 0.45, 0.3) * 0.8;
	grain *= mix(1.0, 0.45, level * (1.0 - earth));
	grain *= 1.0 + earth * 0.6;
	// De grandes taches douces (sable plus ou moins tassé).
	float blotch = value_noise(p * 0.45) - 0.5 + (value_noise(p * 1.7) - 0.5) * 0.5;
	blotch *= 1.0 - level * 0.6;
	// Les rides du vent : des vagues un peu tordues par le bruit, sur le sable sec non travaillé.
	float warp = value_noise(p * 0.6) * 2.4;
	float ripple = sin((p.x * 0.8 + p.y * 0.6) * ripple_scale + warp * 2.0);
	ripple = smoothstep(0.55, 0.95, ripple) * dry * (1.0 - worked) * (1.0 - earth) * (on_object ? 0.0 : 1.0);
	// L'herbe : de petites touffes plus claires et plus sombres.
	float blades = (value_noise(p * 7.0) - 0.5) + (value_noise(vec2(p.x * 22.0, p.y * 5.0)) - 0.5) * 0.6;
	// Les traces de pelle sur du sable travaillé en pente douce (pas sur les dalles), des sillons
	// sur la terre aplanie.
	float marks = smoothstep(0.7, 0.95, sin(p.x * 9.0 + value_noise(p * 3.0) * 1.5)) * worked * dry * flat_top * (1.0 - level) * (1.0 - earth);
	float furrow = (sin(p.x * 14.0 + value_noise(p * 2.0) * 0.8) * 0.5 + 0.5) * level * earth;
	vec3 col = base;
	col *= 1.0 + grain * grain_strength;
	col *= 1.0 + blotch * blotch_strength * 2.0;
	col *= 1.0 + ripple * ripple_strength * 1.6;
	col *= 1.0 - marks * shovel_strength * 1.6;
	col *= 1.0 + blades * 0.22 * grass;
	col *= 1.0 - furrow * 0.12;
	// Le sable travaillé (pas aplani) est un peu plus frais (un rien plus foncé et plus chaud).
	col *= mix(vec3(1.0), vec3(0.96, 0.93, 0.88), worked * dry * (1.0 - level) * (1.0 - earth));
	// Le sable aplani : tassé, lisse, crème, une dalle de 1 m un rien différente de sa voisine.
	vec2 cell = floor(p / level_cell_m);
	float tone = (hash21(cell + 17.0) - 0.5) * 2.0 * level_tile_vary;
	col *= mix(vec3(1.0), vec3(1.05, 1.03, 0.98) * (1.0 + tone), level * dry * (1.0 - earth));
	col *= mix(vec3(1.0), vec3(0.95 + tone), level * earth);
	// Les joints entre dalles : un creux fin et, juste à côté (côté +x / +z), un bord éclairé.
	vec2 f = fract(p / level_cell_m) * level_cell_m;
	vec2 g = min(f, level_cell_m - f);
	float groove = 1.0 - smoothstep(0.008, 0.03, min(g.x, g.y));
	float lip = (1.0 - smoothstep(0.03, 0.07, min(f.x, f.y))) * (1.0 - groove);
	col *= 1.0 - groove * level * level_line_strength;
	col *= 1.0 + lip * level * level_bevel;
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
	// 0.1.15 : une rampe continue, sans palier : avec un soleil bas, une pente très douce
	// passait d'un coup dans le palier sombre et dessinait des pointes en étoile autour des trous.
	float lit = smoothstep(-0.2, 0.6, ndl) * ATTENUATION;
	DIFFUSE_LIGHT += LIGHT_COLOR / PI * (vec3(lit) + shadow_tint * 0.12 * (1.0 - lit));
}
