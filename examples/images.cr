require "stumpy_png"

require "../src/open-simplex-noise"

class ExmapleImageGenerator
  include StumpyPNG

  WIDTH = 512
  HEIGHT = 512
  FRAMES = 48
  FEATURE_SIZE = 24.0

  def initialize(seed : Int64 = 0_i64)
    @noise = OpenSimplexNoise.new(seed)
  end

  def generate_images
    generate_2d_image
    generate_3d_image
    generate_3d_animation
    generate_4d_image
  end

  def generate_2d_image
    puts "Generating 2D image..."
    canvas = Canvas.new(WIDTH, HEIGHT)
    (0...HEIGHT).each do |y|
      (0...WIDTH).each do |x|
        value = @noise.generate(x / FEATURE_SIZE, y / FEATURE_SIZE)
        gray = ((value + 1) * 128).to_i
        color = RGBA.from_rgb_n(gray, gray, gray, 8)
        canvas[x, y] = color
      end
    end
    StumpyPNG.write(canvas, "examples/output/noise2d.png")
  end

  def generate_3d_image
    puts "Generating 3D image..."
    canvas = Canvas.new(WIDTH, HEIGHT)
    (0...HEIGHT).each do |y|
      (0...WIDTH).each do |x|
        value = @noise.generate(x / FEATURE_SIZE, y / FEATURE_SIZE, 0.0)
        gray = ((value + 1) * 128).to_i
        color = RGBA.from_rgb_n(gray, gray, gray, 8)
        canvas[x, y] = color
      end
    end
    StumpyPNG.write(canvas, "examples/output/noise3d.png")
  end

  def generate_3d_animation
    puts "Generating 3D animation..."
    (0...FRAMES).each do |z|
      canvas = Canvas.new(WIDTH, HEIGHT)
      (0...HEIGHT).each do |y|
        (0...WIDTH).each do |x|
          value = @noise.generate(x / FEATURE_SIZE, y / FEATURE_SIZE, z / FEATURE_SIZE)
          gray = ((value + 1) * 128).to_i
          color = RGBA.from_rgb_n(gray, gray, gray, 8)
          canvas[x, y] = color
        end
      end
      puts "writing frame #{z}"
      StumpyPNG.write(canvas, "examples/output/noise3d_frame#{z}.png")
      # use imagemagick to create gif:
      # convert -delay 10 -loop 0 -layers optimize examples/output/noise3d_frame*.png examples/output/noise3d.gif
    end
  end
end

ExmapleImageGenerator.new.generate_images
