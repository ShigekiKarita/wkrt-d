module vec;

import numir;
import mir.ndslice;


alias Vec = Slice!(Contiguous, [1], double*);

enum isVec(V) = packsOf!V == [1LU];

auto x(V)(V v) pure @nogc if (isVec!V) { return v[0]; }
auto y(V)(V v) pure @nogc if (isVec!V) { return v[1]; }
auto z(V)(V v) pure @nogc if (isVec!V) { return v[2]; }

auto vec3(double[] xyz) pure @nogc {
    return xyz.sliced;
}

auto squaredRadius(V)(V v) pure @nogc if (isVec!V) {
    import mir.math : sum;
    enum a = [3LU];
    assert(v.shape == a);
    return sum!"fast"(v ^^ 2.0);
}

auto radius(V)(V v) pure @nogc if (isVec!V) {
    return v.squaredRadius ^^ 0.5;
}

auto unit(V)(V v) pure @nogc if (isVec!V) {
    return v / v.radius;
}

unittest {
    import std.math : approxEqual;
    Vec v = vec3([0.0, 4.0, 3.0]);
    assert(approxEqual(v.radius, 5.0));
    assert(approxEqual(v.unit, [0.0, 4.0/5.0, 3.0/5.0]));
}