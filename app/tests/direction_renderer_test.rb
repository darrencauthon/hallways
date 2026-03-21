def test_direction_renderer_outputs_rotated_sprite_for_up_arrow(args, assert)
  renderer = DirectionRenderer.new
  fake_args = DirectionRendererTestHelpers.build_fake_args

  renderer.render(
    fake_args,
    x: 100,
    y: 200,
    size: 28,
    direction: :up,
    color: { r: 255, g: 255, b: 255 }
  )

  assert.equal! 1, fake_args.outputs.sprites.length, "Expected an arrow to render as a single rotated sprite."
  sprite = fake_args.outputs.sprites[0]
  assert.equal! 270, sprite[:angle], "Expected the up arrow to rotate the right-facing glyph by 270 degrees."
  render_target = fake_args.outputs[sprite[:path]]
  assert.equal! ">", render_target.labels[0][:text], "Expected the direction render target to be based on the > glyph."
end

module DirectionRendererTestHelpers
  def self.build_fake_args
    outputs = DirectionRendererTestFakeOutputs.new
    DirectionRendererTestFakeArgs.new(outputs)
  end
end

class DirectionRendererTestFakeOutputs
  attr_reader :sprites

  def initialize
    @sprites = []
    @render_targets = {}
  end

  def [](key)
    @render_targets[key] ||= DirectionRendererTestFakeRenderTarget.new
  end
end

class DirectionRendererTestFakeRenderTarget
  attr_accessor :w, :h
  attr_reader :labels

  def initialize
    @labels = []
  end
end

class DirectionRendererTestFakeArgs
  attr_reader :outputs

  def initialize(outputs)
    @outputs = outputs
  end
end
