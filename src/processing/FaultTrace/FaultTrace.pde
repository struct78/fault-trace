import de.looksgood.ani.*;
import de.looksgood.ani.easing.*;
import java.util.Arrays;
import java.util.Collections;
import java.util.Calendar;
import java.util.Date;
import java.util.List;
import java.util.GregorianCalendar;
import java.util.Iterator;
import java.util.Timer;
import java.util.TimerTask;
import java.util.TimeZone;
import java.text.SimpleDateFormat;
import java.awt.Rectangle;
import java.awt.geom.Point2D;
import java.awt.Point;
import javax.sound.midi.*;
import themidibus.*;
import wblut.geom.*;
import wblut.hemesh.*;
import wblut.math.*;
import wblut.processing.*;

long setupTime;
long delay;
long quantized_delay;
long start_ms;
long end_ms;
long diff_quantized_ms;
long diff_accelerated_ms;

float theta = 180;

Timer timer;
ThreadTask task;
StateManagerThread stateThread;
Note note;
MidiBus bus;

Iterable<TableRow> rows;
ArrayList<Rectangle> grid = new ArrayList();
ArrayList<Integer> colours = new ArrayList();
ArrayList<Integer> lightColours = new ArrayList();
ArrayList<StateManager> states = new ArrayList();
ArrayList<GlobePoint> points = new ArrayList<GlobePoint>();
ArrayList<GraphPoint> graphPoints = new ArrayList<GraphPoint>();
ArrayList<ArrayList<WB_Point4D>> segments = new ArrayList<ArrayList<WB_Point4D>>();

PFont font;
HE_Mesh globeMesh;
HE_Mesh wireframeMesh;
WB_Render3D render;
WB_DebugRender3D debugRender;
HEC_ConvexHull creatorGlobe;
HEM_Twist twist;
HEM_Lattice lattice;
HEMC_VoronoiCells voronoi;
HE_MeshCollection meshCollection;
HEM_Extrude extrude;
HEC_Geodesic geodesic;

WB_Point4D[] meshPoints;
Globe globe;
Graph graph;
Ani globeAnimation;
float globeScale = 1.0;

Calendar startDate;
Calendar endDate;
Calendar calendar;
Calendar currentDate;
TimeZone timeZone;
String dateFormat;
SimpleDateFormat format;
SimpleDateFormat monthFormat;
SimpleDateFormat dayFormat;
SimpleDateFormat hourFormat;
SimpleDateFormat minuteFormat;
color colour;
HUD hud;
Point2D.Double rectanglePoint;
int uiGridWidth;
int uiMargin;

public void settings() {
	size(1920, 1080, P3D);
	smooth(4);
	pixelDensity(2);
}

void setup() {
	setupTimezone();
	setupTiming();
	setup3D();
	setupUI();
	setupFonts();
	setupAnimation();
	setupGrid();
	setupTimer();
	setupMIDI();
	setupData();
	setupGlobe();
	setupSong();
	setupUIThread();
	setupRenderer();
	setupShutdownHook();
	setupFrameRate();
	setupTime = millis();
	setupDebug();
}

void draw() {
	noCursor();
	drawBackground();
	drawHUD();
	drawGraph();
	drawGlobe();
	saveFrames();
}

void setupGlobe() {
	globe = new Globe( this.points );
}

void setupTiming() {
	start_ms = startDate.getTimeInMillis();
	end_ms = endDate.getTimeInMillis();
	diff_accelerated_ms = Configuration.MIDI.StartOffset + ( ( ( end_ms-start_ms )/Configuration.MIDI.Acceleration ) );
	diff_quantized_ms = Configuration.MIDI.StartOffset + quantize( ( ( end_ms-start_ms ) / Configuration.MIDI.Acceleration ) );
}

void setup3D() {
	// Normal mesh
	creatorGlobe = new HEC_ConvexHull();

	// Lattice
	lattice = new HEM_Lattice().setWidth( 20 ).setDepth( 10 );

	// Twist
	WB_Line line = new WB_Line( 0, 0, 0, 0, exp(1.0) / 2, exp(1.0) / 2 );
	twist = new HEM_Twist().setTwistAxis( line ).setAngleFactor( 1.0 );

	// Voronoi
	voronoi = new HEMC_VoronoiCells();

	// Spikes
	extrude = new HEM_Extrude().setChamfer( 1 ).setDistance( 10 );
	// Extrude
	//extrude = new HEM_Extrude().setHardEdgeChamfer( 1 ).setDistance( 30 );

	geodesic = new HEC_Geodesic();
	geodesic.setRadius( Configuration.Mesh.GlobeSize );
	geodesic.setB( 2 );
	geodesic.setC( 2 );
	geodesic.setType( HEC_Geodesic.ICOSAHEDRON );
}

void setupTimezone() {
	timeZone = TimeZone.getTimeZone( Configuration.Data.TimeZone );
	dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS";

	startDate = Calendar.getInstance();
	endDate = Calendar.getInstance();

	format = new SimpleDateFormat( dateFormat );
	format.setTimeZone( timeZone );

	monthFormat = new SimpleDateFormat("MMM");
	dayFormat = new SimpleDateFormat("dd");
	hourFormat = new SimpleDateFormat("HH");
	minuteFormat = new SimpleDateFormat("mm");

	monthFormat.setTimeZone( timeZone );
	dayFormat.setTimeZone( timeZone );
	hourFormat.setTimeZone( timeZone );
	minuteFormat.setTimeZone( timeZone );

	try {
		startDate.setTime( format.parse( Configuration.Timing.StartDate ) ) ;
		endDate.setTime( format.parse( Configuration.Timing.EndDate ) ) ;
	}
	catch( Exception ex ) {
		println( "Parse exception: " + ex ) ;
	}
}

void setupAnimation() {
	Ani.init(this);
  globeAnimation = new Ani(this, Configuration.Animation.Zoom.Time, "globeScale", globeScale, Ani.QUAD_IN_OUT, "onEnd:setGlobeScale");
}

void setGlobeScale() {
	float endValue = globeAnimation.getEnd();
	globeScale = random( 1.0, 1.5 );
	globeAnimation.setBegin( endValue );
	globeAnimation.setEnd( globeScale );
	globeAnimation.start();
}

void setupUI() {
	// Colours are seasonal
	// Left -> Right = January - December
	//colours.addAll( Arrays.asList( 0xffe31826, 0xffFF6138, 0xffFD7400, 0xff28DAB1, 0xff28DAB1, 0xffce1a9a, 0xffffb93c, 0xff00e0c9, 0xff234baf, 0xff47b1de, 0xffb4ef4f, 0xff26bb12, 0xff3fd492, 0xfff7776d ) );
	//lightColours.addAll( Arrays.asList( 0xFF1899CC, 0xFF79BD8F ) );
	uiGridWidth = Configuration.UI.GridWidth;
	uiMargin = Configuration.UI.Margin;
}

void setupFonts() {
	this.font = loadFont( Configuration.UI.HUD.Font );
}

void setupGrid() {
	for ( int x = 0 ; x < 360; x += 90 ) {
		for ( int y = 0 ; y < 180 ; y += 90 ) {
			grid.add( new Rectangle( x, y, 90, 90 ) );
		}
	}
}

void setupMIDI() {
	// Create the MIDI Bus
	bus = new MidiBus( this, -1, "FaultTrace" );
}

long quantize( long delay ) {
	int type = ( int ) ( ( delay % Configuration.MIDI.BeatsPerBar ) % Configuration.MIDI.NoteType.length );
	float milliseconds_per_beat = ( 60 * 1000 ) / (float)Configuration.MIDI.BeatsPerMinute;
	float milliseconds_per_measure = milliseconds_per_beat * Configuration.MIDI.BeatsPerBar;
	float milliseconds_per_note = milliseconds_per_beat * ( Configuration.MIDI.BeatDivision / Configuration.MIDI.NoteType[ type ]);

	return (long)(Math.round( delay / milliseconds_per_note ) * milliseconds_per_note);
}

void setupSong() {
	// Set the delay between notes
	delay = Configuration.MIDI.StartOffset;
	quantized_delay = delay;

	// CSV
	double latitude, longitude;
	float depth, magnitude, rms;

	String date;
	String previousDate = null;

	Calendar d1 = Calendar.getInstance();
	Calendar d2 = Calendar.getInstance();

	d1 = (Calendar)startDate.clone();

	int x = 0;

	for (TableRow row : rows ) {
		// Extract the data
		date = row.getString("time");
		latitude = row.getDouble("latitude");
		longitude = row.getDouble("longitude");
		depth = row.getFloat("depth");
		magnitude = row.getFloat("mag");
		rms = row.getFloat("rms");

		try {
			if (previousDate != null) {
				d1.setTime(format.parse(previousDate));
			}

			d2.setTime(format.parse(date));
		}
		catch( Exception ex ) {
			println( ex );
			continue;
		}

		if ( d2.after( startDate ) && d2.before( endDate ) ) {
			// Diff in milliseconds
			long diff = d2.getTimeInMillis() - d1.getTimeInMillis();

			// Increase the delay
			delay += (diff/Configuration.MIDI.Acceleration);
			quantized_delay = quantize(delay);

			int channel = getChannelFromCoordinates( latitude, longitude );
			int velocity = mapMagnitude( magnitude );
			int pitch = mapDepth( depth );
			int duration = mapMagnitude( magnitude, Configuration.MIDI.Note.Min, Configuration.MIDI.Note.Max );
			float animationTime = mapMagnitude( magnitude, Configuration.Animation.Duration.Min, Configuration.Animation.Duration.Max );
			float scale = map( depth, 0, Configuration.Data.Depth.Max, Configuration.Animation.Scale.Min, Configuration.Animation.Scale.Max );
			float distance = mapMagnitude( magnitude, Configuration.Data.Distance.Min, Configuration.Data.Distance.Max );
			color colour = getColourFromMonth( d2 );

			WB_Point wbPoint = Geography.CoordinatesToWBPoint( latitude, longitude, scale, Configuration.Mesh.GlobeSize );

			GlobePoint newPoint = new GlobePoint( wbPoint );
			GlobePoint existingPoint = globe.getExistingPoint( newPoint );

			if ( existingPoint != null ) {
				existingPoint.addDelay( quantized_delay + millis() );
				existingPoint.addAnimationTime( animationTime );
				existingPoint.addScale( scale );
				existingPoint.addAnimation( scale, distance, animationTime );
				existingPoint.addDistance( distance );
			}
			else {
				newPoint.addDelay( quantized_delay + millis() );
				newPoint.addAnimationTime( animationTime );
				newPoint.addScale( scale );
				newPoint.addAnimation( scale, distance, animationTime );
				newPoint.addDistance( distance );
				points.add( newPoint );
			}

			graphPoints.add( new GraphPoint( delay + millis(), magnitude ) );
			states.add( new StateManager( d2, colour, (long)(diff/Configuration.MIDI.Acceleration) ) );

			setNote( channel, velocity, pitch, duration, quantized_delay );

			// Heavy guitar
			if ( depth >= 300 ) {
				setNote( 8, velocity, 60, mapMagnitude( magnitude, 20, 10000 ), quantized_delay );
			}

			// Drone
			if ( depth >= 500 ) {
				setNote( 9, velocity, 60, mapMagnitude( magnitude, 20, 10000 ), quantized_delay );
			}

			x++;
		}

		// Update the previous date to the current date for the next iteration
		previousDate = date;
	}
}

void setNote( int channel, int velocity, int pitch, int duration, long delay ) {
	// Create the note
	note = new Note( bus );

	// Each instrument/section represents 1/8th of the globe
	note.channel = channel;

	// How hard the note is hit
	note.velocity = velocity;

	// Pitch of the note
	note.pitch = pitch;

	// How long the note is played for, on some instruments this makes no difference
	note.duration = duration;

	// Add the note to task schedule
	timer.schedule( new ThreadTask(note), delay );
}

void setupData() {
	// Load the data
	Table table = loadTable( Configuration.IO.CSV, "header" );
	rows = table.rows();
}

void setupTimer() {
	timer = new Timer();
}

void setupUIThread() {
	stateThread = new StateManagerThread( states );
	timer.schedule( new ThreadTask( stateThread ), Configuration.MIDI.StartOffset );
}

void setupRenderer() {
	render = new WB_Render3D( this );
}

void setupDebug() {
	println("Tempo: " + Configuration.MIDI.BeatsPerMinute + " BPM");
	println("Time Signature: " + Configuration.MIDI.BeatsPerBar + "/" + Configuration.MIDI.BeatDivision);
	println("Estimated song length: " + (float)diff_accelerated_ms/1000 + " seconds // "+ diff_accelerated_ms/1000/60 + " minutes // " + diff_accelerated_ms/1000/60/60 + " hours // " + diff_accelerated_ms/1000/60/60/24 + " days");
	println("Total " + diff_accelerated_ms + "ms");
	println("Quantized " + diff_quantized_ms + "ms");
	println("Total Data Points: " + points.size() );
}

String getDatePart( SimpleDateFormat dateFormat ) {
	long start = startDate.getTimeInMillis();
	long end = endDate.getTimeInMillis();
	long diff = start+(((long)millis()-setupTime)*Configuration.MIDI.Acceleration);

	if ( diff > end ) {
		return dateFormat.format( end );
	}

	return dateFormat.format( diff );
}

void setupShutdownHook() {
	Runtime.getRuntime().addShutdownHook( new Thread( new Runnable() {
		public void run() {
			for ( int x = 0; x < Configuration.MIDI.Channels; x++ ) {
				bus.sendMessage( ShortMessage.CONTROL_CHANGE, x, 0x7B, 0 );
			}
			bus.close();
		}
	}
	));
}

void setupFrameRate() {
	frameRate( Configuration.UI.FPS );
}

void drawBackground() {
	background( 17, 19, 23 );
}

void drawLights( color colour ) {
	ambient( colour );
	directionalLight( red( colour ), green( colour ), blue( colour ), 0, 0, -1 );
	pointLight( red( Configuration.Palette.Lights.Left ), green( Configuration.Palette.Lights.Left ), blue( Configuration.Palette.Lights.Left ), 0, 0, 250 );
	pointLight( red( Configuration.Palette.Lights.Right ), green( Configuration.Palette.Lights.Right ), blue( Configuration.Palette.Lights.Right ), width, height, 0 );
	shininess( 0.03 );
}

void drawRotation() {
	// Move
	theta += Configuration.Animation.Speed;

	translate( width / 2, ( height / 2 ), 0 );
	rotateY( theta );
	rotateX( radians(23.5) );
}

void drawMesh( color colour, WB_Point4D[] points ) {
	hint(ENABLE_DEPTH_TEST);
	if ( Configuration.Mesh.Renderer != RenderType.Lines ) {
		creatorGlobe.setPoints( points );
		globeMesh = new HE_Mesh( creatorGlobe );
	}

	if ( Configuration.Mesh.ShowWireframe ) {
		noFill();
		stroke( 150, 150, 160, 50 );
		wireframeMesh = new HE_Mesh( geodesic );
		render.drawFaces( wireframeMesh );

		noStroke();
		fill( 225, 225, 230, 110 );
	}

	strokeWeight( 0.66 );
	stroke( colour+3 );

	switch( Configuration.Mesh.Type ) {
		case Dual:
			globeMesh = new HE_Mesh( new HEC_Dual( globeMesh ) );
			break;
		case Voronoi:
			voronoi.setPoints( points );
			voronoi.setN( points.length / 10 );
			voronoi.setContainer( globe.getGeodesic() );
			voronoi.setOffset( 2 );
			voronoi.setSurface( false );
			voronoi.setCreateSkin( false );
			meshCollection = voronoi.create();
			break;
		case Lattice:
			globeMesh.modify( lattice );
			break;
		case Twisted:
			globeMesh.modify( twist );
			break;
		case Extrude:
			globeMesh.modify( extrude );
			//extrude.extruded.modify( new HEM_Extrude().setDistance( 5 ) );
		default:
			break;
	}



	switch ( Configuration.Mesh.Renderer ) {
		case Edges:
			noFill();

			if ( Configuration.Mesh.Type == MeshType.Voronoi ) {
				render.drawEdges( meshCollection );
			} else {
				render.drawEdges( globeMesh );
			}

			break;
		case Faces:
			noStroke();

			if ( Configuration.Mesh.Type == MeshType.Voronoi ) {
				render.drawFaces( meshCollection );
			} else {
				render.drawFaces( globeMesh );
			}

			break;
		case EdgesFaces:
			break;
		case FacesPoints:
			renderFacesPoints( globeMesh, meshCollection );
			break;
		case Points:
			renderPoints( globeMesh );
			break;
		case EdgesPoints:
			renderEdgesPoints( globeMesh );
			break;
		case EdgesFacesPoints:
			renderEdgesFacesPoints( globeMesh );
			break;
		case Lines:
			renderLines( points );
		case Particles:
			renderParticles( points );
		case Rings:
			renderRings( points );
		default:
			break;
	}
}

void renderEdgesFaces( HE_Mesh globeMesh, HE_MeshCollection meshCollection ) {
	if ( Configuration.Mesh.Type == MeshType.Voronoi ) {
		render.drawEdges( meshCollection );
		render.drawFaces( meshCollection );
	} else {
		render.drawEdges( globeMesh );
		render.drawFaces( globeMesh );
	}
}

void renderFacesPoints( HE_Mesh globeMesh, HE_MeshCollection meshCollection ) {
	if ( Configuration.Mesh.Type == MeshType.Voronoi ) {
		noStroke();
		render.drawFaces( meshCollection );
	} else {
		render.drawPoint( globeMesh.getPoints(), (double)2 );
		noStroke();
		render.drawFaces( globeMesh );
	}
}

void renderPoints( HE_Mesh globMesh ) {
	render.drawPoint( globeMesh.getPoints(), (double)2 );
}
void renderEdgesPoints( HE_Mesh globeMesh ) {
	noFill();
	render.drawEdges( globeMesh );
	render.drawPoint( globeMesh.getPoints(), (double)2 );
}

void renderEdgesFacesPoints( HE_Mesh globeMesh ) {
	render.drawEdges( globeMesh );
	render.drawPoint( globeMesh.getPoints(), (double)1 );
	noStroke();
	render.drawFaces( globeMesh );
}

void renderLines( WB_Point4D[] points ) {
	for ( WB_Point4D point : points ) {
		float distance = point.wf();
		WB_Point4D endpoint = point.mul( distance );
		float radius = Configuration.Mesh.GlobeSize;

		strokeWeight( HALF_PI );

		if ( pow( endpoint.xf(), 2 ) + pow( endpoint.yf(), 2 ) + pow( endpoint.zf(), 2 ) < pow( radius, 2 ) )
		{
			stroke( Configuration.Palette.Mesh.Line );
		}
		else {
			stroke( colour );
		}

		line( point.xf(), point.yf(), point.zf(), endpoint.xf(), endpoint.yf(), endpoint.zf() );
	}
}

int getRingLevelFromPoint( WB_Point4D point ) {
	float yf = point.yf();
	int level = (int)Math.ceil((yf + Configuration.Mesh.GlobeSize) / Configuration.Mesh.Rings.Distance);
	return level < 0 ? 0 : level;
}

double getAngleFromVector(float xf, float zf) {
	return ((atan2(xf, zf) * ( 180 / Math.PI ) + 360) % 360);
}

float getRadiusOnYPlane( int y ) {
	return (float)Math.sqrt( Math.pow( Configuration.Mesh.GlobeSize, 2 ) - Math.pow( y, 2 ) );
}

void renderRings( WB_Point4D[] points ) {
	noFill();

	int levels = ((Configuration.Mesh.GlobeSize * 2) * Configuration.Mesh.Rings.Distance);

	segments.clear();

	for ( int x = 0 ; x < levels ; x++ ) {
		segments.add(new ArrayList<WB_Point4D>());
	}

	for ( WB_Point4D point : points ) {
		int level = getRingLevelFromPoint( point );
		segments.get(level).add(point);
	}

	float wf, xf, yf, zf, amp = 0.0;
	double deg = 0.0;

	for ( int y = 0-Configuration.Mesh.GlobeSize ; y < Configuration.Mesh.GlobeSize; y+=Configuration.Mesh.Rings.Distance) {
		int level = (int)((y + Configuration.Mesh.GlobeSize) / Configuration.Mesh.Rings.Distance);
		float radius = getRadiusOnYPlane(y);

		WB_Point4D segmentPoint;

		pushMatrix();
		translate( 0, y, 0 );
		rotateX(radians(-90));
		noFill();
		blendMode(ADD);
		strokeWeight(0.5);
		beginShape();

	  for ( int j = 0; j < 360; j+=Configuration.Mesh.Rings.RotationStep ) {
			amp = 0.0;
			for ( int k = 0 ; k < segments.get(level).size(); k++ ) {
				segmentPoint = segments.get(level).get(k);

				wf = segmentPoint.wf();
				xf = segmentPoint.xf();
				yf = segmentPoint.yf();
				zf = segmentPoint.zf();

				deg = getAngleFromVector(xf, zf);
				if (deg >= j && deg <= j+Configuration.Mesh.Rings.RotationStep) {
					//println(xf + ":" + zf + ":" + deg + ":" + cos(radians((float)deg)) * (radius) + ":" + sin(radians((float)deg)) * (radius) + ":" + cos(radians(j)) * radius +":" + sin(radians(j)) * radius);
					//curveVertex( cos(radians(j)) * (radius * wf), sin(radians(j)) * (radius * wf) );

					//vertex( zf, xf );
					float mid = j - (Configuration.Mesh.Rings.RotationStep/2);

					stroke( Configuration.Palette.Mesh.Line, 128 );
					vertex( cos(radians(mid)) * (radius * wf), sin(radians(mid)) * (radius * wf)  );
				}
			}

			stroke( Configuration.Palette.Mesh.Line, 64 );
			vertex( cos(radians(j)) * radius, sin(radians(j)) * radius );
	  }

		endShape(CLOSE);

		popMatrix();

		blendMode(NORMAL);
	}
}

void renderParticles( WB_Point4D[] points ) {

}

void drawGlobe() {
	meshPoints = globe.getPoints( Configuration.Mesh.MaxPoints );

	currentDate = (Calendar)stateThread.getDate();
	colour = stateThread.getColour();

	if ( currentDate != null && meshPoints.length > 4 ) {
		drawLights( colour );
		drawRotation();
		drawMesh( colour, meshPoints );
	}
	else {
		setupTime = millis();
	}
}

void drawGraph() {
	Calendar currentDate = (Calendar)stateThread.getDate();

	if ( currentDate != null ) {
		strokeWeight( 0.66 );
		graph = new Graph( graphPoints, width, height, (uiGridWidth*4) + (uiMargin*3), uiGridWidth, "right", "bottom" );
		graph.setMargin( uiMargin );
		graph.setFill( stateThread.getColour() );
		graph.setLineStroke( Configuration.Palette.UI.Foreground );
		graph.getPoints( (uiGridWidth*4) + (uiMargin*3) );
		graph.display();
	}
}

void drawHUD() {
	Calendar currentDate = (Calendar)stateThread.getDate();

	if ( currentDate != null ) {
		hud = new HUD( width, height, "left", "bottom", this.font);
		hud.setMargin( uiMargin );
		hud.setFill( stateThread.getColour() );
		hud.setTextFill( Configuration.Palette.UI.Foreground );
		hud.addElement( new HUDElement( uiGridWidth, uiGridWidth, getDatePart( monthFormat ).substring(0,3), "bottom", "left" ) );
		hud.addElement( new HUDElement( uiGridWidth, uiGridWidth, getDatePart( dayFormat ), "bottom", "left" ) );
		hud.addElement( new HUDElement( uiGridWidth, uiGridWidth, getDatePart( hourFormat ), "bottom", "left" ) );
		hud.addElement( new HUDElement( uiGridWidth, uiGridWidth, getDatePart( minuteFormat ), "bottom", "left" ) );
		hud.display();
	}
}

int getChannelFromCoordinates( double latitude, double longitude ) {
	latitude = latitude + 90;
	longitude = longitude + 180;

	for ( Rectangle rectangle : grid ) {
		rectanglePoint = new Point2D.Double( longitude, latitude );
		if ( rectangle.contains( rectanglePoint ) ) {
			return grid.indexOf( rectangle );
		}
	}

	return 0;
}

color getColourFromMonth( Calendar date ) {
	int daysinmonth = date.getActualMaximum( Calendar.DAY_OF_MONTH );
	return lerpColor( color( Configuration.Palette.UI.Start.Background ), color( Configuration.Palette.UI.End.Background ), (float)date.get(Calendar.DAY_OF_MONTH)/daysinmonth );
}

void saveFrames() {
	if ( Configuration.IO.SaveFrames ) {
		saveFrame("frameGrabs/frame-########.tga");
	}
}

int mapDepth( float depth ) {
	return invert( int( map( depth, 0, Configuration.Data.Depth.Max, Configuration.MIDI.Pitch.Min, Configuration.MIDI.Pitch.Max ) ), Configuration.MIDI.Pitch.Min, Configuration.MIDI.Pitch.Max );
}

int mapDepth( float depth, int min, int max ) {
	return invert( int( mapexp( depth, 0, Configuration.Data.Depth.Max, min, max ) ), min, max );
}

float mapDepth(float depth, float min, float max) {
	return invert( mapexp( depth, 0, Configuration.Data.Depth.Max, min, max ), min, max);
}

int mapMagnitude( float magnitude ) {
	return int( mapexp( magnitude, 0, 10, Configuration.MIDI.Velocity.Min, Configuration.MIDI.Velocity.Max ) );
}

int mapMagnitude( float magnitude, int min, int max ) {
	return int( mapexp( magnitude, 0, 10, min, max ) );
}

float mapMagnitude( float magnitude, float min, float max ) {
	return mapexp( magnitude, 0, 10, min, max );
}

int mapexp( float m, int a, int b, int min, int max ) {
	float scale = ( log( max ) - log( min ) ) / ( b - a );
	return int( exp ( log( min ) + scale * ( m - a ) ) );
}

float mapexp( float m, float a, float b, float min, float max ) {
	float scale = ( log( max ) - log( min ) ) / ( b - a );
	return exp ( log( min ) + scale * ( m - a ) );
}

int invert( int n, int min, int max ) {
	return ( max - n ) + min;
}

float invert( float n, float min, float max ) {
	return ( max - n ) + min;
}
