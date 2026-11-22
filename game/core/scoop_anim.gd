class_name ScoopAnim
extends RefCounted
## Le geste de puiser (0.1.18) : la courbe du mouvement du seau pendant que l'on maintient le clic
## dans la mer, puis le retour, lourd, quand le seau est plein. Logique pure (aucun nœud) : la vue
## (player.gd) lit ces valeurs et place le seau ; SoundBoard lit SPLASH_AT pour le « plouf ».
##
## Le geste suit les principes d'animation des jeux (anticipation, action, suite) :
##  1. Anticipation (0 → 0,12) : le seau se soulève un peu et bascule vers soi.
##  2. Plongée (0,12 → 0,32) : il plonge vers la mer devant soi, l'ouverture vers l'avant (80°).
##     Il touche l'eau à SPLASH_AT : éclaboussure et bruit.
##  3. Ramassage (0,32 → 0,78) : sous l'eau, il est tiré vers soi en se redressant (on « racle » l'eau).
##  4. Remontée (0,78 → 1) : il sort de l'eau, encore bas ; l'eau dedans est déjà montée.
##  5. Après (RELEASE_S) : le seau plein remonte jusqu'à la main, lourd (il s'affaisse un peu
##     avant de se caler) et oscille ; quelques gouttes tombent.
## `p` est l'avancement du remplissage (BucketLogic.fill_progress_ratio), donc le geste suit
## toujours la durée de remplissage réglée dans game_config.tres.

## Moment où le seau touche l'eau.
const SPLASH_AT := 0.3
## Durée du retour du seau plein jusqu'à la main.
const RELEASE_S := 0.45
## Distance devant les pieds où le seau entre dans l'eau, puis où il finit le ramassage (m).
const REACH_FAR_M := 1.05
const REACH_NEAR_M := 0.8
## On se baisse pour puiser (la tête descend de tant de mètres, et regarde un peu vers le bas).
const CROUCH_M := 0.32
const LOOK_DOWN_DEG := 18.0


## Pose du seau pendant que l'on puise. Renvoie :
##  dip   : 0 = en main, 1 = dans la mer (mélange entre les deux places) ;
##  tilt  : bascule de l'ouverture vers l'avant, en degrés (négatif = vers soi) ;
##  lift  : petit soulèvement en main (anticipation), en mètres ;
##  pull  : 0 = loin devant, 1 = ramené vers soi (le ramassage) ;
##  sink  : profondeur sous la surface, en mètres.
static func pose(p: float) -> Dictionary:
	p = clampf(p, 0.0, 1.0)
	var dip := 0.0
	if p < 0.12:
		dip = 0.0
	elif p < 0.32:
		dip = _ease_in_out(inverse_lerp(0.12, 0.32, p))
	elif p < 0.78:
		dip = 1.0
	else:
		dip = lerpf(1.0, 0.4, _ease_in_out(inverse_lerp(0.78, 1.0, p)))
	var tilt := 0.0
	if p < 0.12:
		tilt = -12.0 * sin(PI * 0.5 * p / 0.12)
	elif p < 0.32:
		tilt = lerpf(-12.0, 80.0, _ease_in_out(inverse_lerp(0.12, 0.32, p)))
	elif p < 0.78:
		tilt = lerpf(80.0, 15.0, _ease_in_out(inverse_lerp(0.32, 0.78, p)))
	else:
		tilt = lerpf(15.0, 0.0, inverse_lerp(0.78, 1.0, p))
	var lift := 0.07 * sin(PI * p / 0.14) if p < 0.14 else 0.0
	var pull := _ease_in_out(clampf(inverse_lerp(0.32, 0.78, p), 0.0, 1.0))
	var sink := 0.0
	if p >= 0.32 and p < 0.78:
		sink = 0.07 * sin(PI * inverse_lerp(0.32, 0.78, p))
	return {"dip": dip, "tilt": tilt, "lift": lift, "pull": pull, "sink": sink}


## Après le remplissage (t secondes depuis la fin) : le seau plein remonte à la main.
## Même forme que pose() ; il s'affaisse sous le poids (dip un peu négatif = plus bas que la main)
## et oscille avant de se caler. Tout revient à 0 à RELEASE_S.
static func release(t: float) -> Dictionary:
	var k := clampf(t / RELEASE_S, 0.0, 1.0)
	var dip := 0.4 * (1.0 - _ease_out(minf(k * 1.6, 1.0)))
	var sag := -0.05 * sin(PI * k) * (1.0 - k)  # plus bas que la main : c'est lourd
	var tilt := 9.0 * sin(t * 24.0) * exp(-t * 7.0) * (1.0 - k)
	return {"dip": dip, "tilt": tilt, "lift": sag, "pull": 1.0, "sink": 0.0}


## Part de l'eau montrée dans le seau pendant le geste : l'eau n'entre qu'une fois le seau dans
## la mer (avant, le seau qu'on lève restait vide), et il est plein en sortant.
static func water_in(p: float) -> float:
	return smoothstep(SPLASH_AT, 0.8, clampf(p, 0.0, 1.0))


## Vrai si l'avancement est passé de `before` à `after` en franchissant le contact avec l'eau.
static func hits_water(before: float, after: float) -> bool:
	return before < SPLASH_AT and after >= SPLASH_AT


static func _ease_in_out(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


static func _ease_out(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return 1.0 - (1.0 - x) * (1.0 - x)
