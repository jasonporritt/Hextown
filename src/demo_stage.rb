class DemoStage < PhysicalStage

  attr_accessor :rotate_left, :rotate_right, :hexes_snapped_to_player
  ROTATION_SCALE = 200

  def setup
    super

    @space.iterations = 500
    @space.elastic_iterations = 10 

    @player = spawn :player, :x => 500, :y => 500
    @inactive_hexes = []
    @spawn_counter = 0
    @active_hexes = [
      spawn(:hexagon, :x => 100, :y => 100),
      spawn(:hexagon, :x => 1000, :y => 700),
    ]

    @active_hexes.each_with_index do |hex,index|
      hex.player_attractor = hex.pivot(vec2(0,0), @player, vec2(0,0))[0]
      hex.player_attractor.max_force = 200.0
      p hex.player_attractor
    end

    @hexes_to_snap_to_player = []
    space.add_collision_func(:player, :hexagon) do |player, hex|
      @hexes_to_snap_to_player << hex
    end

    @hexes_to_snap_together = []
    space.add_collision_func(:hexagon, :hexagon) do |hex1, hex2|
      @hexes_to_snap_together << [ hex1, hex2 ]
    end

    @hexes_snapped_to_player = []

    i = input_manager

    i.reg :keyboard_down, KbLeft do
      @rotate_left = true
    end
    i.reg :keyboard_down, KbRight do
      @rotate_right = true
    end

    i.reg :keyboard_up, KbLeft do
      @rotate_left = false
    end
    i.reg :keyboard_up, KbRight do
      @rotate_right = false
    end
  end

  def update(time)
    apply_movement(time)
    snap_hexes_to_player()
    snap_hex_pairs()
    spawn_new_hexes(time)
    super
  end

  SPAWN_THRESHOLD = 5000
  def spawn_new_hexes(time)
    @spawn_counter += time
    if @spawn_counter >= SPAWN_THRESHOLD
      @spawn_counter = 0
      new_hex = spawn(:hexagon, :x => 100, :y => 100)
      new_hex.player_attractor = new_hex.pivot(vec2(0,0), @player, vec2(0,0))[0]
      new_hex.player_attractor.max_force = 200.0
      @active_hexes << new_hex
    end
  end

  def apply_movement(time)

    if rotate_right
      vec = -vec2(time*ROTATION_SCALE,0)
      @player.physical.body.apply_impulse(vec, vec2(0,25))
      @player.physical.body.apply_impulse(-vec, vec2(0,-25))
      @hexes_snapped_to_player.each do |hex|
        #hex.physical.body.apply_impulse(vec, vec2(0,0))
      end
    end

    if rotate_left
      vec = vec2(time*ROTATION_SCALE,0)
      @player.physical.body.apply_impulse(vec, vec2(0,25))
      @player.physical.body.apply_impulse(-vec, vec2(0,-25))
      @hexes_snapped_to_player.each do |hex|
        #hex.physical.body.apply_impulse(vec, vec2(0,0))
      end
    end
  end

  def snap_hexes_to_player()
    @active_hexes.each do |hex|
      @hexes_to_snap_to_player.each do |collided|
        if (hex.physical.shape == collided && !hex.stuck_to_player)
          snap_together(@player, hex)
          hexes_snapped_to_player.push hex
        end
      end
    end
    @hexes_to_snap_to_player.clear
  end

  def snap_together(hex1, hex2)

    if (hex2.player_attractor != nil)
      unregister_physical_constraint(hex2.player_attractor)
      hex2.player_attractor = nil
    end

    points = get_snap_points(hex1, hex2)

    # Do the join with Pivot joints
    #hex1.pivot(vec2(points[0][0][0] - hex1.x, points[0][0][1] - hex1.y), hex2, vec2(points[0][1][0] - hex2.x, points[0][1][1] - hex2.y))
    #hex1.pivot(vec2(points[1][0][0] - hex1.x, points[1][0][1] - hex1.y), hex2, vec2(points[1][1][0] - hex2.x, points[1][1][1] - hex2.y))
    
    # Do the join with Pin joints?
    pin1 = hex1.pin(points[0][0], hex2, points[0][1])
    pin2 = hex1.pin(points[1][0], hex2, points[1][1])
    pin1.dist = 0
    pin2.dist = 0

    hex2.physical.shape.group = 1
    hex2.stuck_to_player = true
    @hexes_snapped_to_player << hex2
    @inactive_hexes << hex2
  end

  def snap_hex_pairs()
    @hexes_to_snap_together.each do |pair|
      hex1 = find_hex(pair[0])
      hex2 = find_hex(pair[1])

      if (hex1.stuck_to_player)
        snap_together(hex1, hex2)
      elsif (hex2.stuck_to_player)
        snap_together(hex2, hex1)
      end
    end
    @hexes_to_snap_together.clear
  end

  def find_hex(shape)
    found = @active_hexes.select { |hex| hex.physical.shape == shape }.first
    if (found == nil)
      found = @inactive_hexes.select { |hex| hex.physical.shape == shape }.first
    end

    found
  end


  def get_snap_points(hex1, hex2)
    vertex_pairs = get_verts_for(hex1).map { |v1|
      get_verts_for(hex2).map { |v2|
        {:distance => Math.sqrt( (v1.x - v2.x)**2 + (v1.y - v2.y)**2 ), :v1 => v1, :v2 => v2}
      }
    }.flatten!.sort_by! { |e| e[:distance] }

    closest = []
    closest << [
      hex1.physical.body.world2local(vertex_pairs.first[:v1]),
      hex2.physical.body.world2local(vertex_pairs.first[:v2]) ]

    puts "Closest:"
    p vertex_pairs.first
    vertex_pairs.each do |p|
      if (
        p[:v1].x.to_i != vertex_pairs.first[:v1].x.to_i &&
        p[:v1].y.to_i != vertex_pairs.first[:v1].y.to_i &&
        p[:v2].x.to_i != vertex_pairs.first[:v2].x.to_i &&
        p[:v2].y.to_i != vertex_pairs.first[:v2].y.to_i)

        distance = Math.sqrt( (p[:v1].x - vertex_pairs.first[:v1].x)**2 + (p[:v2].y - vertex_pairs.first[:v2].y)**2)
        # 26 to account for floating point errors and such... close enough
        if (distance <= 26)
          puts "Second closest:"
          p p
          closest << [ hex1.physical.body.world2local(p[:v1]), hex2.physical.body.world2local(p[:v2]) ]
          break
        end
      end
    end

    return closest
  end

  def get_verts_for(hex)
    Hexagon::get_verts().map { |v|
      hex.physical.body.local2world(vec2(v[0], v[1]))
    }
  end

end

