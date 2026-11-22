class_name CrabPose
extends RefCounted
## Les poses du crabe de compagnie (0.1.19) : pour une animation et un instant, l'angle de chaque
## articulation. Calculs purs (sinusoïdes), sans scène : la vue (PetCrab) applique ces angles à
## ses pivots, et les tests vérifient les poses sans rien afficher.
## Idée reprise des crabes animés « avec des maths » sous Godot : une marche en deux groupes de
## pattes qui alternent, un corps qui rebondit, et des gestes exagérés (principes Disney :
## anticipation, écrasement-étirement, mouvements secondaires des yeux).

enum Anim { IDLE, WALK, HAPPY, EAT, SLEEP, WAVE, REFUSE, HUNGRY }

## Pattes par côté. Patte i : côté = i / LEGS_PER_SIDE (0 gauche, 1 droite), rang = i % LEGS_PER_SIDE.
const LEGS_PER_SIDE := 4
const LEGS := LEGS_PER_SIDE * 2
## Un clignement toutes les BLINK_PERIOD s environ, qui dure BLINK_S.
const BLINK_PERIOD := 3.4
const BLINK_S := 0.16
## Vitesse de la marche (cycles de pas par seconde, à multiplier par 2π).
const STEP_HZ := 2.6


## Groupe de marche d'une patte (0 ou 1) : les deux groupes alternent, comme un vrai crabe.
static func gait_group(leg: int) -> int:
	return (leg % LEGS_PER_SIDE + leg / LEGS_PER_SIDE) % 2


## La pose complète. Clés :
## body_y (m, au-dessus du repos), body_roll, body_pitch, body_yaw (rad), squash (échelle verticale),
## leg_lift[i], leg_swing[i], knee[i] (rad), claw_raise[2], claw_spread[2], claw_open[2] (rad),
## stalk_tilt[2] (rad, vers l'arrière), blink (0 ouvert, 1 fermé), happy_eyes (0..1, yeux « ^ ^ »),
## pupil (Vector2, -1..1), mouth (0..1).
static func pose(anim: Anim, t: float) -> Dictionary:
	var p := {
		"body_y": 0.0, "body_roll": 0.0, "body_pitch": 0.0, "body_yaw": 0.0, "squash": 1.0,
		"leg_lift": _zeros(LEGS), "leg_swing": _zeros(LEGS), "knee": _filled(LEGS, 0.0),
		"claw_raise": [0.15, 0.15], "claw_spread": [0.0, 0.0], "claw_open": [0.15, 0.15],
		"stalk_tilt": [0.0, 0.0], "blink": blink(t), "happy_eyes": 0.0,
		"pupil": Vector2(sin(t * 0.7) * 0.6, sin(t * 0.43) * 0.3), "mouth": 0.0,
	}
	# Respiration : le corps gonfle un peu, toujours.
	p.squash = 1.0 + sin(t * 2.2) * 0.025
	match anim:
		Anim.IDLE:
			# Un petit claquement de pince de temps en temps, les yeux regardent autour.
			var click := maxf(sin(t * 0.9) - 0.85, 0.0) / 0.15
			p.claw_open = [0.15 + click * 0.5 * absf(sin(t * 18.0)), 0.15]
			p.stalk_tilt = [sin(t * 0.8) * 0.12, sin(t * 0.8 + 0.6) * 0.12]
		Anim.WALK:
			var w := t * TAU * STEP_HZ
			for i in LEGS:
				var ph := w + gait_group(i) * PI
				p.leg_lift[i] = maxf(sin(ph), 0.0) * 0.55
				p.leg_swing[i] = cos(ph) * 0.35
			p.body_y = absf(sin(w)) * 0.012
			p.body_roll = sin(w) * 0.06
			p.claw_raise = [0.3 + sin(w) * 0.08, 0.3 - sin(w) * 0.08]
			p.stalk_tilt = [sin(w + 1.0) * 0.1, sin(w + 1.6) * 0.1]
		Anim.HAPPY:
			# Il sautille, pinces en l'air qui applaudissent, yeux plissés de bonheur.
			var hop := absf(sin(t * 7.0))
			p.body_y = hop * 0.07
			p.squash = 1.0 + (0.5 - hop) * 0.16
			p.claw_raise = [1.15 + sin(t * 14.0) * 0.15, 1.15 - sin(t * 14.0) * 0.15]
			p.claw_spread = [0.25 + sin(t * 14.0) * 0.3, 0.25 + sin(t * 14.0) * 0.3]
			p.claw_open = [0.5 + 0.4 * sin(t * 14.0), 0.5 + 0.4 * sin(t * 14.0)]
			for i in LEGS:
				p.leg_lift[i] = maxf(sin(t * 14.0 + i), 0.0) * 0.3 * (1.0 - hop)
			p.happy_eyes = 1.0
			p.blink = 0.0
			p.mouth = 0.6
		Anim.EAT:
			# Les pinces portent la croquette à la bouche, l'une après l'autre ; la bouche mâche.
			p.claw_raise = [0.25 + maxf(sin(t * 6.0), 0.0) * 0.8, 0.25 + maxf(sin(t * 6.0 + PI), 0.0) * 0.8]
			p.claw_spread = [-0.35, -0.35]
			p.claw_open = [0.1, 0.1]
			p.mouth = absf(sin(t * 12.0))
			p.body_pitch = 0.08 + sin(t * 12.0) * 0.02
			p.happy_eyes = 0.6
		Anim.SLEEP:
			# Couché, les yeux rentrés et fermés, la respiration lente.
			p.body_y = -0.035
			p.squash = 1.0 + sin(t * 1.4) * 0.05
			p.stalk_tilt = [1.25, 1.25]
			p.blink = 1.0
			p.pupil = Vector2.ZERO
			p.claw_raise = [-0.1, -0.1]
			p.claw_open = [0.0, 0.0]
			p.claw_spread = [-0.3, -0.3]
			p.knee = _filled(LEGS, 0.55)
		Anim.WAVE:
			# Bonjour ! La pince droite se lève et s'agite, le corps penche vers elle.
			p.claw_raise = [0.25, 1.35]
			p.claw_spread = [0.0, 0.35 + sin(t * 9.0) * 0.45]
			p.claw_open = [0.15, 0.35 + 0.35 * sin(t * 18.0)]
			p.body_roll = 0.1
			p.mouth = 0.4
			p.happy_eyes = 0.4
		Anim.REFUSE:
			# « Non merci, je n'ai plus faim » : il secoue le corps, pinces croisées devant.
			p.body_yaw = sin(t * 13.0) * 0.28
			p.claw_raise = [0.55, 0.55]
			p.claw_spread = [-0.55, -0.55]
			p.claw_open = [0.0, 0.0]
			p.blink = maxf(p.blink, 0.55)
		Anim.HUNGRY:
			# Il boude : yeux tombants, pinces basses, un soupir de temps en temps.
			var sigh := maxf(sin(t * 0.6), 0.0)
			p.stalk_tilt = [0.45 + sigh * 0.15, 0.45 + sigh * 0.15]
			p.blink = maxf(p.blink, 0.35)
			p.claw_raise = [-0.05, -0.05]
			p.claw_open = [0.05 + absf(sin(t * 2.5)) * 0.2, 0.05]
			p.body_y = -sigh * 0.01
			p.pupil = Vector2(0.0, -0.6)
	return p


## Fermeture des paupières (0 ouvert, 1 fermé) : un clignement court à intervalles un peu irréguliers.
static func blink(t: float) -> float:
	var cycle := floori(t / BLINK_PERIOD)
	# Décalage pseudo-aléatoire du clignement dans son cycle (même valeur à chaque appel).
	var offset := fposmod(sin(float(cycle) * 12.9898) * 43758.5453, 1.0) * (BLINK_PERIOD - BLINK_S)
	var local := t - cycle * BLINK_PERIOD - offset
	if local < 0.0 or local > BLINK_S:
		return 0.0
	return sin(local / BLINK_S * PI)


static func _zeros(n: int) -> Array:
	return _filled(n, 0.0)


static func _filled(n: int, v: float) -> Array:
	var a := []
	a.resize(n)
	a.fill(v)
	return a
