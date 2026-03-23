def test_player_box_renderer_uses_placeholder_when_image_missing(args, assert)
  renderer = PlayerBoxRenderer.new
  fake_args = PlayerBoxRendererTestFakeArgs.new

  renderer.render(
    fake_args,
    x: 10,
    y: 20,
    fill_color: { r: 1, g: 2, b: 3 },
    selected: false,
    title: "Player 1",
    title_size_enum: 1,
    title_color: { r: 255, g: 255, b: 255 },
    subtitle: "",
    subtitle_size_enum: 1,
    subtitle_color: { r: 255, g: 255, b: 255 },
    image_path: nil
  )

  assert.equal! 0, fake_args.outputs.sprites.length, "Expected placeholder avatars to avoid sprite rendering."
  assert.equal! true, fake_args.outputs.solids.length > 2, "Expected placeholder avatars to render the existing X marker."
end

def test_player_box_renderer_uses_sprite_when_image_present(args, assert)
  renderer = PlayerBoxRenderer.new
  fake_args = PlayerBoxRendererTestFakeArgs.new

  renderer.render(
    fake_args,
    x: 10,
    y: 20,
    fill_color: { r: 1, g: 2, b: 3 },
    selected: false,
    title: "Caveman",
    title_size_enum: 1,
    title_color: { r: 255, g: 255, b: 255 },
    subtitle: "",
    subtitle_size_enum: 1,
    subtitle_color: { r: 255, g: 255, b: 255 },
    image_path: "sprites/caveman.png"
  )

  assert.equal! 1, fake_args.outputs.sprites.length, "Expected avatar images to render as sprites."
  assert.equal! "sprites/caveman.png", fake_args.outputs.sprites[0][:path], "Expected the supplied avatar image path to be used."
end

class PlayerBoxRendererTestFakeOutputs
  attr_accessor :solids, :sprites, :borders, :labels

  def initialize
    @solids = []
    @sprites = []
    @borders = []
    @labels = []
  end
end

class PlayerBoxRendererTestFakeArgs
  attr_reader :outputs

  def initialize
    @outputs = PlayerBoxRendererTestFakeOutputs.new
  end
end
