import de.looksgood.ani.*;
import de.looksgood.ani.easing.*;
import java.util.Arrays;
import java.util.Collections;
import java.util.Calendar;
import java.util.Date;
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
// Add twist mesh
// Track is running longer than the HUD - this is due to quantize() pushing values outside the bounds
// Implement cycle of instruments (channel = channel+mod(4))
// Look at setting an on/off flag on the note and set 2 different threads to play and stop the notes
// Add more shape types
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
WB_Point[] wireframePoints;
Globe globe;
Ani globeAnimation;
float globeScale = 1.0;

Calendar startDate;
Calendar endDate;
Calendar calendar;
TimeZone timeZone;
String dateFormat;
SimpleDateFormat format;

public void settings() {
	fullScreen(P3D, 2);
	smooth(8);
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
	drawGlobe();
	drawHUD();
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

	WB_Line line = new WB_Line( 0, 0, 0, 0, exp(1.0) / 2, exp(1.0) / 2 );
	twist = new HEM_Twist().setTwistAxis( line ).setAngleFactor( TWO_PI );
}

void setupTimezone() {
	timeZone = TimeZone.getTimeZone( Configuration.Data.TimeZone );
	dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS";

	startDate = Calendar.getInstance();
	endDate = Calendar.getInstance();

	format = new SimpleDateFormat( dateFormat );

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
	globeScale = random(1.0, 1.75);
	globeAnimation.setBegin( endValue );
	globeAnimation.setEnd( globeScale );
	globeAnimation.start();
}

void setupUI() {
	// Colours are seasonal
	// Left -> Right = January - December
	colours.addAll(Arrays.asList(0xffe31826, 0xff881832, 0xff942aaf, 0xffce1a9a, 0xffffb93c, 0xff00e0c9, 0xff234baf, 0xff47b1de, 0xffb4ef4f, 0xff26bb12, 0xff3fd492, 0xfff7776d));
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
	float quantization = Configuration.MIDI.Quantization;
	float snap = beat * ( Configuration.MIDI.BeatsPerMeasure /  quantization );

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

			println( delay + ":" + quantized_delay );

			int channel = getChannelFromCoordinates( latitude, longitude );
			int velocity = mapMagnitude( magnitude );
			int pitch = mapDepth( depth );
			int duration = mapMagnitude( magnitude, Configuration.MIDI.Note.Min, Configuration.MIDI.Note.Max );
			float animationTime = mapMagnitude( magnitude, Configuration.Animation.Duration.Min, Configuration.Animation.Duration.Max );
			float scale = mapDepth( depth, Configuration.Animation.Scale.Min, Configuration.Animation.Scale.Max );
			float initialScale = mapDepth( depth, Configuration.Animation.Scale.Min, 1.0 );
			color colour = getColourFromMonth( d2 );

			WB_Point point = Geography.CoordinatesToWBPoint( latitude, longitude, Configuration.Mesh.GlobeSize );
			point.mulSelf( initialScale ) ;
			points.add( new GlobePoint( point, quantized_delay + millis(), animationTime, scale ) );
			states.add( new StateManager( d2, colour, quantize(diff/Configuration.MIDI.Acceleration) + millis() ) );

			setNote( channel, velocity, pitch, duration, quantized_delay );

			x++;
		}

		// Update the previous date to the current date for the next iteration
		previousDate = date;
	}
}

void setNote( int channel, int velocity, int pitch, int duration, long delay ) {
	// Create the note
	Note note = new Note( bus );

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

	translate( width / 2, height / 2, 0 );
	rotateY( frameCount * Configuration.Animation.Speed );
	rotateX( -frameCount * Configuration.Animation.Speed );
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

	scale( globeScale );

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
			render.drawFaces( globeMesh );
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
			stroke(colour+5, 70);
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
	WB_Point[] points = globe.getPoints( Configuration.Mesh.MaxFaces );

	Calendar currentDate = (Calendar)stateThread.getDate();
	color colour = stateThread.getColour();

	if ( currentDate != null && points.length > 4 ) {
		pushMatrix();
		drawLights( colour );
		drawRotation();
		drawMesh( colour, points );
		popMatrix();
	}
}

void drawHUD() {
	noLights();
	Calendar currentDate = (Calendar)stateThread.getDate();
	SimpleDateFormat monthFormat = new SimpleDateFormat("MMM");
	SimpleDateFormat dayFormat = new SimpleDateFormat("dd");
	SimpleDateFormat hourFormat = new SimpleDateFormat("HH");
	SimpleDateFormat minuteFormat = new SimpleDateFormat("mm");

	monthFormat.setTimeZone( timeZone );
	dayFormat.setTimeZone( timeZone );
	hourFormat.setTimeZone( timeZone );
	minuteFormat.setTimeZone( timeZone );

	if ( currentDate != null ) {

		// TO DO
		// Array list of objects that have a width, height, text object
		// Figure out how to do graph
		HUD hud = new HUD( width, height, "left", "bottom", this.font);
		hud.setMargin( 10 );
		hud.setFill( stateThread.getColour() );
		hud.setTextFill( 210 );
		hud.addElement( new HUDElement( 100, 100, getDatePart( monthFormat ).substring(0,3), "bottom", "left" ) );
		hud.addElement( new HUDElement( 100, 100, getDatePart( dayFormat ), "bottom", "left" ) );
		hud.addElement( new HUDElement( 100, 100, getDatePart( hourFormat ), "bottom", "left" ) );
		hud.addElement( new HUDElement( 100, 100, getDatePart( minuteFormat ), "bottom", "left" ) );
		hud.display();
	}
}

int getChannelFromCoordinates( double latitude, double longitude ) {
	latitude = latitude + 90;
	longitude = longitude + 180;

	for ( Rectangle rectangle : grid ) {
		Point2D.Double point = new Point2D.Double( longitude, latitude );
		if ( rectangle.contains( point ) ) {
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

int mapDepth( float depth ) {
	return invert( int( map( depth, 0, Configuration.Data.Depth.Max, Configuration.MIDI.Pitch.Min, Configuration.MIDI.Pitch.Max ) ), Configuration.MIDI.Pitch.Min, Configuration.MIDI.Pitch.Max );
}

int mapDepth( float depth, int min, int max ) {
	return invert( int( mapexp( depth, 0, 750, min, max ) ), min, max );
}

float mapDepth(float depth, float min, float max) {
	return invert( mapexp( depth, 0, 750, min, max ), min, max);
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

void saveFrames() {
	if ( Configuration.IO.SaveFrames ) {
		saveFrame("frameGrabs/frame-########.tga");
	}
}

/*


				// Major/Great earthquakes
				// Tubas
				if (magnitude >= 7) {
					note = new Note(bus);
					note.channel = 8;
					note.velocity = mapMagnitude(magnitude);
					note.pitch = mapDepth(depth);
					note.duration = 1000;

					task = new ThreadTask(note);
					timer.schedule(task, delay);
				}

				// Major/Great earthquakes
				// Kettle Drum
				// Drone
				// Tuba
				// French Horn
				// Trombone
				if (magnitude >= 8) {
					note = new Note(bus);
					note.channel = 9;
					note.velocity = 127;
					note.pitch = 36;
					note.duration = 200;


					task = new ThreadTask(note);
					timer.schedule(task, delay);

					note = new Note(bus);
					note.channel = 9;
					note.velocity = 127;
					note.pitch = 56;
					note.duration = 200;

					task = new ThreadTask(note);
					timer.schedule(task, delay);
				}


				// Small earthquakes
				if (magnitude <= 1) {
					note = new Note(bus);
					note.channel = 10;
					note.velocity = 255;
					note.pitch = mapDepth(depth, 40, 80);
					//note.duration = mapMagnitudeToLength(5000, magnitude);

					task = new ThreadTask(note);
					timer.schedule(task, delay);
				}

				// Low RMS (root-mean-square)
				if (rms < 0.01f) {
					note = new Note(bus);
					note.channel = 11;
					note.velocity = mapMagnitude(magnitude);
					note.pitch = mapDepth(depth);
					note.duration = 2000;

					task = new ThreadTask(note);
					timer.schedule(task, delay-500);

				}

				// Big RMS (root-mean-square)
				if (rms > HALF_PI) {
					note = new Note(bus);
					note.channel = 12;
					note.velocity = mapMagnitude(magnitude);
					note.pitch = mapDepth(depth);
					note.duration = 1000;

					task = new ThreadTask(note);
					timer.schedule(task, delay-500);
				}*/
