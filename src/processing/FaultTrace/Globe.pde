public class Globe {
	ArrayList<GlobePoint> points;
	ArrayList<WB_Point> buffer;

	public Globe( ArrayList<GlobePoint> points ) {
		this.points = points;
		this.buffer = new ArrayList<WB_Point>();
	}

	public WB_Point[] getPoints( int max ) {
		this.buffer.clear();
		GlobePoint point;
		int newSize = 0;
		int size = this.points.size();

		for ( int x = 0 ; x < size ; x++ ) {
			point = this.points.get(x);
			if ( point.canDisplay() ) {
				point.animate();
				this.buffer.add( point.getPoint() );
				newSize++;
			}
		}

		if ( newSize > max ) {
			for ( int x = 0 ; x < newSize-max ; x++ ) {
				if ( x < size ) {
					this.points.remove( x );
				}
			}
		}

		return this.buffer.toArray( new WB_Point[ newSize ] );
	}
}
