module ray;

import vec;

struct Ray {
    Vec origin, direction;

    this(Vec origin, Vec direction) pure @nogc {
        enum s = [3LU];
        assert(origin.shape == s);
        assert(direction.shape == s);
        this.origin = origin;
        this.direction = direction;
    }

    auto point(double scale) pure @nogc {
        return origin + scale * direction;
    }
}

