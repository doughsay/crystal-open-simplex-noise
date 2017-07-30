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
end
