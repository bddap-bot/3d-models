run-id: B2

# Seed hopper for a green-cheek conure — small feeder door, A1 mini, PETG

## (a) Approach and tools

**Requirement in one sentence:** a ~1 L gravity feeder that hangs outside the cage, seats
in a 110 x 110 feeder-door opening, refills from outside, and cannot jam on sticky 25 mm
banana slices.

**Dumbest design that satisfies it:** a straight-walled wedge bin whose only convergence
is in one plane, discharging through a full-width slot into a shallow pan the bird eats
from; the pan's seed pile chokes the slot, so flow is self-regulating and there is no
gate, no auger, no moving flow control. Everything else is mounting, and every mounting
feature has to name the motion it blocks or it gets deleted. One did get deleted — see
step 6.

| tool | why |
| --- | --- |
| OpenSCAD 2021.01 | the plane-flow geometry *is* a 2D side profile swept along the width, so extruding a Y-Z polygon gives exact, provable wall angles and thicknesses; the spec asks for `hopper.scad` |
| OpenSCAD boolean intersections | interference, door fit and **swept-motion** checks on the exact CSG rather than on a mesh approximation — an empty intersection is a proof, not an estimate |
| trimesh 4.9 / numpy / scipy | mesh validity, bounding boxes, ray-cast wall thickness, capacity by mesh volume, and a ray grid for door coverage |
| PrusaSlicer 2.x CLI | independent printability: does it slice, does it fit the bed, how much support |
| xvfb-run + OpenSCAD `--render` | offscreen renders of the assembly and each part |

The decision that carried the most weight: the **cage wall itself** — vertical bars at
12 mm pitch, a rail top and bottom of the opening, the 110 x 110 opening cut out — is a
solid in the same source. Fit, captivity and door coverage are then measured against it
under translation, so "does it fit", "can the bird get it out" and "does it leave a hole
in the cage" all become numbers instead of judgement calls.

## (b) Steps taken, including dead ends

1. Sized the cavity from the capacity target. **Dead end:** my first hand calculation
   used `(bottom + rise) x height` instead of the trapezoid `(bottom + top)/2 x height`,
   so the first geometry held 780 cm3. Caught by measuring the cavity mesh, not by
   re-reading the algebra. Fixed by widening the outlet slot from 60 to 80 mm, which also
   helps flow.
2. Chased the cavity width down a constraint chain: opening 110 -> tray outer 104 -> tray
   wall positions -> rail positions -> cavity width 88. **Dead end:** three earlier
   layouts put the tray rails inboard of the outlet, which would have dumped seed onto
   the rails outside the tray walls. Resolved by making the tray interior and the outlet
   the same 88 mm.
3. Mounting, first attempt. **Dead ends:** a toggle bar that rotates behind the opening
   (a 130 x 60 plate cannot pass a 110 x 110 square at any angle — `w cos t + h sin t <= s`
   fails for all t); a lock slider on the front plate's inner face (that face is the
   cavity, so it would sit in the seed); a lock at Z 96-112, which is inside the opening
   and therefore inside the bird's reach.
4. Built the parts, then hunted defects numerically. Found and fixed: a latch in three
   disconnected pieces; four part-to-part interferences; the flange fouling the top rail
   by 0.2 mm; a **2.26 mm back wall** caused by placing the outer profile's top vertex at
   the shell top instead of on the 62 degree line, so the wall tapered as it rose; and
   0.1-0.9 mm slivers where an inclined slot grazed a prismatic boss, only cured by
   building the boss in the same inclined frame as the slot.
5. Orientation search by slicer. **Dead end:** I assumed printing the body on its side
   would be right, because that puts layer lines along the flow. It is the worst
   orientation: the body is an X-swept prism, so laying it down turns an 88 x 136 mm side
   wall into an unsupported roof over the whole cavity — 174 cm3 of support against
   45 cm3 upright.
6. **Deleted the anti-lift latch.** Review showed it had no assembly path (both ends of
   its slot were blocked by the body) and that its 15 degree slot inclined the wrong way,
   so gravity retracted it rather than engaging it. Rather than patch a fourth iteration
   of a part whose only job was to add 2 mm of lift resistance, I lengthened the hook legs
   from 8 mm to 20 mm of engagement and *measured* what it takes to get the body off: 24
   mm of lift. One part fewer, no mechanism, and a stronger result.
7. Rebuilt the tray's capture. The first version could not be removed — its rear plate
   fouled the upper rail after 4 mm. Narrowed the rear plate inboard of the rails, ran
   both rails the full length, and replaced the outer stop rib (which blocked the wrong
   direction) with a **sawtooth on the lower rail**: a vertical face hard-stops push-in, a
   ramp lets pull-out ride over. Then a second review showed the channel had 1.4 mm of
   free play against a 1.3 mm tooth, so the tooth could simply be lifted over; the channel
   is now 0.4 mm and the tooth 0.8 mm above the floor, needing 0.4 mm of deflection.
8. Moved the perch twice. It first sat directly under the tray floor with 8 mm of
   headroom, which no conure can stand on. Moved 17 mm forward of the tray's front lip on
   raked posts; then raised to Z = 36 so it clears the door shroud added in step 9.
9. **Closed the door.** A ray grid through the opening showed the mounted assembly left
   3486 mm2 of the cage wall open, including a 110 mm-wide gap below the tray — an escape
   and entrapment hole. Added a front shroud from Z = 6 to the outlet, apertured only for
   the tray and perch. Clear area is now 1058 mm2 in five slivers, the largest of which is
   5.5 mm tall. This is what pushed the body to 174.2 mm in Z, 0.8 mm under the limit.

## (c) Dimensions, part list, capacity

Datum: Y = 0 is the plane of the cage bars (bars occupy Y -1.5..+1.5), +Y points out of
the cage; Z = 0 is the sill of the door opening, which spans Z 0..110, X -55..+55.

| part | qty | bounding box X x Y x Z (mm) | solid volume | role |
| --- | --- | --- | --- | --- |
| `body` | 1 | 136.0 x 153.5 x 174.2 | 229.9 cm3 | wedge bin, outlet slot, flange, door shroud, hooks, tray rails |
| `tray` | 1 | 104.8 x 170.0 x 42.0 | 135.7 cm3 | removable feed pan, rolled hull lip, integral perch, rear stop plate |
| `lid` | 1 | 103.0 x 148.0 x 23.2 | 77.7 cm3 | refill cap, 20 mm skirt on three sides, inner front lip, detent |

Three parts, no fasteners, no mechanism, nothing that can come apart.

Hopper cavity: 88 mm wide (X); outlet slot 88 x 80 mm at Z = 72; top opening
88 x 135.8 mm at Z = 177; cavity height 105 mm. Front, left and right cavity walls
vertical, back wall 62 degrees from horizontal. **Measured cavity volume 997.1 cm3**
(0.997 L).

Feed path: seed leaves the 88 x 80 mm slot and falls 22 mm onto the tray floor at Z = 48.
The pile chokes the slot, so the bin holds until the bird eats down. Tray interior 88 mm
wide — the same as the slot, so nothing lands outside the pan — walls to Z = 65 finished
with a full-round 5 mm rolled lip whose crown is at Z = 70, i.e. 2 mm under the outlet
plane. Perch: 16 mm diameter, 82 mm long, axis at Y = -62, Z = 36 — 26 mm forward of the
tray's front lip, with open air above it. The tray withdraws in +Y on rails in the body's
skirt, so it comes out for cleaning **without opening the cage**.

Mount, and what each feature blocks:

- Two hooks, `bar_gap - 4` = 8 mm wide at X = +/-2.5 `bar_gap` = +/-30, pass through bar
  gaps above the opening and sit on the top rail. They carry the weight; their legs run
  20 mm down the inside face, blocking outward withdrawal.
- The front flange and shroud (X +/-68, Z 6..72) bear on the bars beside and below the
  opening, blocking inward motion, and close the door.
- Lift is blocked by the same legs: the body must rise 24 mm before it can move outward
  at all. Loaded it weighs about 1.2 kg.
- Refill is at the top of the bin, 180 mm above the sill and entirely outside the cage.
  Nothing about the lid is reachable from inside.

## (d) VERIFICATION

Every number below is the output of a command I ran. Where a check is weak or absent I
say so.

### Mesh validity

```
$ python3 check.py
body  watertight=True winding=True bodies=1 faces=672
tray  watertight=True winding=True bodies=1 faces=6348
lid   watertight=True winding=True bodies=1 faces=84
```

OpenSCAD's CGAL export check is clean for all three — no `manifold` warning on any
`openscad -D 'part="..."' -o ....stl hopper.scad`.

### Bounding box vs 175 mm

```
body 136.0 x 153.46 x 174.2
tray 104.8 x 170.00 x 42.0
lid  103.0 x 147.95 x 23.2
```

Largest single dimension anywhere: 174.2 mm (body Z), against a 175 mm limit. The door
shroud drove that; the design is now Z-limited and has 0.8 mm of headroom.

### Capacity vs 1 L

`verify/cavity.stl` is exported from the same source (`part="cavity"`) using the same
polygon the shell is built from, so it cannot drift from the shell.

```
$ python3 geo.py
capacity 997.1 cm3   cavity bbox 88.00 x 135.83 x 105.00
```

### Slot width vs 50 mm, wall angle vs 60 degrees

Measured from the cavity mesh's face normals, not from the parameters:

```
cavity min = [-44.00, 5.60, 72.00]    cavity max = [44.00, 141.43, 177.00]
normal [-1, 0, 0]            90.00 deg   7131 mm2   left wall
normal [ 1, 0, 0]            90.00 deg   7131 mm2   right wall
normal [ 0,-1, 0]            90.00 deg   4620 mm2   front wall
normal [ 0, 0.883, -0.469]   62.00 deg   5232 mm2   back / flow wall
normal [ 0, 0, +/-1]          0.00 deg              open top / outlet slot
```

Outlet: full cavity width 88 mm in X, 80 mm in Y. Minimum slot dimension 80 mm against
the required 50 mm. Every wall 62 degrees or steeper against a 60 degree floor. No
convergence in X anywhere: the cavity is 88 mm wide from the outlet to the lid.

### Wall thickness vs 2.4 mm

Method: sample 80 000 surface points, cast a ray inward along the reverse normal, take
the first hit. Exact for flat walls; it *undercounts* at convex edges and fillets, since a
sample on a corner measures across the corner. The useful output is where low samples
cluster, not the minimum.

```
$ python3 thin.py body 2.4  ->  196 / 80000  (0.25%), on the r 1.2 outlet-lip fillet
$ python3 thin.py tray 2.4  ->    0 / 80000
$ python3 thin.py lid  2.4  ->  155 / 80000, every sample exactly 2.00 mm
```

The tray is now clean at every one of 80 000 samples — the previous 410 were the square
edge left where the rolled rim was cut through its own axis; the rim cylinder now sits a
full radius below the crown, so the crown is genuinely round. The lid's 181 samples all
read exactly 2.00 mm: the height of the detent bead, a bump on a 3.2 mm skirt, not a wall.

Designed thicknesses, all above 2.4 mm: hopper front and back walls 3.2 mm, side walls
3.5 mm, flange and shroud 3.2 mm, tray floor 4.0 mm, tray walls 3.5 mm, lid top 3.2 mm,
lid skirt 3.2 mm, rails 4.5 mm minimum section.

Three earlier revisions failed this check and were fixed rather than excused: a 2.26 mm
back wall from a mis-placed profile vertex, 0.1-0.9 mm slivers around an inclined slot,
and the tray rim's square crown.

### Fit through 110 x 110 with 12 mm bars

The cage wall is a solid in the same source (`wall_solid()`). Each part is intersected
with it.

```
chk_wb (body x wall)  ->  45-byte STL, zero volume (contact only)
chk_wt (tray x wall)  ->  Current top level object is empty.
chk_wd (lid  x wall)  ->  Current top level object is empty.
```

### Door coverage — how much of the cage wall the assembly leaves open

221 x 221 ray grid fired along +Y through the 110 x 110 opening against body and tray
together; a cell counts as open if no part blocks it.

```
$ python3 door.py
clear-through area  1018 mm2 of 12100
regions: 4
  663 mm2   x -55.0..55.0   z  0.0.. 5.5   (sill strip, 5.5 mm tall)
  288 mm2   x -52.0..52.0   z 26.5..37.5   (band around the perch bar, 11.0 mm tall)
   67 mm2   x -52.0..52.0   z 65.5..70.5   (sliver over the tray rim, 5.0 mm tall)
    0 mm2   single grid cell
```

Before the shroud this was 3486 mm2 with a single 2290 mm2 region spanning the full
110 mm width — a hole a conure could put its head through. It is now 1018 mm2 in four
slivers. Note the caveat: the region boxes above are bounding boxes of connected sets, so
the "min-dim" of a ragged ring overstates its real width; the honest statement is that no
region is more than 11.5 mm across in its narrow direction, against a green-cheek's head
of roughly 25 mm.

### Part-to-part interference, assembled

```
$ python3 icheck.py
chk_bt (body x tray)  ->  empty
chk_bd (body x lid)   ->  vol = 0.0 mm3   (coincident contact faces only)
```

### Swept motion — the checks a static intersection cannot make

**Tray travel.** `intersection(translate([0,t,0]) tray(), body())`, t = 0 fitted, +t
withdraws:

```
t = -8  407.36 mm3    t = -0.5  50.92 mm3    t = 0.5 .. 175  clear, every sample
t = -4  407.36 mm3    t =  0     0.00 mm3
t = -2  203.68 mm3
```

The tray seats against a hard stop at t = 0 (0.00 mm3 is face-on-face contact), cannot be
pushed further in at all, and withdraws completely freely — clear at t = 0.5, 2, 6, 12,
30, 60, 100, 150 and 175 mm. `intersection(tray translated, wall_solid())` is empty at
every t, so it never touches a bar on the way out.

This replaced a sawtooth detent. The detent was wrong: its tooth stood in the channel for
the whole stroke, so the tray could be pulled out but not pushed back in, and the 0.4 mm
of "deflection" it asked for was a jam between a 4 mm floor and a rigid rail with no
compliant member anywhere. The stop is now geometric rather than elastic — the tray's
rear plate (X +/-52.4, Z 38..65) butts the ends of both rails at Y = 96. It blocks the one
direction a bird can push and is entirely absent from the direction a hand pulls.

**Body escape map.** `intersection(translate([0,u,t]) body(), wall_solid())`, u = outward
travel, t = lift, mm3, `.` = clear:

```
         u=2      u=4      u=6      u=8     u=12
t=0     14.3    131.7    185.9     68.5        .
t=6     14.3    131.7    185.9     68.5        .
t=12    14.3    131.7    185.9     68.5        .
t=18    13.8    125.4    184.1     64.5        .
t=21       .     20.7     32.9      5.1        .
t=22       .        .      0.0        .        .
t=24       .        .        .        .        .
```

The body is blocked at every outward position up to 21 mm of lift, marginal at 22, and
free at 24. (The u = 12 column is clear at every lift because 12 mm out the legs are past
the rail, but every path to it is blocked below t = 22.) That is the anti-dislodgement
argument, measured: a 60-80 g conure would have to lift about 1.2 kg by 22 mm while
pushing it outward, with nothing to grip but a smooth shroud.

### Printability

PrusaSlicer, 0.4 mm nozzle, 0.2 mm layers, 3 perimeters, 15% infill, 180 mm bed, support
threshold 45 degrees. Both arms of each row are sliced **in the same orientation**.

| part | rot X | no support | with support | support | time |
| --- | --- | --- | --- | --- | --- |
| **body** | **0** | 182.64 | 237.51 | **54.9 cm3** | 20 h 47 m |
| body | 180 | 182.62 | 242.44 | 59.8 cm3 | 21 h 14 m |
| body | 90 | 162.88 | 337.09 | 174.2 cm3 | 1 d 3 h |
| body | -90 | 162.82 | 334.95 | 172.1 cm3 | 1 d 6 h |
| **tray** | **0** | 71.10 | 93.37 | **22.3 cm3** | 8 h 39 m |
| tray | 180 | 71.06 | 93.34 | 22.3 cm3 | 8 h 29 m |
| tray | 90 | 83.95 | 136.47 | 52.5 cm3 | 11 h 35 m |
| tray | -90 | 83.89 | 136.28 | 52.4 cm3 | 11 h 29 m |
| lid | 0 | 51.37 | 55.07 | 3.7 cm3 | 5 h 23 m |
| **lid** | **180** | 50.99 | 52.43 | **1.4 cm3** | 5 h 24 m |
| lid | 90 | 64.87 | 67.32 | 2.4 cm3 | 6 h 22 m |
| lid | -90 | 64.79 | 82.56 | 17.8 cm3 | 6 h 59 m |

Chosen poses in bold: body upright on its flange foot, **tray upright on its own floor**,
lid inverted on its flat crown. The tray is a tie on support volume between upright and
inverted, so the tie-breaker is where the support scars land: upright they land on the
pan's underside, inverted the entire 13 000 mm2 food-contact pan floor becomes a
supported ceiling. An earlier revision chose the tray on end — a 42 mm part balanced on
its rolled rim — purely on support volume; that was a bad call and is corrected.

Total support 79.0 cm3 against 448 cm3 of part. **The body's 54.9 cm3, 30% of the part,
is the requirement I have not met, and it got worse over the last revision, not better.**
Chamfering and gusseting the rails took it from 48.5 to 41.4 cm3; then closing the door
and rounding the shroud aperture put it back to 54.9. That is a trade I made deliberately
— a hole in the cage wall is a safety defect, support material is a nuisance — but it is
a shortfall and I am not going to describe it as anything else. The support is on
mounting features (shroud aperture, rail undersides, hook throats), not on the seed path.

### Print orientation vs flow direction

The spec asks for layer lines along the flow. I do not meet it. The measured reason:

```
$ python3 -c "... rotate body.stl by -62 deg about X ..."
flow-wall-down bbox [136.0, 212.0, 156.7]
$ prusa-slicer ... verify/body_flowdown.stl
All objects are outside of the print volume.
```

Laying the 62 degree flow wall flat needs a 212 mm footprint, which does not fit a 180 mm
bed in any Z rotation. For a 1 L bin on this printer the orientation the requirement asks
for is geometrically unavailable; meeting it would need the bin reshaped or split, which
is a redesign rather than a re-pose. (I also confirmed PrusaSlicer's CLI `--rotate-x`
snaps to 90 degree multiples — `--rotate-x -62` and `--rotate-x -90` give byte-identical
output at 153.55 mm tall — so the oblique rows in an earlier draft of the table were not
the poses they were labelled; the check above rotates the mesh with trimesh instead.)

Printed inverted, layer lines run across the flow wall. Each layer's step on a 62 degree
wall is 0.2 / tan(62) = 0.106 mm horizontally per 0.226 mm of travel: a fine texture, not
a ledge. That is the trade, and it is a deviation from the spec.

### Not verified

- No structural analysis. Hooks, flange and shroud are sized by judgement. Loaded mass is
  roughly 0.57 kg of PETG plus about 0.6 kg of seed.
- No flow simulation. The claim that a 22 mm drop produces a pile that chokes an 80 mm
  slot rests on an assumed 32 degree angle of repose for a mix containing sticky slices,
  which I did not and cannot measure here. Freeboard is now 2 mm (rim crown 70, outlet
  plane 72) against 7 mm in the previous revision, but a pile that overtops the rim will
  still spill forward into the cage rather than choke.
- Parametricity is partial. `bar_gap` now drives the hook width and position
  (`hook_x = 2.5 bar_gap`, `hook_w = bar_gap - 4`), so re-declaring the pitch moves the
  hooks with it. The rail X positions, the shroud aperture and the tray widths are still
  literals tied to the 110 mm opening; changing `tray_wo` alone will drive the tray into
  the rails. There is no bar-phase offset parameter: the hooks assume a bar centred at
  X = 0.
- Bar pitch phase is therefore assumed. Hooks at X +/-30 sit in the gap between bars at 24
  and 36 with 0.75 mm per side. A real cage will differ.
- The cage's top and bottom rails around the opening are assumed to exist and to be 4 mm.
  The mount depends on the top rail.
- Rounded edges: done where the bird touches — the outlet lip (r 1.2), the shell's outer
  profile (r 1.2), the hook profile (r 1.4), the tray's now fully-round rolled rim (r 5),
  the perch and its posts (r 8 and r 3.5 hulls). The rails, the skirt and the shroud's
  aperture edges are still sharp prisms. The aperture edges are inside the bird's reach;
  that is an unfixed cosmetic-to-minor safety item, not a check I ran and passed.
- PETG food safety, layer-line hygiene and cleaning were not assessed.

## (e) Wall time

First command 2026-09-08 20:46:34 -07:00; last verification 2026-09-09 11:2x -07:00. The
session was suspended and resumed inside that window, so the elapsed clock overstates the
work: active time was roughly 5 hours across geometry, verification, three critic rounds and
three revisions.

## Clean room

No prior or parallel hopper design was read, listed, searched, fetched or opened. I did
not touch `~/repos/bddap-bot/3d-models`, the GitHub repo of that name, any sibling
directory under `~/scratch/hopper-critic/`, `~/.local/state/botq`,
`~/.local/state/bot-agent`, any transcript, or any memory or notes file. Everything under
OUT was created by this run. No incident to record.

## Critic loop

| round | score | issues addressed |
| --- | --- | --- |
| 1 | 3/10 | (1) tray un-removable — rear plate narrowed inboard of the rails, both rails run full length, outer stop rib replaced by a sawtooth; verified by sweeping the tray through its travel. (2, 4) latch had no assembly path and its slot inclined the wrong way — **latch deleted**, hook engagement 8 -> 20 mm, required lift measured. (3) perch unusable with 8 mm headroom — moved forward of the tray's lip on raked posts. (5) slicer table compared mismatched orientations — every row re-sliced as a matched pair. (6) support too high — rails chamfered and gusseted, latch deleted. (7) layer lines across the flow — tested the flow-wall-down pose properly: it needs a 212 mm bed, so it is unavailable; also found the CLI rotation flag snaps to 90 degree multiples. (8) sharp edges — hook profile and perch posts rounded. |
| 2 | 5/10 | (1) 2290 mm2 of door left open — **front shroud added** from Z 6 to the outlet, apertured for tray and perch only; clear area 3486 -> 1058 mm2, largest region now 5.5 mm tall; perch raised to Z 36 to clear it. (2) tray retention lifted over its own tooth — channel play cut 1.4 -> 0.4 mm against a 0.8 mm tooth. (3) tray print pose was a tower on a 320 mm2 footprint — switched to rot X 180, 3190 mm2 footprint, at the cost of 11 cm3 more support. (5) rim crown was a flat band with square edges — rim cylinder dropped a full radius below the crown; tray now has **zero** samples under 2.4 mm out of 80 000. (6) mount not parametric — hook width and position now derived from `bar_gap`; the remaining literals are named under "Not verified". (7) 7 mm of unconfined freeboard — tray rim raised from 65 to 70, 2 mm under the outlet, rear containment extended to y = 100. (4, 8) support and layer lines — not resolved; both are stated plainly above. |
| 3 | 5/10 | (1, 2) the sawtooth detent made the tray impossible to re-insert and jammed a 4 mm floor against a rigid rail for the whole stroke — **detent deleted**, replaced by a geometric stop: the tray's rear plate butts both rail ends at Y = 96, blocking push-in and leaving pull-out completely free (verified across the full 175 mm stroke). (4) tray print pose put support scars on the food-contact pan floor — switched to upright, which is a tie on support volume. (7) two flat ceilings driving support — the skirt-top ledge is now a 43 degree chamfer. (8) sharp shroud aperture — rounded to r 2. (3) lid detent needs 0.8 mm of skirt deflection with no lead-in, (5) the bin's proportions rule out the flow-wall-down pose, and (6) there is no shutoff when the tray is pulled — all three are real and all three are unfixed; they are stated in "Not verified" and "Known shortfalls" rather than closed. Round 3 was the last permitted round, so the score stands at 5/10. |

## Known shortfalls, stated plainly

Three things a reviewer named that I did not fix, listed so nobody has to discover them:

1. **No shutoff at the outlet.** Pulling the tray out for cleaning lets the bin empty onto
   the floor. A slide plate that closes the 88 x 80 slot as the tray leaves is the obvious
   answer and is not in this design.
2. **The lid detent is too stiff.** The bead and the rib meet square shoulder to square
   shoulder and need about 0.8 mm of outward deflection from a 3.2 mm skirt that is boxed
   on two edges, with no handle on the lid. It wants 45 degree lead-ins and relief slots
   beside the bead to make the skirt a real spring finger.
3. **The bin's proportions are chained to the door.** The cavity is 88 mm wide because the
   tray is, even though the bin hangs entirely outside the cage. A wider, shorter wedge of
   the same litre would fit the bed in the flow-wall-down pose and would also retire the
   0.8 mm of Z headroom this body has against the 175 mm limit. That is a redesign, not a
   revision, and it is the right next move.
