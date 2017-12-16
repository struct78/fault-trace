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
		radius     = 100;
		myColor    = color( 1, 1, 1 );
		particles  = new ArrayList();
		nebulae    = new ArrayList();
	}

	public void exist() {
		setPosition();
		iterateListExist();
		render();

		pgl.disable( PGL.TEXTURE_2D );
		iterateListRenderTrails();
	}

	public void setPosition(){
		loc.addSelf( vel );

		if ( loc.y > floorLevel ) {
			loc.y = floorLevel;
			vel.y = 0;
		}
	}

	public void iterateListExist(){
		pgl.enable( PGL.TEXTURE_2D );

		int size = particles.size();
		for( int i = size - 1; i >= 0; i-- ){
			Particle p = (Particle)particles.get(i);

			if( p.ISSPLIT )
				addParticles( p );

			if ( !p.ISDEAD ){
				p.exist();
			} else {
				particles.set( i, particles.get( particles.size() - 1 ) );
				particles.remove( particles.size() - 1 );
			}
		}

		for( Iterator it = particles.iterator(); it.hasNext(); ){
			Particle p = (Particle) it.next();
			p.renderReflection();
		}
	}


	public void render() {
		renderImage( images.emitter,loc, radius, myColor, 1.0 );
		renderReflection(images.reflection);
	}

	public void renderReflection(PImage img) {
		float altitude           = floorLevel - loc.y;
		float reflectMaxAltitude = 300.0;
		float yPer               = 1.0 - altitude/reflectMaxAltitude;

		if ( yPer > .05 )
			renderImageOnFloor(img, new Vec3D( loc.x, floorLevel, loc.z ), radius * 10.0, color( 0.5, 1.0, yPer*.25 ), yPer );
			//renderImageOnFloor(img, new Vec3D( loc.x, floorLevel, loc.z ), radius + ( yPer + 1.0 ) * radius * random( 2.0, 3.5 ), color( 1.0, 0, 0 ), yPer );
	}

	public void iterateListRenderTrails() {
		for( Iterator it = particles.iterator(); it.hasNext(); ){
			Particle p = (Particle) it.next();
			p.renderTrails();
		}
	}

	public void addParticles( int a, WB_Point5D point ) {
		vec = new Vec3D( point.xf(), point.yf(), point.zf() );
		vel = vec.scale( .15 );

		for ( int i = 0; i < a; i++ ) {
			particles.add( new Particle( 1, vec, vel ) );
		}
	}

	public void addParticles( Particle _p ) {
		// play with amt if you want to control how many particles spawn when splitting
		int amt = (int)( _p.radius * .15 );
		for( int i=0; i<amt; i++ ){
			particles.add( new Particle( _p.gen + 1, _p.loc[0], _p.vel ) );
		}
	}
}
