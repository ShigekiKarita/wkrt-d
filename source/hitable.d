module hitable;

import vec;
import ray;

import std.numeric : dotProduct;


struct HitRecord {
    double scale;
    Vec point, normal;
}

auto initHitRecord() {
    return HitRecord(0.0, [0.0, 0.0, 0.0].vec3, [0.0, 0.0, 0.0].vec3);
}

interface Hitable {
    bool hit(Ray r, double scaleMin, double scaleMax, ref HitRecord rec) const pure;
}

class Sphere : Hitable {
    Vec center;
    double radius;

    this(Vec c, double r) pure @nogc {
        this.center = c;
        this.radius = r;
    }

    override bool hit(Ray r, double scaleMin, double scaleMax, ref HitRecord rec) const pure @nogc {
        auto oc = r.origin - this.center;
        const a = r.direction.squaredRadius;
        const b = 2.0 * dotProduct(oc, r.direction);
        const c = oc.squaredRadius - this.radius ^^ 2.0;
        const d = b ^^ 2.0 - 4.0 * a * c; // 二次方程式の解のルートの中身, 5章では b の定義が少し違う
        if (d > 0) {
            foreach (i; [-1, 1]) {
                const scale = (-b + i * d^^0.5) / (2.0 * a);
                if (scaleMin < scale && scale < scaleMax) {
                    rec.scale = scale;
                    rec.point[] = r.point(rec.scale);
                    rec.normal[] = (rec.point - this.center) / this.radius;
                    return true;
                }
            }
        }
        return false;
    }
}

class HitableList : Hitable {
    Hitable[] list;

    this(Hitable[] hs) { this.list = hs; }

    override bool hit(Ray r, double scaleMin, double scaleMax, ref HitRecord rec) const pure {
        auto tmprec = initHitRecord();
        bool hitAny = false;
        double closest = scaleMax;
        foreach (hitable; list) {
            if (hitable.hit(r, scaleMin, closest, tmprec)) {
                hitAny = true;
                closest = tmprec.scale;
                rec = tmprec;
            }
        }
        return hitAny;
    }
}
