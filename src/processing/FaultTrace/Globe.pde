public class Globe {
	ArrayList<GlobePoint> points;

	public Globe( ArrayList<GlobePoint> points ) {
		this.points = points;
	}

	public WB_Point[] getPoints( int max ) {
		ArrayList<WB_Point> buffer = new ArrayList<WB_Point>();
		GlobePoint point;
		int newSize = 0;
		int size = this.points.size();

		for ( int x = 0 ; x < size ; x++ ) {
			point = this.points.get(x);
			if ( point.canDisplay() ) {
				point.animate();
				buffer.add( point.getPoint() );
				newSize++;
			}
		}

		if (newSize > max) {
			for ( int x = 0 ; x < newSize-max ; x++ ) {
				if ( x < size ) {
					this.points.remove( x );
				}
			}
		}

		return buffer.toArray(new WB_Point[newSize]);
	}
}
