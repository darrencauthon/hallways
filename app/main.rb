def tick(args)
  args.outputs.background_color = [20, 20, 28]
  args.outputs.labels << {
    x: 640,
    y: 380,
    text: "Hallways",
    alignment_enum: 1,
    size_enum: 6,
    r: 240,
    g: 240,
    b: 240
  }

  args.outputs.labels << {
    x: 640,
    y: 330,
    text: "DragonRuby + Quoridor prototype",
    alignment_enum: 1,
    size_enum: 2,
    r: 180,
    g: 180,
    b: 190
  }
end
