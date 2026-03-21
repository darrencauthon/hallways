def test_wall_placement_rules_allow_basic_two_well_placement(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)
  rules = WallPlacementRules.new
  wall = game.walls.find { |candidate| candidate.player == game.current_player && !candidate.placed? }
  wall_well = game.board.wall_wells.find { |candidate| candidate.orientation == :horizontal && candidate.col == 4 && candidate.row == 0 }

  allowed = rules.can_place?(game: game, wall: wall, wall_well: wall_well, preferred_side: :positive)

  assert.equal! true, allowed, "Expected wall placement rules to allow a basic two-well placement."
end

def test_wall_placement_rules_reject_crossing_wall_span(args, assert)
  game = Game.new(cell_width: 48, cell_height: 48)
  rules = WallPlacementRules.new
  first_wall = game.walls.find { |candidate| candidate.player == game.current_player && !candidate.placed? }
  first_well = game.board.wall_wells.find { |candidate| candidate.orientation == :horizontal && candidate.col == 4 && candidate.row == 4 }
  game.place_wall_in_well_with_side(first_wall, first_well, preferred_side: :positive)
  game.next_turn!

  crossing_wall = game.walls.find { |candidate| candidate.player == game.current_player && !candidate.placed? }
  crossing_well = game.board.wall_wells.find { |candidate| candidate.orientation == :vertical && candidate.col == 4 && candidate.row == 4 }
  allowed = rules.can_place?(game: game, wall: crossing_wall, wall_well: crossing_well, preferred_side: :positive)

  assert.equal! false, allowed, "Expected wall placement rules to reject a crossing wall span."
end
