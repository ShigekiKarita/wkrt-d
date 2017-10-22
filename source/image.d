module image;

import std.format : format;
import numir;
import mir.ndslice;


/// text based image format
struct PPMImage {
    alias ElemType = double;
    alias DataType = Slice!(Universal, [3], ElemType*);
    alias PixelType = Slice!(cast(SliceKind)0, [1LU], double*);
    DataType data;
    const max = 255L;

    this(long width, long height, long max=255) {
        this.data = zeros!ElemType(width, height, 3).universal;
        this.max = max;
    }

    this(DataType data, long max=255) {
        assert(data.shape[2] == 3);
        this.data = data;
        this.max = max;
    }

    int opApply(int delegate(size_t, size_t, PixelType) dg) {
        int result = 0;
        foreach (j; 0 .. height) {
            foreach (i; 0 .. width) {
                result = dg(i, j, data[i, j, 0..$]);
                if (result) return result;
            }
        }
        return result;
    }

    @property
    auto height() pure { return data.shape[1]; }

    @property
    auto width() pure { return data.shape[0]; }

    @property
    auto content() {
        auto s = "P3\n%s %s\n%s\n".format(width, height,  max);
        // ~ "%(%(%(%s %)\n%)\n%)\n".format(data.reversed!0.transposed!(0, 1));
        auto rdata = data.reversed!1;
        foreach (i, j, pixel; this)
            s ~= "%(%s %)\n".format((255.99 * rdata[i, j]).as!long);
        return s;
    }

    auto save(string filename) {
        import std.file : fwrite = write;
        filename.fwrite(content);
    }
}

/// just writing example
unittest {
    auto img = PPMImage(200, 100);
    foreach (j; 0 .. img.height) {
        foreach (i; 0 .. img.width) {
            img.data[i, j, 0..$] = [cast(double) i / img.width, cast(double) j / img.height, 0.2].sliced;
        }
    }
    img.save("/tmp/test.ppm");
}
