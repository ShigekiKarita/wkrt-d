module material;

import numir;
import mir.ndslice;
import std.numeric : dotProduct;

import vec : Vec, randomSphereVec, reflect, unit;
import ray : Ray;
import hitable : HitRecord;

interface Material {
    bool scatter(Ray r, HitRecord rec, ref Vec attenuation, ref Ray scattered) const;
}


class Lambertian : Material {
    const Vec albedo;

    this(Vec a) pure @nogc { this.albedo = a; }

    override bool scatter(Ray r, HitRecord rec, ref Vec attenuation, ref Ray scattered) const {
        auto target = rec.normal + randomSphereVec();
        scattered = Ray(rec.point, target.slice);
        attenuation = albedo;
        return true;
    }
}


class Metal : Material {
    const Vec albedo;
    const double fuzz;
    this(Vec a, double fuzz=0.0) pure @nogc {
        assert(fuzz <= 1.0);
        this.albedo = a;
        this.fuzz = fuzz;
    }
    override bool scatter(Ray r, HitRecord rec, ref Vec attenuation, ref Ray scattered) const {
        auto target = reflect(r.direction.unit, rec.normal).slice;
        if (this.fuzz > 0.0) { target[] += this.fuzz * randomSphereVec(); }
        scattered = Ray(rec.point, target);
        attenuation = albedo;
        return dotProduct(scattered.direction, rec.normal) > 0.0;
    }
}
