import std.stdio;
import std.format;
import std.numeric : dotProduct;

import image : PPMImage;
import vec;

import numir;
import mir.ndslice;


enum Color {
    red = [1.0, 0.0, 0.0],
    white = [1.0, 1.0, 1.0],
    skyblue = [0.5, 0.7, 1.0]
}

struct Ray {
    Vec origin, direction;

    this(Vec origin, Vec direction) {
        assert(origin.shape == [3]);
        assert(direction.shape == [3]);
        this.origin = origin;
        this.direction = direction;
    }

    auto point(double scale) pure @nogc {
        return origin + scale * direction;
    }

    // auto hitSphere(Vec center, double radius) pure @nogc {
    //     auto oc = origin - center;
    //     auto a = direction.squaredRadius;
    //     auto b = 2.0 * dotProduct(oc, direction);
    //     auto c = oc.squaredRadius - radius ^^ 2.0;
    //     auto d = b ^^ 2.0 - 4.0 * a * c; // 二次方程式の解のルートの中身
    //     return d < 0 ? -1.0 : (-b - d ^^ 0.5) / (2.0 * a);
    // }

    // auto color() pure {
    //     auto center = [0.0, 0.0, -1.0].vec3;
    //     auto s = hitSphere(center, 0.5);
    //     if (s > 0.0) {
    //         auto r = 0.5 * (this.point(s).unit - center + 1.0);
    //         return r.slice;
    //     }
    //     auto t = 0.5 * (direction.unit.y + 1.0);
    //     auto r = (1.0 - t) * Color.white.vec3 + t * Color.skyblue.vec3;
    //     return r.slice;
    // }
}

// auto color(V)(V direction) pure @nogc if (isVec!V) {
//     double t = 0.5 * (direction.unit.y + 1.0);
//     return (1.0 - t) * vec3([1, 1, 1]) + t * vec3([0.5, 0.7, 1.0]);
// }

struct HitRecord {
    double scale;
    Vec point, normal;
}

interface Hitable {
    bool hit(Ray r, double scaleMin, double scaleMax, ref HitRecord rec) const;
}

class Sphere : Hitable {
    Vec center;
    double radius;

    this(Vec c, double r) {
        this.center = c;
        this.radius = r;
    }

    override bool hit(Ray r, double scaleMin, double scaleMax, ref HitRecord rec) const {
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

    override bool hit(Ray r, double scaleMin, double scaleMax, ref HitRecord rec) const {
        auto tmprec = HitRecord(0.0, [0.0, 0.0, 0.0].vec3, [0.0, 0.0, 0.0].vec3);
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


struct Camera {
    Vec lowerLeft, horizontal, vertical, origin;

    auto ray(double u, double v) {
        auto d = lowerLeft + u * horizontal + v * vertical - origin;
        return Ray(origin, d.slice);
    }
}



auto color(Ray r, Hitable world) {
    HitRecord rec;
    if (world.hit(r, 0.0, double.max, rec)) {
        auto rgb = 0.5 * (rec.normal + 1.0);
        return rgb.slice;
    }
    auto scale = 0.5 * (r.direction.unit.y + 1.0);
    auto rgb = (1.0 - scale) * Color.white.vec3 + scale * Color.skyblue.vec3;
    return rgb.slice;
}


void main()
{
    Camera camera = {
        lowerLeft: [-2.0, -1.0, -1.0].vec3,
        horizontal: [4.0, 0.0, 0.0].vec3,
        vertical: [0.0, 2.0, 0.0].vec3,
        origin: [0.0, 0.0, 0.0].vec3
    };

    auto img = PPMImage(200, 100);
    auto lowerLeft = [-2.0, -1.0, -1.0].vec3;
    auto horizontal = [4.0, 0.0, 0.0].vec3;
    auto vertical = [0.0, 2.0, 0.0].vec3;
    auto origin = [0.0, 0.0, 0.0].vec3;

    Hitable[] list = [new Sphere([0.0, 0.0, -1.0].vec3, 0.5),
                      new Sphere([0.0, -100.5, -1.0].vec3, 100)];
    Hitable world= new HitableList(list);

    auto ns = 100;
    foreach (i, j, pixel; img) {
        auto col = [0.0, 0.0, 0.0].vec3;
        auto us = uniform(ns, 2);
        foreach (n; 0 .. ns) {
            auto u = (cast(double) i + us[n, 0]) / img.width;
            auto v = (cast(double) j + us[n, 1]) / img.height;
            auto r = camera.ray(u, v);
            col[] += color(r, world);
        }
        pixel[] = col / ns;
        // auto u = cast(double) i / img.width;
        // auto v = cast(double) j / img.height;
        // auto d = lowerLeft + u * horizontal + v * vertical;
        // auto ray = Ray(origin, d.slice);
        // pixel[] = color(ray, world);
    }
    img.save("3.ppm");
}
