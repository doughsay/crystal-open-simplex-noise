require "./open-simplex-noise/*"

class OpenSimplexNoise
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
end
