module PlayerPalette
  COLORS = [
    [143, 45, 45],
    [47, 75, 143],
    [47, 107, 69],
    [154, 106, 31]
  ].freeze

  BOX_FILLS = COLORS.map do |color|
    { r: color[0], g: color[1], b: color[2], a: 220 }
  end.freeze
end
