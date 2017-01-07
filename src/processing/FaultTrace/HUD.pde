public class HUD {
	int width;
	int height;
	int margin;
	int x;
	int y;

	PFont font;

	String text;
	String posX;
	String posY;
	color fill;
	color textFill;
	ArrayList< HUDElement > elements;

	public HUD( int width, int height, String posX, String posY, PFont font ) {
		this.width = width;
		this.height = height;
		this.posX = posX;
		this.posY = posY;
		this.font = font;

		this.margin = 0;
		this.elements = new ArrayList< HUDElement >();
	}

	public void setMargin( int margin ) {
		this.margin = margin;
	}

	public void setFill( color colour ) {
		this.fill = colour;
	}

	public void setTextFill( color colour ) {
		this.textFill = colour;
	}

	public void addElement( HUDElement element ) {
		this.elements.add( element );
	}

	public void display() {

		int hudWidth = this.margin;
		int hudHeight = 0;

		// TODO allow for vertical stacking

		for ( HUDElement element : this.elements ) {
			hudWidth += element.width + this.margin;

			if ( element.height > hudHeight ) {
				hudHeight = this.margin + element.height + this.margin;
			}
		}

		switch ( this.posX ) {
			case "centre":
				this.x = this.width/2 - hudWidth/2;
				break;
			case "right":
				this.x = this.width - hudWidth;
				break;
			case "left":
				this.x = this.margin;
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
				this.y = this.height/2 - hudHeight/2;
				break;
			case "bottom":
				this.y = this.height - hudHeight;
				break;
			default:
				this.y = this.margin;
				break;
		}

		int currentX = this.x;

		noStroke();

		for ( HUDElement element : this.elements ) {
			fill( this.fill );
			rect( currentX, this.y, element.width, element.height );
			fill( this.textFill );

			// Text
			textFont( this.font, Configuration.UI.HUD.FontSize );
			textAlign( LEFT, BASELINE );
			text( element.text, currentX+this.margin, this.y+element.height-this.margin );
			currentX += element.width + this.margin;
		}
	}
}
