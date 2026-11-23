shader_type spatial;
// Du texte peint dans la matière (textes peints, 2026-11-23) : la forme des lettres vient d'une texture (la police
// dessinée une fois), mais la peinture est éclairée comme l'objet qui la porte (soleil, ombres,
// nuit), un peu mate, avec des traces de pinceau, des bords qui bavent, des écailles là où elle
// est usée, et une couche assez fine pour laisser voir un peu le bois ou la toile dessous.
// Pas de contour, pas de billboard : rien qui « flotte » au-dessus de la surface.
render_mode blend_mix, depth_draw_never, cull_back, specular_schlick_ggx;

uniform sampler2D text_tex : hint_default_transparent, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec4 paint_color : source_color = vec4(0.1, 0.1, 0.1, 1.0);
// Taille du texte posé, en mètres : le bruit est calé sur des centimètres réels.
uniform vec2 quad_size = vec2(1.0, 0.2);
// Part de peinture partie (0 = neuve, 0.5 = bien écaillée).
uniform float wear : hint_range(0.0, 1.0) = 0.2;
// Variations de couleur des coups de pinceau (sens de la largeur).
uniform float streaks : hint_range(0.0, 1.0) = 0.25;
// Lettres un peu tremblées (en fraction de la hauteur du texte).
uniform float wobble : hint_range(0.0, 0.1) = 0.012;
// Bord qui bave : le contour mange ou déborde un peu, au hasard.
uniform float bleed : hint_range(0.0, 1.0) = 0.35;
// Opacité de la couche (moins de 1 : on devine la matière dessous).
uniform float coverage : hint_range(0.0, 1.0) = 0.9;
uniform float paint_roughness : hint_range(0.0, 1.0) = 0.8;
uniform float seed = 0.0;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int k = 0; k < 4; k++) {
		v += a * vnoise(p);
		p = p * 2.03 + vec2(17.1, 9.7);
		a *= 0.5;
	}
	return v / 0.9375;
}

void fragment() {
	vec2 p = UV * quad_size + vec2(seed * 7.13, seed * 3.71);  // en mètres
	// Lettres tracées à la main : un léger tremblé, à l'échelle de la lettre.
	float h = max(quad_size.y, 0.01);
	vec2 shake = vec2(vnoise(p / h * 2.5), vnoise(p / h * 2.5 + 31.0)) - 0.5;
	vec2 uv = UV + shake * wobble * h / quad_size;
	float a = texture(text_tex, uv).a;
	// Le bord bave : le seuil de la lettre bouge avec un grain fin (2 à 3 mm).
	float grain = fbm(p * 140.0);
	float edge = 0.5 + (grain - 0.5) * bleed;
	float w = max(fwidth(a), 0.02);
	float ink = smoothstep(edge - w, edge + w, a);
	// Écailles : de grandes taches (2 à 6 cm) où la peinture est partie, au bord déchiqueté.
	// La taille des écailles suit celle des lettres (un quart de lettre au plus) : on use sans
	// jamais effacer une lettre entière.
	float chips = fbm(p / h * 7.0 + 50.0) + (grain - 0.5) * 0.25;
	float keep = 1.0 - smoothstep(1.0 - wear * 0.55 - 0.04, 1.0 - wear * 0.55 + 0.02, chips);
	// Coups de pinceau : bandes étirées dans le sens de l'écriture.
	float brush = vnoise(vec2(p.x * 4.0, p.y * 90.0));
	float fine = vnoise(vec2(p.x * 30.0, p.y * 400.0));
	float stroke = (brush - 0.5) * 0.7 + (fine - 0.5) * 0.3;
	// La couche est plus mince par endroits : on y devine la matière.
	float thick = coverage * (1.0 - streaks * 0.35 * (0.5 - stroke)) * mix(0.85, 1.0, grain);
	ALBEDO = paint_color.rgb * (1.0 + stroke * streaks * 0.5) * mix(0.92, 1.04, grain);
	ROUGHNESS = clamp(paint_roughness + (grain - 0.5) * 0.15, 0.0, 1.0);
	SPECULAR = 0.25;
	ALPHA = clamp(ink * keep * thick * paint_color.a, 0.0, 1.0);
}
