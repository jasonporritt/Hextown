#class HexagonView < ActorView
#  def draw(target, x_off, y_off, z)
#    radius = 25
#    x = @actor.x + x_off - radius
#    y = @actor.y + y_off - radius
#
#    rotation = @actor.rotation
#    draw_ngon target, x,y, rotation, radius, 6, [200,200,255,140], z
#    target.draw_line x,y, x+offset_x(rotation,radius), y+offset_y(rotation,radius), [200,200,255.140], z
#    
#  end
#
#  def draw_ngon(target, cx,cy,a,r,sides,color, z)
#    x1, y1 = offset_x(a, r), offset_y(a, r)
#    angle = (360.0/sides)
#    (1..sides).each { |s|
#      x2, y2 = offset_x(angle*s + a, r), offset_y(angle*s + a, r)
#      target.draw_line cx + x1, cy + y1, cx + x2, cy + y2, color, z
#      x1, y1 = x2, y2
#    }
#  end
#end

class Hexagon < Actor

  attr_accessor :stuck_to_player, :player_attractor

  @stuck_to_player = false

  def self.get_verts()
    angle = (360.0/6)
    r = 25
    verts = (1..6).map { |s| [offset_x(angle*s,r), offset_y(angle*s,r)] }.reverse
  end

  has_behaviors :graphical,:updatable, :physical => {
    :shape => :poly,
    #:verts => verts,
    :verts => Hexagon::get_verts(),
    :mass => 10,
    :elasticity => 0,
    :friction => 0.4,
    #:moment => 500
  }

  def edge_nearest(vector)
    Hexagon::get_verts.map { |v|
      {:distance => Math.sqrt( (x + v[0] - other_x)**2 + (y + v[1] - other_y)**2 ), :vert => v}
    }.sort_by! { |e| e[:distance] }.take(2).map { |e| e[:vert] }
  end


end
