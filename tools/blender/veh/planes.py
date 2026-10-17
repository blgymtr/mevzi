# Nakliye uçağı modellerini üretir (roadmap 122): assets/models/plane_usa.glb (C-130 tipi), plane_rus.glb (Il-76 tipi)
# blender -b --factory-startup -P tools/blender/veh/planes.py -- <çıkış_klasörü>
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import vlib
import fam_plane

out = sys.argv[sys.argv.index("--") + 1:][0]
for nat, fam in (("usa", "plane_c130"), ("rus", "plane_il76")):
    vlib.reset(nat)
    pivots, meta = fam_plane.FAMILIES[fam]({})
    vlib.export(os.path.join(out, "plane_%s.glb" % nat), pivots, meta)
