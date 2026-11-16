shader_type sky;
// Le ciel cartoon (0.1.1) : un dégradé à trois couleurs (zénith, horizon, sous l'horizon) qui suit
// l'heure, un soleil rond à bord net avec un halo doux, plus chaud quand il est bas, et des
// étoiles la nuit. La direction et la force du soleil viennent de la lumière directionnelle
// (LIGHT0_*), donc le cycle jour/nuit de main.gd pilote tout, sans rien de plus à brancher.

uniform vec4 day_top : source_color = vec4(0.22, 0.52, 0.92, 1.0);
uniform vec4 day_horizon : source_color = vec4(0.62, 0.84, 0.98, 1.0);
uniform vec4 sunset_horizon : source_color = vec4(0.98, 0.62, 0.38, 1.0);
uniform vec4 night_top : source_color = vec4(0.02, 0.04, 0.12, 1.0);
uniform vec4 night_horizon : source_color = vec4(0.07, 0.12, 0.25, 1.0);
uniform vec4 below_color : source_color = vec4(0.10, 0.36, 0.52, 1.0);
uniform vec4 sun_color : source_color = vec4(1.0, 0.95, 0.75, 1.0);
uniform vec4 sun_low_color : source_color = vec4(1.0, 0.55, 0.25, 1.0);
// Taille apparente du disque (cosinus de son demi-angle) et largeur du halo.
uniform float sun_size = 0.9992;
uniform float halo_power = 220.0;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	// La nuit, le soleil est éteint (LIGHT0_ENABLED faux) : on le met sous l'horizon.
	vec3 sun_dir = LIGHT0_ENABLED ? LIGHT0_DIRECTION : vec3(0.0, -1.0, 0.0);
	// Hauteur du soleil : 1 à midi, 0 à l'horizon, négative la nuit.
	float sun_h = sun_dir.y;
	float day = smoothstep(-0.12, 0.25, sun_h);
	float sunset = (1.0 - smoothstep(0.0, 0.35, abs(sun_h))) * day;
	vec3 top = mix(night_top.rgb, day_top.rgb, day);
	vec3 horizon = mix(night_horizon.rgb, day_horizon.rgb, day);
	// Côté soleil, l'horizon rougit au coucher.
	float toward_sun = pow(max(dot(normalize(dir.xz + 1e-4), normalize(sun_dir.xz + 1e-4)), 0.0), 2.0);
	horizon = mix(horizon, sunset_horizon.rgb, sunset * (0.35 + 0.65 * toward_sun));
	float up = clamp(dir.y, 0.0, 1.0);
	vec3 col = mix(horizon, top, pow(up, 0.55));
	if (dir.y < 0.0) {
		col = mix(horizon, below_color.rgb * mix(0.25, 1.0, day), smoothstep(0.0, -0.15, dir.y));
	}
	// Le soleil : disque net + halo, plus orange près de l'horizon.
	if (LIGHT0_ENABLED) {
		float d = dot(dir, sun_dir);
		vec3 sc = mix(sun_low_color.rgb, sun_color.rgb, smoothstep(0.0, 0.4, sun_h));
		float disk = smoothstep(sun_size - 0.00015, sun_size, d);
		float halo = pow(max(d, 0.0), halo_power) * 0.6 + pow(max(d, 0.0), 12.0) * 0.12;
		col += sc * (disk * 2.5 + halo) * day;
	}
	// Les étoiles, la nuit seulement.
	if (dir.y > 0.0) {
		vec3 cell = floor(dir * 220.0);
		float star = step(0.9975, hash(cell));
		col += vec3(star) * (1.0 - day) * smoothstep(0.0, 0.2, dir.y);
	}
	COLOR = col;
}
