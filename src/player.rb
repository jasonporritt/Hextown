#class PlayerView < HexagonView
#end

class Player < Hexagon

  has_behaviors :graphical, :updatable, :physical => {
    :shape => :poly,
    :verts => Hexagon::get_verts(),
    :mass => 1000,
    :friction => 0.1
  }

  def setup
    super
    #physical.body.v_limit = 20
    physical.body.w_limit = 5
    physical.shape.group = 1
    stuck_to_player = true
  end

end
