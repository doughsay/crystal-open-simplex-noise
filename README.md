# Open Simplex Noise

This is an implementation of 2D, 3D, and 4D open simplex noise in crystal.

## Usage

Add it to your `shard.yml`:

```yml
dependencies:
  ...
  open-simplex-noise:
    github: doughsay/crystal-open-simplex-noise
  ...
```

Instantiate a noise generator using an `Int64` seed:

```crystal
noise = OpenSimplexNoise.new(12345_i64)
```

Use the `generate` method, passing in either 2, 3, or 4 `Float64`s to generate noise:

```crystal
noise.generate(1.0, 2.0)
#=> -0.08284024020120388
```

## WIP

This is a work-in-progress; only 2D is implemented so far.

## Credits

This is mostly just a transliteration of the python version from here: https://github.com/lmas/opensimplex, which itself is a transliteration of Kurt Spencer's original code (released to the public domain).

## License

[MIT](LICENSE.md)
