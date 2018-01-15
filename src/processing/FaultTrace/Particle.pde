public class Particle {
	int len;            // number of elements in position array
	Vec3D[] loc;        // array of position vectors
	Vec3D startLoc;     // just used to make sure every loc[] is initialized to the same position
	Vec3D vel;          // velocity vector
	Vec3D perlin;       // perlin noise vector
	float radius;       // particle's size
	float age;          // current age of particle
	Vec3D grav;
	int lifeSpan;       // max allowed age of particle
	float agePer;       // range from 1.0 (birth) to 0.0 (death)
	int gen;            // number of times particle has been involved in a SPLIT
	float bounceAge;    // amount to age particle when it bounces off floor
	float bounceVel;    // speed at impact
	color tint;
	boolean ISDEAD;     // if age == lifeSpan, make particle die


	Particle( int _gen, Vec3D _loc, Vec3D _vel ){
		gen         = _gen;
		radius      = random( 5 - gen, 30 - ( gen-1 )*10 );

		len         = (int)( radius*.5 );
		loc         = new Vec3D[ len ];
		startLoc    = new Vec3D( _loc.add( new Vec3D().randomVector().scaleSelf( random( 1.0 ) ) ) );

		for( int i=0; i<len; i++ ){
			loc[i]    = new Vec3D( startLoc );
		}

		vel         = new Vec3D( _vel );

		if ( gen > 1 ) {
			vel.addSelf( new Vec3D().randomVector().scaleSelf( random( 1.0 ) ) );
		} else {
			vel.addSelf( new Vec3D().randomVector().scaleSelf( random( 2.0 ) ) );
		}

		perlin      = new Vec3D();

		age         = 0;
		bounceAge   = 2;
		lifeSpan    = (int)( radius );

		tint        = Configuration.Palette.Mesh.Explosions[ (int)random(Configuration.Palette.Mesh.Explosions.length) ];
		grav        = vel.scale( -Configuration.Mesh.Explosions.Gravity );
	}

	void exist(){
		findVelocity();
		setPosition();
		render();
		setAge();
	}

	void findPerlin(){
		float xyRads      = getRads( loc[0].x, loc[0].z, 20.0, 50.0 );
		float yRads       = getRads( loc[0].x, loc[0].y, 20.0, 50.0 );
		perlin.set( cos(xyRads), -sin(yRads), sin(xyRads) );
		perlin.scaleSelf( .5 );
	}

	void findVelocity() {
		if( Configuration.Mesh.Explosions.AllowGravity )
			vel.addSelf( grav );
	}

	void setPosition(){
		for( int i=len-1; i>0; i-- ){
			loc[i].set( loc[i-1] );
		}

		loc[0].addSelf( vel );
	}

	void render() {
		renderImage(images.particle, loc[0], radius * agePer, tint, 1.0 );
		renderImage(images.particle, loc[0], radius * agePer * .5, tint, agePer );
	}

	void setAge() {
		age += Configuration.Mesh.Explosions.Age;

		if ( age > lifeSpan ) {
			ISDEAD = true;
		} else {
			agePer = 1.0 - age/(float)lifeSpan;
		}
	}
}

float minNoise = 0.799;
float maxNoise = 0.801;
float getRads(float val1, float val2, float mult, float div) {
	float rads = noise(val1/div, val2/div, counter/div);

	if (rads < minNoise) minNoise = rads;
	if (rads > maxNoise) maxNoise = rads;

	rads -= minNoise;
	rads *= 1.0/(maxNoise - minNoise);

	return rads * mult;
}
