class OpenSimplexNoise
  private def extrapolate(xsb : Int32, ysb : Int32, zsb : Int32, dx : Float64, dy : Float64, dz : Float64)
    index = @perm_grad_index_3d[(@perm[(@perm[xsb & 0xFF] + ysb) & 0xFF] + zsb) & 0xFF]
    g1, g2, g3 = GRADIENTS_3D[(index..index + 2)]
    g1 * dx + g2 * dy + g3 * dz
  end

  def generate(x : Float64, y : Float64, z : Float64)
    # Generate 3D OpenSimplex noise from X,Y,Z coordinates.

    # Place input coordinates on simplectic honeycomb.
    stretch_offset = (x + y + z) * STRETCH_CONSTANT_3D
    xs = x + stretch_offset
    ys = y + stretch_offset
    zs = z + stretch_offset

    # Floor to get simplectic honeycomb coordinates of rhombohedron (stretched cube) super-cell origin.
    xsb = xs.floor.to_i
    ysb = ys.floor.to_i
    zsb = zs.floor.to_i

    # Skew out to get actual coordinates of rhombohedron origin. We'll need these later.
    squish_offset = (xsb + ysb + zsb) * SQUISH_CONSTANT_3D
    xb = xsb + squish_offset
    yb = ysb + squish_offset
    zb = zsb + squish_offset

    # Compute simplectic honeycomb coordinates relative to rhombohedral origin.
    xins = xs - xsb
    yins = ys - ysb
    zins = zs - zsb

    # Sum those together to get a value that determines which region we're in.
    in_sum = xins + yins + zins

    # Positions relative to origin point.
    dx0 = x - xb
    dy0 = y - yb
    dz0 = z - zb

    value = 0
    if in_sum <= 1 # We're inside the tetrahedron (3-Simplex) at (0,0,0)

      # Determine which two of (0,0,1), (0,1,0), (1,0,0) are closest.
      a_point = 0x01
      a_score = xins
      b_point = 0x02
      b_score = yins
      if a_score >= b_score && zins > b_score
        b_score = zins
        b_point = 0x04
      elsif a_score < b_score && zins > a_score
        a_score = zins
        a_point = 0x04
      end

      # Now we determine the two lattice points not part of the tetrahedron that may contribute.
      # This depends on the closest two tetrahedral vertices, including (0,0,0)
      wins = 1 - in_sum
      if wins > a_score || wins > b_score # (0,0,0) is one of the closest two tetrahedral vertices.
        c = b_score > a_score ? b_point : a_point # Our other closest vertex is the closest out of a and b.

        if (c & 0x01) == 0
          xsv_ext0 = xsb - 1
          xsv_ext1 = xsb
          dx_ext0 = dx0 + 1
          dx_ext1 = dx0
        else
          xsv_ext0 = xsv_ext1 = xsb + 1
          dx_ext0 = dx_ext1 = dx0 - 1
        end

        if (c & 0x02) == 0
          ysv_ext0 = ysv_ext1 = ysb
          dy_ext0 = dy_ext1 = dy0
          if (c & 0x01) == 0
            ysv_ext1 -= 1
            dy_ext1 += 1
          else
            ysv_ext0 -= 1
            dy_ext0 += 1
          end
        else
          ysv_ext0 = ysv_ext1 = ysb + 1
          dy_ext0 = dy_ext1 = dy0 - 1
        end

        if (c & 0x04) == 0
          zsv_ext0 = zsb
          zsv_ext1 = zsb - 1
          dz_ext0 = dz0
          dz_ext1 = dz0 + 1
        else
          zsv_ext0 = zsv_ext1 = zsb + 1
          dz_ext0 = dz_ext1 = dz0 - 1
        end
      else # (0,0,0) is not one of the closest two tetrahedral vertices.
        c = (a_point | b_point) # Our two extra vertices are determined by the closest two.

        if (c & 0x01) == 0
          xsv_ext0 = xsb
          xsv_ext1 = xsb - 1
          dx_ext0 = dx0 - 2 * SQUISH_CONSTANT_3D
          dx_ext1 = dx0 + 1 - SQUISH_CONSTANT_3D
        else
          xsv_ext0 = xsv_ext1 = xsb + 1
          dx_ext0 = dx0 - 1 - 2 * SQUISH_CONSTANT_3D
          dx_ext1 = dx0 - 1 - SQUISH_CONSTANT_3D
        end

        if (c & 0x02) == 0
          ysv_ext0 = ysb
          ysv_ext1 = ysb - 1
          dy_ext0 = dy0 - 2 * SQUISH_CONSTANT_3D
          dy_ext1 = dy0 + 1 - SQUISH_CONSTANT_3D
        else
          ysv_ext0 = ysv_ext1 = ysb + 1
          dy_ext0 = dy0 - 1 - 2 * SQUISH_CONSTANT_3D
          dy_ext1 = dy0 - 1 - SQUISH_CONSTANT_3D
        end

        if (c & 0x04) == 0
          zsv_ext0 = zsb
          zsv_ext1 = zsb - 1
          dz_ext0 = dz0 - 2 * SQUISH_CONSTANT_3D
          dz_ext1 = dz0 + 1 - SQUISH_CONSTANT_3D
        else
          zsv_ext0 = zsv_ext1 = zsb + 1
          dz_ext0 = dz0 - 1 - 2 * SQUISH_CONSTANT_3D
          dz_ext1 = dz0 - 1 - SQUISH_CONSTANT_3D
        end
      end

      # Contribution (0,0,0)
      attn0 = 2 - dx0 * dx0 - dy0 * dy0 - dz0 * dz0
      if attn0 > 0
        attn0 *= attn0
        value += attn0 * attn0 * extrapolate(xsb + 0, ysb + 0, zsb + 0, dx0, dy0, dz0)
      end

      # Contribution (1,0,0)
      dx1 = dx0 - 1 - SQUISH_CONSTANT_3D
      dy1 = dy0 - 0 - SQUISH_CONSTANT_3D
      dz1 = dz0 - 0 - SQUISH_CONSTANT_3D
      attn1 = 2 - dx1 * dx1 - dy1 * dy1 - dz1 * dz1
      if attn1 > 0
        attn1 *= attn1
        value += attn1 * attn1 * extrapolate(xsb + 1, ysb + 0, zsb + 0, dx1, dy1, dz1)
      end

      # Contribution (0,1,0)
      dx2 = dx0 - 0 - SQUISH_CONSTANT_3D
      dy2 = dy0 - 1 - SQUISH_CONSTANT_3D
      dz2 = dz1
      attn2 = 2 - dx2 * dx2 - dy2 * dy2 - dz2 * dz2
      if attn2 > 0
        attn2 *= attn2
        value += attn2 * attn2 * extrapolate(xsb + 0, ysb + 1, zsb + 0, dx2, dy2, dz2)
      end

      # Contribution (0,0,1)
      dx3 = dx2
      dy3 = dy1
      dz3 = dz0 - 1 - SQUISH_CONSTANT_3D
      attn3 = 2 - dx3 * dx3 - dy3 * dy3 - dz3 * dz3
      if attn3 > 0
        attn3 *= attn3
        value += attn3 * attn3 * extrapolate(xsb + 0, ysb + 0, zsb + 1, dx3, dy3, dz3)
      end
    elsif in_sum >= 2 # We're inside the tetrahedron (3-Simplex) at (1,1,1)

      # Determine which two tetrahedral vertices are the closest, out of (1,1,0), (1,0,1), (0,1,1) but not (1,1,1).
      a_point = 0x06
      a_score = xins
      b_point = 0x05
      b_score = yins
      if a_score <= b_score && zins < b_score
        b_score = zins
        b_point = 0x03
      elsif a_score > b_score && zins < a_score
        a_score = zins
        a_point = 0x03
      end

      # Now we determine the two lattice points not part of the tetrahedron that may contribute.
      # This depends on the closest two tetrahedral vertices, including (1,1,1)
      wins = 3 - in_sum
      if wins < a_score || wins < b_score # (1,1,1) is one of the closest two tetrahedral vertices.
        c = b_score < a_score ? b_point : a_point # Our other closest vertex is the closest out of a and b.

        if (c & 0x01) != 0
          xsv_ext0 = xsb + 2
          xsv_ext1 = xsb + 1
          dx_ext0 = dx0 - 2 - 3 * SQUISH_CONSTANT_3D
          dx_ext1 = dx0 - 1 - 3 * SQUISH_CONSTANT_3D
        else
          xsv_ext0 = xsv_ext1 = xsb
          dx_ext0 = dx_ext1 = dx0 - 3 * SQUISH_CONSTANT_3D
        end

        if (c & 0x02) != 0
          ysv_ext0 = ysv_ext1 = ysb + 1
          dy_ext0 = dy_ext1 = dy0 - 1 - 3 * SQUISH_CONSTANT_3D
          if (c & 0x01) != 0
            ysv_ext1 += 1
            dy_ext1 -= 1
          else
            ysv_ext0 += 1
            dy_ext0 -= 1
          end
        else
          ysv_ext0 = ysv_ext1 = ysb
          dy_ext0 = dy_ext1 = dy0 - 3 * SQUISH_CONSTANT_3D
        end

        if (c & 0x04) != 0
          zsv_ext0 = zsb + 1
          zsv_ext1 = zsb + 2
          dz_ext0 = dz0 - 1 - 3 * SQUISH_CONSTANT_3D
          dz_ext1 = dz0 - 2 - 3 * SQUISH_CONSTANT_3D
        else
          zsv_ext0 = zsv_ext1 = zsb
          dz_ext0 = dz_ext1 = dz0 - 3 * SQUISH_CONSTANT_3D
        end
      else # (1,1,1) is not one of the closest two tetrahedral vertices.
        c = (a_point & b_point) # Our two extra vertices are determined by the closest two.

        if (c & 0x01) != 0
          xsv_ext0 = xsb + 1
          xsv_ext1 = xsb + 2
          dx_ext0 = dx0 - 1 - SQUISH_CONSTANT_3D
          dx_ext1 = dx0 - 2 - 2 * SQUISH_CONSTANT_3D
        else
          xsv_ext0 = xsv_ext1 = xsb
          dx_ext0 = dx0 - SQUISH_CONSTANT_3D
          dx_ext1 = dx0 - 2 * SQUISH_CONSTANT_3D
        end

        if (c & 0x02) != 0
          ysv_ext0 = ysb + 1
          ysv_ext1 = ysb + 2
          dy_ext0 = dy0 - 1 - SQUISH_CONSTANT_3D
          dy_ext1 = dy0 - 2 - 2 * SQUISH_CONSTANT_3D
        else
          ysv_ext0 = ysv_ext1 = ysb
          dy_ext0 = dy0 - SQUISH_CONSTANT_3D
          dy_ext1 = dy0 - 2 * SQUISH_CONSTANT_3D
        end

        if (c & 0x04) != 0
          zsv_ext0 = zsb + 1
          zsv_ext1 = zsb + 2
          dz_ext0 = dz0 - 1 - SQUISH_CONSTANT_3D
          dz_ext1 = dz0 - 2 - 2 * SQUISH_CONSTANT_3D
        else
          zsv_ext0 = zsv_ext1 = zsb
          dz_ext0 = dz0 - SQUISH_CONSTANT_3D
          dz_ext1 = dz0 - 2 * SQUISH_CONSTANT_3D
        end
      end

      # Contribution (1,1,0)
      dx3 = dx0 - 1 - 2 * SQUISH_CONSTANT_3D
      dy3 = dy0 - 1 - 2 * SQUISH_CONSTANT_3D
      dz3 = dz0 - 0 - 2 * SQUISH_CONSTANT_3D
      attn3 = 2 - dx3 * dx3 - dy3 * dy3 - dz3 * dz3
      if attn3 > 0
        attn3 *= attn3
        value += attn3 * attn3 * extrapolate(xsb + 1, ysb + 1, zsb + 0, dx3, dy3, dz3)
      end

      # Contribution (1,0,1)
      dx2 = dx3
      dy2 = dy0 - 0 - 2 * SQUISH_CONSTANT_3D
      dz2 = dz0 - 1 - 2 * SQUISH_CONSTANT_3D
      attn2 = 2 - dx2 * dx2 - dy2 * dy2 - dz2 * dz2
      if attn2 > 0
        attn2 *= attn2
        value += attn2 * attn2 * extrapolate(xsb + 1, ysb + 0, zsb + 1, dx2, dy2, dz2)
      end

      # Contribution (0,1,1)
      dx1 = dx0 - 0 - 2 * SQUISH_CONSTANT_3D
      dy1 = dy3
      dz1 = dz2
      attn1 = 2 - dx1 * dx1 - dy1 * dy1 - dz1 * dz1
      if attn1 > 0
        attn1 *= attn1
        value += attn1 * attn1 * extrapolate(xsb + 0, ysb + 1, zsb + 1, dx1, dy1, dz1)
      end

      # Contribution (1,1,1)
      dx0 = dx0 - 1 - 3 * SQUISH_CONSTANT_3D
      dy0 = dy0 - 1 - 3 * SQUISH_CONSTANT_3D
      dz0 = dz0 - 1 - 3 * SQUISH_CONSTANT_3D
      attn0 = 2 - dx0 * dx0 - dy0 * dy0 - dz0 * dz0
      if attn0 > 0
        attn0 *= attn0
        value += attn0 * attn0 * extrapolate(xsb + 1, ysb + 1, zsb + 1, dx0, dy0, dz0)
      end
    else # We're inside the octahedron (Rectified 3-Simplex) in between.
      # Decide between point (0,0,1) and (1,1,0) as closest
      p1 = xins + yins
      if p1 > 1
        a_score = p1 - 1
        a_point = 0x03
        a_is_further_side = true
      else
        a_score = 1 - p1
        a_point = 0x04
        a_is_further_side = false
      end

      # Decide between point (0,1,0) and (1,0,1) as closest
      p2 = xins + zins
      if p2 > 1
        b_score = p2 - 1
        b_point = 0x05
        b_is_further_side = true
      else
        b_score = 1 - p2
        b_point = 0x02
        b_is_further_side = false
      end

      # The closest out of the two (1,0,0) and (0,1,1) will replace the furthest out of the two decided above, if closer.
      p3 = yins + zins
      if p3 > 1
        score = p3 - 1
        if a_score <= b_score && a_score < score
          a_point = 0x06
          a_is_further_side = true
        elsif a_score > b_score && b_score < score
          b_point = 0x06
          b_is_further_side = true
        end
      else
        score = 1 - p3
        if a_score <= b_score && a_score < score
          a_point = 0x01
          a_is_further_side = false
        elsif a_score > b_score && b_score < score
          b_point = 0x01
          b_is_further_side = false
        end
      end

      # Where each of the two closest points are determines how the extra two vertices are calculated.
      if a_is_further_side == b_is_further_side
        if a_is_further_side # Both closest points on (1,1,1) side

          # One of the two extra points is (1,1,1)
          dx_ext0 = dx0 - 1 - 3 * SQUISH_CONSTANT_3D
          dy_ext0 = dy0 - 1 - 3 * SQUISH_CONSTANT_3D
          dz_ext0 = dz0 - 1 - 3 * SQUISH_CONSTANT_3D
          xsv_ext0 = xsb + 1
          ysv_ext0 = ysb + 1
          zsv_ext0 = zsb + 1

          # Other extra point is based on the shared axis.
          c = (a_point & b_point)
          if (c & 0x01) != 0
            dx_ext1 = dx0 - 2 - 2 * SQUISH_CONSTANT_3D
            dy_ext1 = dy0 - 2 * SQUISH_CONSTANT_3D
            dz_ext1 = dz0 - 2 * SQUISH_CONSTANT_3D
            xsv_ext1 = xsb + 2
            ysv_ext1 = ysb
            zsv_ext1 = zsb
          elsif (c & 0x02) != 0
            dx_ext1 = dx0 - 2 * SQUISH_CONSTANT_3D
            dy_ext1 = dy0 - 2 - 2 * SQUISH_CONSTANT_3D
            dz_ext1 = dz0 - 2 * SQUISH_CONSTANT_3D
            xsv_ext1 = xsb
            ysv_ext1 = ysb + 2
            zsv_ext1 = zsb
          else
            dx_ext1 = dx0 - 2 * SQUISH_CONSTANT_3D
            dy_ext1 = dy0 - 2 * SQUISH_CONSTANT_3D
            dz_ext1 = dz0 - 2 - 2 * SQUISH_CONSTANT_3D
            xsv_ext1 = xsb
            ysv_ext1 = ysb
            zsv_ext1 = zsb + 2
          end
        else # Both closest points on (0,0,0) side

          # One of the two extra points is (0,0,0)
          dx_ext0 = dx0
          dy_ext0 = dy0
          dz_ext0 = dz0
          xsv_ext0 = xsb
          ysv_ext0 = ysb
          zsv_ext0 = zsb

          # Other extra point is based on the omitted axis.
          c = (a_point | b_point)
          if (c & 0x01) == 0
            dx_ext1 = dx0 + 1 - SQUISH_CONSTANT_3D
            dy_ext1 = dy0 - 1 - SQUISH_CONSTANT_3D
            dz_ext1 = dz0 - 1 - SQUISH_CONSTANT_3D
            xsv_ext1 = xsb - 1
            ysv_ext1 = ysb + 1
            zsv_ext1 = zsb + 1
          elsif (c & 0x02) == 0
            dx_ext1 = dx0 - 1 - SQUISH_CONSTANT_3D
            dy_ext1 = dy0 + 1 - SQUISH_CONSTANT_3D
            dz_ext1 = dz0 - 1 - SQUISH_CONSTANT_3D
            xsv_ext1 = xsb + 1
            ysv_ext1 = ysb - 1
            zsv_ext1 = zsb + 1
          else
            dx_ext1 = dx0 - 1 - SQUISH_CONSTANT_3D
            dy_ext1 = dy0 - 1 - SQUISH_CONSTANT_3D
            dz_ext1 = dz0 + 1 - SQUISH_CONSTANT_3D
            xsv_ext1 = xsb + 1
            ysv_ext1 = ysb + 1
            zsv_ext1 = zsb - 1
          end
        end
      else # One point on (0,0,0) side, one point on (1,1,1) side
        if a_is_further_side
          c1 = a_point
          c2 = b_point
        else
          c1 = b_point
          c2 = a_point
        end

        # One contribution is a _permutation of (1,1,-1)
        if (c1 & 0x01) == 0
          dx_ext0 = dx0 + 1 - SQUISH_CONSTANT_3D
          dy_ext0 = dy0 - 1 - SQUISH_CONSTANT_3D
          dz_ext0 = dz0 - 1 - SQUISH_CONSTANT_3D
          xsv_ext0 = xsb - 1
          ysv_ext0 = ysb + 1
          zsv_ext0 = zsb + 1
        elsif (c1 & 0x02) == 0
          dx_ext0 = dx0 - 1 - SQUISH_CONSTANT_3D
          dy_ext0 = dy0 + 1 - SQUISH_CONSTANT_3D
          dz_ext0 = dz0 - 1 - SQUISH_CONSTANT_3D
          xsv_ext0 = xsb + 1
          ysv_ext0 = ysb - 1
          zsv_ext0 = zsb + 1
        else
          dx_ext0 = dx0 - 1 - SQUISH_CONSTANT_3D
          dy_ext0 = dy0 - 1 - SQUISH_CONSTANT_3D
          dz_ext0 = dz0 + 1 - SQUISH_CONSTANT_3D
          xsv_ext0 = xsb + 1
          ysv_ext0 = ysb + 1
          zsv_ext0 = zsb - 1
        end

        # One contribution is a _permutation of (0,0,2)
        dx_ext1 = dx0 - 2 * SQUISH_CONSTANT_3D
        dy_ext1 = dy0 - 2 * SQUISH_CONSTANT_3D
        dz_ext1 = dz0 - 2 * SQUISH_CONSTANT_3D
        xsv_ext1 = xsb
        ysv_ext1 = ysb
        zsv_ext1 = zsb
        if (c2 & 0x01) != 0
          dx_ext1 -= 2
          xsv_ext1 += 2
        elsif (c2 & 0x02) != 0
          dy_ext1 -= 2
          ysv_ext1 += 2
        else
          dz_ext1 -= 2
          zsv_ext1 += 2
        end
      end

      # Contribution (1,0,0)
      dx1 = dx0 - 1 - SQUISH_CONSTANT_3D
      dy1 = dy0 - 0 - SQUISH_CONSTANT_3D
      dz1 = dz0 - 0 - SQUISH_CONSTANT_3D
      attn1 = 2 - dx1 * dx1 - dy1 * dy1 - dz1 * dz1
      if attn1 > 0
        attn1 *= attn1
        value += attn1 * attn1 * extrapolate(xsb + 1, ysb + 0, zsb + 0, dx1, dy1, dz1)
      end

      # Contribution (0,1,0)
      dx2 = dx0 - 0 - SQUISH_CONSTANT_3D
      dy2 = dy0 - 1 - SQUISH_CONSTANT_3D
      dz2 = dz1
      attn2 = 2 - dx2 * dx2 - dy2 * dy2 - dz2 * dz2
      if attn2 > 0
        attn2 *= attn2
        value += attn2 * attn2 * extrapolate(xsb + 0, ysb + 1, zsb + 0, dx2, dy2, dz2)
      end

      # Contribution (0,0,1)
      dx3 = dx2
      dy3 = dy1
      dz3 = dz0 - 1 - SQUISH_CONSTANT_3D
      attn3 = 2 - dx3 * dx3 - dy3 * dy3 - dz3 * dz3
      if attn3 > 0
        attn3 *= attn3
        value += attn3 * attn3 * extrapolate(xsb + 0, ysb + 0, zsb + 1, dx3, dy3, dz3)
      end

      # Contribution (1,1,0)
      dx4 = dx0 - 1 - 2 * SQUISH_CONSTANT_3D
      dy4 = dy0 - 1 - 2 * SQUISH_CONSTANT_3D
      dz4 = dz0 - 0 - 2 * SQUISH_CONSTANT_3D
      attn4 = 2 - dx4 * dx4 - dy4 * dy4 - dz4 * dz4
      if attn4 > 0
        attn4 *= attn4
        value += attn4 * attn4 * extrapolate(xsb + 1, ysb + 1, zsb + 0, dx4, dy4, dz4)
      end

      # Contribution (1,0,1)
      dx5 = dx4
      dy5 = dy0 - 0 - 2 * SQUISH_CONSTANT_3D
      dz5 = dz0 - 1 - 2 * SQUISH_CONSTANT_3D
      attn5 = 2 - dx5 * dx5 - dy5 * dy5 - dz5 * dz5
      if attn5 > 0
        attn5 *= attn5
        value += attn5 * attn5 * extrapolate(xsb + 1, ysb + 0, zsb + 1, dx5, dy5, dz5)
      end

      # Contribution (0,1,1)
      dx6 = dx0 - 0 - 2 * SQUISH_CONSTANT_3D
      dy6 = dy4
      dz6 = dz5
      attn6 = 2 - dx6 * dx6 - dy6 * dy6 - dz6 * dz6
      if attn6 > 0
        attn6 *= attn6
        value += attn6 * attn6 * extrapolate(xsb + 0, ysb + 1, zsb + 1, dx6, dy6, dz6)
      end
    end

    # First extra vertex
    attn_ext0 = 2 - dx_ext0 * dx_ext0 - dy_ext0 * dy_ext0 - dz_ext0 * dz_ext0
    if attn_ext0 > 0
      attn_ext0 *= attn_ext0
      value += attn_ext0 * attn_ext0 * extrapolate(xsv_ext0, ysv_ext0, zsv_ext0, dx_ext0, dy_ext0, dz_ext0)
    end

    # Second extra vertex
    attn_ext1 = 2 - dx_ext1 * dx_ext1 - dy_ext1 * dy_ext1 - dz_ext1 * dz_ext1
    if attn_ext1 > 0
      attn_ext1 *= attn_ext1
      value += attn_ext1 * attn_ext1 * extrapolate(xsv_ext1, ysv_ext1, zsv_ext1, dx_ext1, dy_ext1, dz_ext1)
    end

    value / NORM_CONSTANT_3D
  end
end
