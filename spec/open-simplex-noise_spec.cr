require "./spec_helper"

describe OpenSimplexNoise do
  it "can be instantiated without providing a seed" do
    noise = OpenSimplexNoise.new
    noise.should be_a(OpenSimplexNoise)
  end

  it "can be instantiated whith a provided seed" do
    noise = OpenSimplexNoise.new(1234i64)
    noise.should be_a(OpenSimplexNoise)
  end

  it "generates 2d noise" do
    noise = OpenSimplexNoise.new
    noise.generate(0.0, 1.0).should eq(-0.6395659667748858)
  end

  it "generates 3d noise" do
    noise = OpenSimplexNoise.new
    noise.generate(0.0, 1.0, 2.0).should eq(-0.15210355987054994)
  end

  it "generates 4d noise" do
    noise = OpenSimplexNoise.new
    noise.generate(0.0, 1.0, 2.0, 3.0).should eq(-0.1144190578536712)
  end
end
