public class Globe {
	ArrayList<GlobePoint> points;
	ArrayList<WB_Point> buffer;
	ArrayList<WB_Point> bufferBase;
	HEC_Geodesic creator;
	HE_Mesh icosahedron;
	List<WB_Coord> icosahedronPoints;

	public Globe( ArrayList<GlobePoint> points ) {
		this.points = points;
		this.creator = new HEC_Geodesic();
		this.creator.setRadius( Configuration.Mesh.GlobeSize );
		this.creator.setB( 1 );
		this.creator.setC( 1 );
		this.creator.setType( HEC_Geodesic.ICOSAHEDRON );
		this.icosahedron = new HE_Mesh( creator );
		this.icosahedronPoints = icosahedron.getPoints();
		this.fillBuffer();
	}

	private void fillBuffer() {
		this.bufferBase = new ArrayList<WB_Point>();
		this.buffer = new ArrayList<WB_Point>();
		for ( WB_Coord coord : this.icosahedronPoints ) {
			this.bufferBase.add( new WB_Point( coord ) );
		}
	}

	public WB_Point[] getPoints( int max ) {
		this.buffer.clear();
		this.buffer.addAll( this.bufferBase );
		GlobePoint point;
		int newSize = this.bufferBase.size();
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

public class GlobePoint {
	long delay;
	float animationTime;
	float scale;
	WB_Point point;
	Ani animation;

	public GlobePoint( WB_Point point, long delay, float animationTime, float scale ) {
		this.delay = delay;
		this.point = point;
		this.animationTime = animationTime;
		this.scale = scale;

		this.animation = new Ani( this, this.animationTime, "scale", 1.0f, Ani.ELASTIC_OUT );
		this.animation.pause();
	}

	public boolean canDisplay() {
	 return ( millis() > this.delay );
	}

	public void animate() {
		if ( !this.animation.isPlaying() && !this.animation.isEnded() ) {
			this.animation.resume();
		}
	}

	public WB_Point getPoint() {
		return this.point.scale( this.scale );
		//return this.point;
	}
}
