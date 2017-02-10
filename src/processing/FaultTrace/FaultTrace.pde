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

// TODO
// Place HUD over object
// Implement cycle of instruments (channel = channel+mod(4))
// Add VR support


long setupTime;
long delay;
long quantized_delay;
long start_ms;
long end_ms;
long diff_quantized_ms;
long diff_accelerated_ms;

float theta = 0;

Timer timer;
ThreadTask task;
StateManagerThread stateThread;
Note note;
MidiBus bus;

Iterable<TableRow> rows;
ArrayList<Rectangle> grid = new ArrayList();
ArrayList<Integer> colours = new ArrayList();
ArrayList<StateManager> states = new ArrayList();
ArrayList<GlobePoint> points = new ArrayList<GlobePoint>();
ArrayList<GraphPoint> graphPoints = new ArrayList<GraphPoint>();

PFont font;
HE_Mesh globeMesh;
HE_Mesh wireframeMesh;
WB_Render3D render;
WB_DebugRender3D drender;
HEC_ConvexHull creatorGlobe;
HEC_ConvexHull creatorWireframe;
HEM_Twist twist;
HEM_Lattice lattice;
HEC_Geodesic geodesic;
HEM_ChamferEdges chamfer;
HES_TriDec globeSimplifier;
WB_Point[] wireframePoints;
WB_Point[] meshPoints;
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
	smooth(8);
	//pixelDensity(2);
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
	setupSong();
	setupGlobe();
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
	diff_accelerated_ms = Configuration.MIDI.StartOffset + (((end_ms-start_ms)/Configuration.MIDI.Acceleration));
	diff_quantized_ms = Configuration.MIDI.StartOffset + quantize(((end_ms-start_ms)/Configuration.MIDI.Acceleration));
}

void setup3D() {
	creatorGlobe = new HEC_ConvexHull();
	creatorWireframe = new HEC_ConvexHull();
	lattice = new HEM_Lattice().setWidth( 20 ).setDepth( 5 );
	geodesic = new HEC_Geodesic();
	geodesic.setRadius( Configuration.Mesh.GlobeSize );
	geodesic.setB( 2 );
	geodesic.setC( 3 );
	geodesic.setType(HEC_Geodesic.ICOSAHEDRON);
	//globeSimplifier = new HES_TriDec().setGoal( 1.0 );
	WB_Line line = new WB_Line( 0, 0, 0, 0, exp(1.0) / 2, exp(1.0) / 2 );
	twist = new HEM_Twist().setTwistAxis( line ).setAngleFactor( TWO_PI );
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
	colours.addAll( Arrays.asList( 0xffe31826, 0xff881832, 0xff942aaf, 0xffce1a9a, 0xffffb93c, 0xff00e0c9, 0xff234baf, 0xff47b1de, 0xffb4ef4f, 0xff26bb12, 0xff3fd492, 0xfff7776d ) );
	uiGridWidth = Configuration.UI.GridWidth;
	uiMargin = Configuration.UI.Margin;
}

void setupFonts() {
	this.font = loadFont( Configuration.UI.HUD.Font );
}

void setupGrid() {
	for (int x = 0 ; x < 360; x += 90) {
		for (int y = 0 ; y < 180 ; y += 90) {
			grid.add(new Rectangle(x, y, 90, 90));
		}
	}
}

void setupMIDI() {
	// Create the MIDI Bus
	bus = new MidiBus( this, -1, "FaultTrace" );
}

long quantize( long delay ) {
	float beat = ( 60 * 1000 ) / (float)Configuration.MIDI.BeatsPerMinute;
	float snap = beat * ( Configuration.MIDI.BeatsPerBar /  Configuration.MIDI.BeatUnit );

	return (long)( Math.round( delay/snap ) * snap );
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
			float scale = mapDepth( depth, Configuration.Animation.Scale.Min, Configuration.Animation.Scale.Max );
			float initialScale = mapDepth( depth, Configuration.Animation.Scale.Min, 1.0 );
			color colour = getColourFromMonth( d2 );

			WB_Point point = Geography.CoordinatesToWBPoint( latitude, longitude, Configuration.Mesh.GlobeSize, depth );
			point.mulSelf( initialScale ) ;
			points.add( new GlobePoint( point, quantized_delay + millis(), animationTime, scale ) );
			graphPoints.add( new GraphPoint( delay + millis(), magnitude ) );

			states.add( new StateManager( d2, colour, (long)(diff/Configuration.MIDI.Acceleration) ) );

			setNote( channel, velocity, pitch, duration, quantized_delay );

			// Drone
			if ( magnitude >= 4 ) {
				setNote( 8, velocity, 0, (int)(quantize( diff / Configuration.MIDI.Acceleration ) * Configuration.MIDI.BeatsPerBar), quantized_delay );
			}

			// Sub Bass
			if ( magnitude >= 7 ) {
				setNote( 9, velocity, 0, (int)(quantize( diff / Configuration.MIDI.Acceleration ) * Configuration.MIDI.BeatsPerBar), quantized_delay );
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
	println("Time Signature: " + Configuration.MIDI.BeatsPerBar + "/" + Configuration.MIDI.BeatUnit);
	println("Estimated song length: " + (float)diff_accelerated_ms/1000 + " seconds // "+ diff_accelerated_ms/1000/60 + " minutes // " + diff_accelerated_ms/1000/60/60 + " hours // " + diff_accelerated_ms/1000/60/60/24 + " days");
	println("Total " + diff_accelerated_ms + "ms");
	println("Quantized " + diff_quantized_ms + "ms");
	println("Setup lasted " + setupTime + "ms");
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
	background( 225, 225, 230 );
}

void drawLights( color colour ) {
	ambient(colour);
	directionalLight( red( colour ), green( colour ), blue( colour ), 1, 1, -1 );
	pointLight( red( colour ), green( colour ), blue( colour ), width * 0.8, height * 0.8, 0 );
	shininess(100.0);
}

void drawRotation() {
	// Move
	theta += Configuration.Animation.Speed;

	translate( width / 2, ( height / 2 ), 0 );
	rotateY( theta );
}

void drawMesh( color colour, WB_Point[] points ) {
	creatorGlobe.setPoints( points );
	globeMesh = new HE_Mesh( creatorGlobe );

	if ( Configuration.Mesh.Type == MeshType.Dual ) {
		globeMesh = new HE_Mesh( new HEC_Dual( globeMesh ) );
	}

	if ( Configuration.Mesh.Type == MeshType.Lattice ) {
		globeMesh.modify( lattice );
	}

	if ( Configuration.Mesh.Type == MeshType.Twisted ) {
		globeMesh.modify( twist );
	}

	//globeMesh.simplify( globeSimplifier );

	if ( Configuration.Mesh.ShowWireframe ) {
		wireframeMesh = new HE_Mesh( geodesic );
		stroke( 240 );
		render.drawEdges( wireframeMesh );
	}

	stroke(colour+5, 70);
	fill(colour);

	switch ( Configuration.Mesh.Renderer ) {
		case Edges:
			noFill();
			render.drawEdges( globeMesh );
			break;
		case Faces:
			noStroke();
			render.drawMesh( globeMesh );
			break;
		case EdgesFaces:
			render.drawEdges( globeMesh );
			render.drawFaces( globeMesh );
			break;
		case Points:
			render.drawPoints( globeMesh.getPoints(), 2 );
			break;
		case EdgesPoints:
			noFill();
			render.drawEdges( globeMesh );
			render.drawPoints( globeMesh.getPoints(), 2 );
			break;
		case EdgesFacesPoints:
			stroke(colour+2, 70);
			render.drawEdges( globeMesh );
			render.drawPoints( globeMesh.getPoints(), 4 );
			noStroke();
			render.drawFaces( globeMesh );
			break;
		default:
			break;
	}
}

void drawGlobe() {
	meshPoints = globe.getPoints( Configuration.Mesh.MaxFaces );

	currentDate = (Calendar)stateThread.getDate();
	colour = stateThread.getColour();

	if ( currentDate != null && meshPoints.length > 4 ) {
		drawLights( colour );
		drawRotation();
		drawMesh( colour, meshPoints );
	}
}

void drawGraph() {
	Calendar currentDate = (Calendar)stateThread.getDate();

	if ( currentDate != null ) {
		graph = new Graph( graphPoints, width, height, (uiGridWidth*4) + (uiMargin*3), uiGridWidth, "right", "bottom" );
		graph.setMargin( uiMargin );
		graph.setFill( stateThread.getColour() );
		graph.setLineStroke( 210 );
		graph.getPoints( (uiGridWidth*4) + (uiMargin*3) );
		graph.display();
	}
}

void drawHUD() {
	Calendar currentDate = (Calendar)stateThread.getDate();

	if ( currentDate != null ) {

		// TO DO
		// Array list of objects that have a width, height, text object
		// Figure out how to do graph
		hud = new HUD( width, height, "left", "bottom", this.font);
		hud.setMargin( uiMargin );
		hud.setFill( stateThread.getColour() );
		hud.setTextFill( 210 );
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
	Calendar nextMonth = (Calendar)date.clone();
	nextMonth.add( Calendar.MONTH, 1 );

	int daysinmonth = date.getActualMaximum( Calendar.DAY_OF_MONTH );

	return lerpColor( color( colours.get( date.get( Calendar.MONTH ) ) ), color( colours.get( nextMonth.get(Calendar.MONTH) ) ), (float)date.get(Calendar.DAY_OF_MONTH)/daysinmonth
	);
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
