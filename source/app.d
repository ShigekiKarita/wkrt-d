import std.stdio;
import std.format;

import image : PPMImage;
import vec;
import hitable;
import ray;

import numir;
import mir.ndslice;


enum Color {
    red = [1.0, 0.0, 0.0],
    white = [1.0, 1.0, 1.0],
    skyblue = [0.5, 0.7, 1.0]
}

struct Camera {
    Vec lowerLeft, horizontal, vertical, origin;

    auto ray(double u, double v) pure const {
        auto d = lowerLeft + u * horizontal + v * vertical - origin;
        return Ray(origin, d.slice);
    }
}



Vec color(Ray r, Hitable world, double minEps=1e-3) {
    auto rec = initHitRecord();
    if (world.hit(r, minEps, double.max, rec)) {
        auto target = rec.normal + randomSphereVec();
        return (0.5 * color(Ray(rec.point, target.slice), world)).slice;
    }
    auto scale = 0.5 * (r.direction.unit.y + 1.0);
    auto rgb = (1.0 - scale) * Color.white.vec3 + scale * Color.skyblue.vec3;
    return rgb.slice;
}


void main()
{
    const Camera camera = {
        lowerLeft: [-2.0, -1.0, -1.0].vec3,
        horizontal: [4.0, 0.0, 0.0].vec3,
        vertical: [0.0, 2.0, 0.0].vec3,
        origin: [0.0, 0.0, 0.0].vec3
    };

    auto img = PPMImage(400, 200);
    auto nalias = 100;

    auto lowerLeft = [-2.0, -1.0, -1.0].vec3;
    auto horizontal = [4.0, 0.0, 0.0].vec3;
    auto vertical = [0.0, 2.0, 0.0].vec3;
    auto origin = [0.0, 0.0, 0.0].vec3;

    Hitable[] list = [
        new Sphere([0.0, 0.0, -1.0].vec3, 0.5),
        new Sphere([0.0, -100.5, -1.0].vec3, 100)
        ];
    Hitable world= new HitableList(list);
    foreach (i, j, pixel; img) {
        auto col = [0.0, 0.0, 0.0].vec3;
        auto us = uniform(nalias, 2);
        foreach (n; 0 .. nalias) {
            auto u = (cast(double) i + us[n, 0]) / img.width;
            auto v = (cast(double) j + us[n, 1]) / img.height;
            auto r = camera.ray(u, v);
            col[] += color(r, world);
        }
        pixel[] = (col / nalias) ^^ 0.5;
    }
    img.save("3.ppm");
}
