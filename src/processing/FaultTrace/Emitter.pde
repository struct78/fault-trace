public class Emitter {
	Vec3D loc;
	Vec3D vel;
	Vec3D vec;
	float radius;

	color myColor;

	ArrayList particles;
	ArrayList nebulae;
	WB_Point5D point;

	public Emitter() {
		loc        = new Vec3D( );
		vel        = new Vec3D( );
		radius     = 50;
		myColor    = color( 1, 1, 1 );
		particles  = new ArrayList();
		nebulae    = new ArrayList();
	}

	public void exist() {
		setPosition();
		iterateListExist();
		render();

		pgl.disable( PGL.TEXTURE_2D );
	}

	public void setPosition() {
		loc.addSelf( vel );
	}

	public void iterateListExist(){
		pgl.enable( PGL.TEXTURE_2D );

		int size = particles.size();
		for( int i = size - 1; i >= 0; i-- ){
			Particle p = (Particle)particles.get(i);

			if ( !p.ISDEAD ){
				p.exist();
			} else {
				particles.set( i, particles.get( particles.size() - 1 ) );
				particles.remove( particles.size() - 1 );
			}
		}
	}


	public void render() {
		renderImage( images.emitter, loc, radius, myColor, 1.0 );
	}

	public void addParticles( int a, WB_Point5D point ) {
		vec = new Vec3D( point.xf(), point.yf(), point.zf() );
		vel = vec.scale( Configuration.Mesh.Explosions.Velocity );

		for ( int i = 0; i < a; i++ ) {
			particles.add( new Particle( 1, vec, vel ) );
		}
	}
}
