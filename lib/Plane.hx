class Plane extends Polygon {

	public function new( x = 1, y = 1, z = 1 )
	{
		var p = [
			new Vector(x, y, z),
			new Vector(-x, y, z),
			new Vector(-x, -y, z),
			new Vector(x, -y, z),
		];
		var idx = [
			0, 3, 1,
			1, 3, 2			
		];
		super(p, idx);
	}
	
}