
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
		if ( this.animation.isEnded() ) {
			return this.point;
		}
		else {
			WB_Vector dv = new WB_Vector( this.point.get() ).mulSelf( this.scale );
			return new WB_Point(dv);
		}
	}
}
