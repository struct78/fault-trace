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
		this.creator.setRadius( Configuration.Mesh.GlobeSize);
		this.creator.setB( 3 );
		this.creator.setC( 3 );
		this.creator.setType( HEC_Geodesic.ICOSAHEDRON );
		this.icosahedron = new HE_Mesh( creator );
		this.icosahedronPoints = icosahedron.getPoints();
		this.fillBuffer();
	}

	public GlobePoint getExistingPoint( GlobePoint newPoint ) {
		int size = this.points.size();
		GlobePoint point;

		for ( int x = 0 ; x < size ; x++ ) {
			point = this.points.get(x);
			WB_Vector vec = point.point.subToVector3D( newPoint.point );

			if (
				abs((float)vec.xd()) <= Configuration.Optimisations.PointDistanceTolerance &&
				abs((float)vec.yd()) <= Configuration.Optimisations.PointDistanceTolerance &&
				abs((float)vec.zd()) <= Configuration.Optimisations.PointDistanceTolerance
			) {
				return point;
			}
		}

		return null;
	}

	public HE_Mesh getGeodesic() {
		return this.icosahedron;
	}

	private void fillBuffer() {
		this.bufferBase = new ArrayList<WB_Point>();
		this.buffer = new ArrayList<WB_Point>();

		if ( Configuration.Mesh.UseIcosahedronBase ) {
			for ( WB_Coord coord : this.icosahedronPoints ) {
				this.bufferBase.add( new WB_Point( coord ) );
			}
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
					point = this.points.get(x);

					if ( !point.isFinishing && !point.isFinished ) {
						point.remove();
					}

					if ( point.isFinished ) {
						this.points.remove( x );
					}
				}
			}
		}
		return this.buffer.toArray( new WB_Point[ newSize ] );
	}
}

public class GlobePoint {
	ArrayList<Long> delays;
	ArrayList<Float> animationTimes;
	ArrayList<Float> scales;
	ArrayList<Ani> animations;

	long delay;
	float animationTime;
	float scale;
	boolean isFinished;
	boolean isFinishing;
	int index;
	WB_Point point;
	Ani animation;

	public GlobePoint( WB_Point point ) {
		this.delays = new ArrayList<Long>();
		this.animationTimes = new ArrayList<Float>();
		this.scales = new ArrayList<Float>();
		this.animations = new ArrayList<Ani>();
		this.point = point;
		this.scale = 0.0;
		this.index = 0;
		this.isFinished = false;
		this.isFinishing = false;
	}

	public void addDelay( long delay ) {
		this.delays.add( delay );
	}

	public void addScale( float scale ) {
		this.scales.add( scale );
	}

	public void addAnimationTime( float animationTime ) {
		this.animationTimes.add( animationTime );
	}

	public void addAnimation( float scale, float animationTime ) {
	 	Ani animation = new Ani( this, animationTime, "scale", scale, Ani.EXPO_OUT );
		animation.pause();

		this.animations.add( animation );

		animation = null;
	}

	public void remove() {
		this.isFinishing = true;
		this.isFinished = false;
		Ani animation = new Ani( this, Configuration.Animation.Duration.Max, "scale", 0.0, Ani.EXPO_IN, "onEnd:onEnd" );
		animation.start();
	}

	public void onEnd() {
		this.isFinished = true;
		this.isFinishing = false;
	}

	public boolean canDisplay() {
		for ( int x = 0 ; x < this.delays.size() ; x++ ) {
			long delay = this.delays.get( x );
			float animationTime = this.animationTimes.get( x );
			if ( millis() >= delay ) {
				this.index = x;
				return true;
			}
		}

		return false;
	}

	public void animate() {
		Ani animation = this.animations.get( this.index );
		if ( animation != null ) {
			if ( !animation.isPlaying() && !animation.isEnded() ) {
				animation.resume();
			}
		}
	}

	public WB_Point getPoint() {
		return this.point.scale( this.scale );
	}
}
