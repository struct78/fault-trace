public class Graph {
	ArrayList<GraphPoint> points;
	ArrayList<GraphPoint> buffer;
	int width;
	int height;
	int graphWidth;
	int graphHeight;
	int margin;
	int x;
	int y;
	int newSize;

	String posX;
	String posY;
	GraphPoint point;
	color fill;
	color lineStroke;
	ArrayList< HUDElement > elements;

	public Graph( ArrayList<GraphPoint> points, int width, int height, int graphWidth, int graphHeight, String posX, String posY ) {
		this.width = width;
		this.height = height;
		this.graphWidth = graphWidth;
		this.graphHeight = graphHeight;
		this.posX = posX;
		this.posY = posY;
		this.points = points;
		this.buffer = new ArrayList<GraphPoint>();
		this.newSize = 0;
	}

	public void getPoints( int max ) {
		this.buffer.clear();
		int size = this.points.size();

		for ( int x = 0 ; x < size ; x++ ) {
			point = this.points.get(x);
			if ( point.canDisplay() ) {
				this.buffer.add( point );
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
	}

	public void setMargin( int margin ) {
		this.margin = margin;
	}

	public void setFill( color colour ) {
		this.fill = colour;
	}

	public void setLineStroke( color colour ) {
		this.lineStroke = colour;
	}

	public void display() {
		int multiplier = 2;

		switch ( this.posX ) {
			case "centre":
				this.x = this.width/2 - this.graphWidth/2;
				break;
			case "right":
				this.x = this.width - this.graphWidth - ( this.margin * multiplier );
				break;
			case "left":
				this.x = this.margin * multiplier;
				break;
			default:
				this.x = this.margin;
				break;
		}

		switch ( this.posY ) {
			case "top":
				this.y = this.margin;
				break;
			case "middle":
				this.y = this.height/2 - this.graphHeight/2;
				break;
			case "bottom":
				this.y = this.height - this.graphHeight - ( this.margin * multiplier );
				break;
			default:
				this.y = this.margin;
				break;
		}

		fill( this.fill );
		rect( this.x, this.y, this.graphWidth, this.graphHeight );
		noFill();
		stroke( this.lineStroke );
		pushMatrix();
		translate( this.x, this.y + this.graphHeight - ( this.margin * multiplier ) );
		beginShape();

		int x = 0;
		for ( GraphPoint point : this.buffer ) {
			vertex( x, -map( point.magnitude, 1, 10, 1, this.graphHeight ) );
			x++;
		}
	  endShape();
		popMatrix();
	}
}

public class GraphPoint {
	float magnitude;
	long delay;

	public GraphPoint( long delay, float magnitude ) {
		this.delay = delay;
		this.magnitude = magnitude;
	}

	public boolean canDisplay() {
	 return ( millis() > this.delay );
	}
}
