class OpenSimplexNoise
  private STRETCH_CONSTANT_2D = -0.21132486540518708  # (1/Math.sqrt(2+1)-1)/2
  private SQUISH_CONSTANT_2D = 0.3660254037844386     # (Math.sqrt(2+1)-1)/2
  private STRETCH_CONSTANT_3D = -1.0 / 6              # (1/Math.sqrt(3+1)-1)/3
  private SQUISH_CONSTANT_3D = 1.0 / 3                # (Math.sqrt(3+1)-1)/3
  private STRETCH_CONSTANT_4D = -0.13819660112501053  # (1/Math.sqrt(4+1)-1)/4
  private SQUISH_CONSTANT_4D = 0.30901699437494745    # (Math.sqrt(4+1)-1)/4

  private NORM_CONSTANT_2D = 47
  private NORM_CONSTANT_3D = 103
  private NORM_CONSTANT_4D = 30

  private DEFAULT_SEED = 0_i64

  # Gradients for 2D. They approximate the directions to the
  # vertices of an octagon from the center.
  private GRADIENTS_2D = [
     5,  2,     2,  5,
    -5,  2,    -2,  5,
     5, -2,     2, -5,
    -5, -2,    -2, -5,
  ]

  # Gradients for 3D. They approximate the directions to the
  # vertices of a rhombicuboctahedron from the center, skewed so
  # that the triangular and square facets can be inscribed inside
  # circles of the same radius.
  private GRADIENTS_3D = [
    -11,  4,  4,    -4,  11,  4,   -4,  4,  11,
     11,  4,  4,     4,  11,  4,    4,  4,  11,
    -11, -4,  4,    -4, -11,  4,   -4, -4,  11,
     11, -4,  4,     4, -11,  4,    4, -4,  11,
    -11,  4, -4,    -4,  11, -4,   -4,  4, -11,
     11,  4, -4,     4,  11, -4,    4,  4, -11,
    -11, -4, -4,    -4, -11, -4,   -4, -4, -11,
     11, -4, -4,     4, -11, -4,    4, -4, -11,
  ]

  # Gradients for 4D. They approximate the directions to the
  # vertices of a disprismatotesseractihexadecachoron from the center,
  # skewed so that the tetrahedral and cubic facets can be inscribed inside
  # spheres of the same radius.
  private GRADIENTS_4D = [
      3,  1,  1,  1,     1,  3,  1,  1,     1,  1,  3,  1,     1,  1,  1,  3,
     -3,  1,  1,  1,    -1,  3,  1,  1,    -1,  1,  3,  1,    -1,  1,  1,  3,
      3, -1,  1,  1,     1, -3,  1,  1,     1, -1,  3,  1,     1, -1,  1,  3,
     -3, -1,  1,  1,    -1, -3,  1,  1,    -1, -1,  3,  1,    -1, -1,  1,  3,
      3,  1, -1,  1,     1,  3, -1,  1,     1,  1, -3,  1,     1,  1, -1,  3,
     -3,  1, -1,  1,    -1,  3, -1,  1,    -1,  1, -3,  1,    -1,  1, -1,  3,
      3, -1, -1,  1,     1, -3, -1,  1,     1, -1, -3,  1,     1, -1, -1,  3,
     -3, -1, -1,  1,    -1, -3, -1,  1,    -1, -1, -3,  1,    -1, -1, -1,  3,
      3,  1,  1, -1,     1,  3,  1, -1,     1,  1,  3, -1,     1,  1,  1, -3,
     -3,  1,  1, -1,    -1,  3,  1, -1,    -1,  1,  3, -1,    -1,  1,  1, -3,
      3, -1,  1, -1,     1, -3,  1, -1,     1, -1,  3, -1,     1, -1,  1, -3,
     -3, -1,  1, -1,    -1, -3,  1, -1,    -1, -1,  3, -1,    -1, -1,  1, -3,
      3,  1, -1, -1,     1,  3, -1, -1,     1,  1, -3, -1,     1,  1, -1, -3,
     -3,  1, -1, -1,    -1,  3, -1, -1,    -1,  1, -3, -1,    -1,  1, -1, -3,
      3, -1, -1, -1,     1, -3, -1, -1,     1, -1, -3, -1,     1, -1, -1, -3,
     -3, -1, -1, -1,    -1, -3, -1, -1,    -1, -1, -3, -1,    -1, -1, -1, -3,
  ]

  def initialize(seed : Int64 = DEFAULT_SEED)
    # Initiate the class and generate permutation arrays from a seed number.

    # Initializes the class using a permutation array generated from a 64-bit seed.
    # Generates a proper permutation (i.e. doesn't merely perform N
    # successive pair swaps on a base array)
    @perm = Array(Int32).new(256, 0)
    @perm_grad_index_3d = Array(Int32).new(256, 0)

    source = (0...256).to_a
    3.times { seed = seed * 6364136223846793005 + 1442695040888963407 }

    source.reverse.each do |i|
      seed = seed * 6364136223846793005 + 1442695040888963407
      r = (seed + 31) % (i + 1)
      r += i + 1 if r < 0
      @perm[i] = source[r]
      @perm_grad_index_3d[i] = (@perm[i] % (GRADIENTS_3D.size / 3)) * 3
      source[r] = source[i]
    end
  end

  private def extrapolate(xsb, ysb, dx, dy)
    index = @perm[(@perm[xsb & 0xFF] + ysb) & 0xFF] & 0x0E
    g1, g2 = GRADIENTS_2D[(index..index + 1)]
    g1 * dx + g2 * dy
  end

  private def extrapolate(xsb, ysb, zsb, dx, dy, dz)
    index = @perm_grad_index_3d[(@perm[(@perm[xsb & 0xFF] + ysb) & 0xFF] + zsb) & 0xFF]
    g1, g2, g3 = GRADIENTS_3D[(index..index + 2)]
    g1 * dx + g2 * dy + g3 * dz
  end

  private def extrapolate(xsb, ysb, zsb, wsb, dx, dy, dz, dw)
    index = @perm[(@perm[(@perm[(@perm[xsb & 0xFF] + ysb) & 0xFF] + zsb) & 0xFF] + wsb) & 0xFF] & 0xFC
    g1, g2, g3, g4 = GRADIENTS_4D[(index..index + 3)]
    g1 * dx + g2 * dy + g3 * dz + g4 * dw
  end

  def generate(x : Float64, y : Float64)
    # Generate 2D OpenSimplex noise from X,Y coordinates.

    # Place input coordinates onto grid.
    stretch_offset = (x + y) * STRETCH_CONSTANT_2D
    xs = x + stretch_offset
    ys = y + stretch_offset

    # Floor to get grid coordinates of rhombus (stretched square) super-cell origin.
    xsb = xs.floor.to_i
    ysb = ys.floor.to_i

    # Skew out to get actual coordinates of rhombus origin. We'll need these later.
    squish_offset = (xsb + ysb) * SQUISH_CONSTANT_2D
    xb = xsb + squish_offset
    yb = ysb + squish_offset

    # Compute grid coordinates relative to rhombus origin.
    xins = xs - xsb
    yins = ys - ysb

    # Sum those together to get a value that determines which region we're in.
    in_sum = xins + yins

    # Positions relative to origin point.
    dx0 = x - xb
    dy0 = y - yb

    value = 0

    # Contribution (1,0)
    dx1 = dx0 - 1 - SQUISH_CONSTANT_2D
    dy1 = dy0 - 0 - SQUISH_CONSTANT_2D
    attn1 = 2 - dx1 * dx1 - dy1 * dy1
    if attn1 > 0
      attn1 *= attn1
      value += attn1 * attn1 * extrapolate(xsb + 1, ysb + 0, dx1, dy1)
    end

    # Contribution (0,1)
    dx2 = dx0 - 0 - SQUISH_CONSTANT_2D
    dy2 = dy0 - 1 - SQUISH_CONSTANT_2D
    attn2 = 2 - dx2 * dx2 - dy2 * dy2
    if attn2 > 0
      attn2 *= attn2
      value += attn2 * attn2 * extrapolate(xsb + 0, ysb + 1, dx2, dy2)
    end

    if in_sum <= 1 # We're inside the triangle (2-Simplex) at (0,0)
      zins = 1 - in_sum
      if zins > xins || zins > yins # (0,0) is one of the closest two triangular vertices
        if xins > yins
          xsv_ext = xsb + 1
          ysv_ext = ysb - 1
          dx_ext = dx0 - 1
          dy_ext = dy0 + 1
        else
          xsv_ext = xsb - 1
          ysv_ext = ysb + 1
          dx_ext = dx0 + 1
          dy_ext = dy0 - 1
        end
      else # (1,0) and (0,1) are the closest two vertices.
        xsv_ext = xsb + 1
        ysv_ext = ysb + 1
        dx_ext = dx0 - 1 - 2 * SQUISH_CONSTANT_2D
        dy_ext = dy0 - 1 - 2 * SQUISH_CONSTANT_2D
      end
    else # We're inside the triangle (2-Simplex) at (1,1)
      zins = 2 - in_sum
      if zins < xins || zins < yins # (0,0) is one of the closest two triangular vertices
        if xins > yins
          xsv_ext = xsb + 2
          ysv_ext = ysb + 0
          dx_ext = dx0 - 2 - 2 * SQUISH_CONSTANT_2D
          dy_ext = dy0 + 0 - 2 * SQUISH_CONSTANT_2D
        else
          xsv_ext = xsb + 0
          ysv_ext = ysb + 2
          dx_ext = dx0 + 0 - 2 * SQUISH_CONSTANT_2D
          dy_ext = dy0 - 2 - 2 * SQUISH_CONSTANT_2D
        end
      else # (1,0) and (0,1) are the closest two vertices.
        dx_ext = dx0
        dy_ext = dy0
        xsv_ext = xsb
        ysv_ext = ysb
      end
      xsb += 1
      ysb += 1
      dx0 = dx0 - 1 - 2 * SQUISH_CONSTANT_2D
      dy0 = dy0 - 1 - 2 * SQUISH_CONSTANT_2D
    end

    # Contribution (0,0) or (1,1)
    attn0 = 2 - dx0 * dx0 - dy0 * dy0
    if attn0 > 0
      attn0 *= attn0
      value += attn0 * attn0 * extrapolate(xsb, ysb, dx0, dy0)
    end

    # Extra Vertex
    attn_ext = 2 - dx_ext * dx_ext - dy_ext * dy_ext
    if attn_ext > 0
      attn_ext *= attn_ext
      value += attn_ext * attn_ext * extrapolate(xsv_ext, ysv_ext, dx_ext, dy_ext)
    end

    value / NORM_CONSTANT_2D
  end
end
