import com.hamoid.*;
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
import java.util.*;
import themidibus.*;
import toxi.geom.*;
import wblut.geom.*;
import wblut.hemesh.*;
import wblut.math.*;
import wblut.processing.*;

long setupTime;
long delay;
long quantized_delay;
long loopTime;
long loopDuration;
long start_ms;
long end_ms;
long diff_quantized_ms;
long diff_accelerated_ms;
long startTime;

float theta = radians(180);
float phi = 0.0;

Timer timer;
ThreadTask task;
StateManagerThread stateThread;
Note note;
MidiBus bus;
boolean is2D;

Iterable<TableRow> rows;
ArrayList<Rectangle> grid = new ArrayList();
ArrayList<Integer> colours = new ArrayList();
ArrayList<Integer> lightColours = new ArrayList();
ArrayList<StateManager> states = new ArrayList();
ArrayList<GlobePoint> points = new ArrayList<GlobePoint>();
ArrayList<GraphPoint> graphPoints = new ArrayList<GraphPoint>();
ArrayList<ArrayList<WB_Point5D>> segments = new ArrayList<ArrayList<WB_Point5D>>();
ArrayList<ArrayList<WB_Point5D>> segments5D = new ArrayList<ArrayList<WB_Point5D>>();
ArrayList<Float> amplitudes = new ArrayList<Float>();
ArrayList<Float> amplitudesSmoothed = new ArrayList<Float>();
ArrayList<NoteStub> stubs = new ArrayList<NoteStub>();
ArrayList<String> uuids = new ArrayList<String>();

PFont font;
HE_Mesh globeMesh;
HE_Mesh wireframeMesh;
WB_Render3D render;
HEC_ConvexHull creatorGlobe;
HEM_Twist twist;
HEM_Lattice lattice;
HEMC_VoronoiCells voronoi;
HE_MeshCollection meshCollection;
HEM_Extrude extrude;
HEC_Geodesic geodesic;
HEC_Sphere sphere;

WB_Point5D[] meshPoints;
WB_Point5D[] meshPoints5D;
WB_Point wbPoint;
WB_Point5D segmentPoint;
WB_Point5D segmentPoint5D;
Globe globe;
Graph graph;
Ani globeAnimation;
Ani globeOffsetAnimation;
float globeScale = 1.0;
float globeOffset = 1.0;
boolean isHeMeshRenderer = false;
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
color colour, background;
HUD hud;
Point2D.Double rectanglePoint;
int uiGridWidth;
int uiMargin;
NoteStub stub;

//renderRings()
int levels;
int level;
float wf, xf, yf, zf;
int opacity = 150;
int k, j, x, y, z;
float eased_y;
float radius;
float mid, r2, x2, y2;
double deg = 0.0;
float xf2, yf2, zf2, wf2, d2, xf3, yf3, zf3, xoff, yoff;
float axf, ayf, azf, nxf, nyf, nzf;
float amplitude, mf;

//renderPoints
float interval;
WB_Point4D trail;

//renderSpikes
float step;
float distance;
float azimuth;
float elevation;

//renderPetals
PVector[] controlPoints;
PVector a, b;
BezierCurve curve;

//renderExplosions
PGL pgl;
Images images;
Emitter emitter;
ArrayList<Emitter> emitters;
float floorLevel;
Vec3D gravity;
int counter;

//quantize()
int type;
float milliseconds_per_beat = ( 60 * 1000 ) / (float)Configuration.MIDI.BeatsPerMinute;
float milliseconds_per_measure = milliseconds_per_beat * Configuration.MIDI.BeatsPerBar;
float milliseconds_per_note;
int barLength = int(milliseconds_per_beat * Configuration.MIDI.BeatsPerBar);

PShader pointShader;
VideoExport videoExport;
boolean isExporting = false;

public void settings() {
	size(1920, 1080, Configuration.UI.Mode);
	smooth(4);
	pixelDensity(2);
}

void setup() {
	setupTimezone();
	setupTiming();
	setup2D();
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
	setupInfo();
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
	diff_accelerated_ms = Configuration.MIDI.StartOffset + ( ( ( end_ms-start_ms )/Configuration.MIDI.TimeCompression ) );
	diff_quantized_ms = Configuration.MIDI.StartOffset + quantize( ( ( end_ms-start_ms ) / Configuration.MIDI.TimeCompression ), 0 );
}

void setup2D() {
	is2D = (Configuration.Mesh.Renderer == RenderType.PulsarSignal);
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

	sphere = new HEC_Sphere();
	sphere.setRadius( Configuration.Mesh.GlobeSize );
	sphere.setUFacets( 40 );
	sphere.setVFacets( 40 );


	images = new Images();
	gravity = new Vec3D( 0, .7, 0 );
	emitter = new Emitter();
	floorLevel = 400;
	emitters = new ArrayList<Emitter>();
	pgl = ((PGraphicsOpenGL) g).pgl;

	if (Configuration.Mesh.Renderer == RenderType.Explosions) {
		colorMode( RGB, 1.0 );
	}
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
	globeOffsetAnimation = new Ani(this, Configuration.Animation.Zoom.Time, "globeOffset", globeOffset, Ani.QUAD_IN_OUT, "onEnd:setGlobeOffset");
}

void setGlobeScale() {
	float endValue = globeAnimation.getEnd();
	globeScale = random( 0.8, 2.5 );
	globeAnimation.setBegin( endValue );
	globeAnimation.setEnd( globeScale );
	globeAnimation.start();
}

void setGlobeOffset() {
	float endValue = globeOffsetAnimation.getEnd();
	globeOffset = random( -100, 100 );
	globeOffsetAnimation.setBegin( endValue );
	globeOffsetAnimation.setEnd( globeOffset );
	globeOffsetAnimation.start();
}

void setupUI() {
	uiGridWidth = Configuration.UI.GridWidth;
	uiMargin = Configuration.UI.Margin;
}

void setupFonts() {
	this.font = loadFont( Configuration.UI.HUD.Font );
}

void setupGrid() {
	int rows = 2;

	while (Configuration.MIDI.Channels % rows > 0) {
		rows++;
	}

	int columns = Configuration.MIDI.Channels / rows;
	int squareWidth = (360/rows);
	int squareHeight = (180/columns);

	for ( int y = 0 ; y < 180 ; y += squareHeight ) {
		for ( int x = 0 ; x < 360; x += squareWidth ) {
			grid.add( new Rectangle( x, y, squareWidth, squareHeight ) );
		}
	}
}

void setupMIDI() {
	// Create the MIDI Bus
	bus = new MidiBus( this, -1, "FaultTrace" );
}

long quantize( long delay, int channel ) {
	int barType = 0;

	for ( x = 0 ; x < Configuration.MIDI.BarToChannel.length ; x++ ) {
		for ( y = 0 ; y < Configuration.MIDI.BarToChannel[x].length ; y++ ) {
			// Channel is 0 based
			if ( Configuration.MIDI.BarToChannel[x][y] == (channel+1) ) {
				barType = x;
			}
		}
	}

	//
	if (Configuration.MIDI.ModuloNotes) {
		// This takes a beat from the modulo of the delay and the beats per bar and the note type, using the same notes but not sequentially, giving the song a more varied feel
		type =  (int)(( delay % Configuration.MIDI.BeatsPerBar ) % Configuration.MIDI.NoteType[ barType ].length );
	} else {
		// This cycles through each note sequentially
		type = (int)(delay / milliseconds_per_beat) % Configuration.MIDI.NoteType[ barType ].length;
	}

	milliseconds_per_note = milliseconds_per_beat * ( Configuration.MIDI.BeatNoteValue / Configuration.MIDI.NoteType[ barType ][ type ].toFloat());
	return (long)(Math.round( delay / milliseconds_per_note ) * milliseconds_per_note);
}

// TODO
// - Duration to come from quantization
// - quantize() to come from BeatNoteValue

int quantize_duration( long channel ) {
	int barType = 0;

	for ( x = 0 ; x < Configuration.MIDI.BarToChannel.length ; x++ ) {
		for ( y = 0 ; y < Configuration.MIDI.BarToChannel[x].length ; y++ ) {
			// Channel is 0 based
			if ( Configuration.MIDI.BarToChannel[x][y] == (channel+1) ) {
				barType = x;
			}
		}
	}

	if (Configuration.MIDI.ModuloNotes) {
		// This takes a beat from the modulo of the delay and the beats per bar and the note type, using the same notes but not sequentially, giving the song a more varied feel
		type =  (int)(( delay % Configuration.MIDI.BeatsPerBar ) % Configuration.MIDI.NoteType[ barType ].length );
	} else {
		// This cycles through each note sequentially
		type = (int)(delay / milliseconds_per_beat) % Configuration.MIDI.NoteType[ barType ].length;
	}

	// TODO
	milliseconds_per_note = milliseconds_per_beat * ( Configuration.MIDI.BeatNoteValue / Configuration.MIDI.NoteType[ barType ][ type ].toFloat());
	return (int)milliseconds_per_note;
}

void setupSong() {
	// Set the delay between notes
	delay = Configuration.MIDI.StartOffset;
	startTime = millis();
	quantized_delay = quantize(delay, 0);

	// CSV
	double latitude, longitude;
	float depth, magnitude, rms, dmin;

	String date;
	String previousDate = null;

	Calendar d1 = Calendar.getInstance();
	Calendar d2 = Calendar.getInstance();

	d1 = (Calendar)startDate.clone();

	int x = 0;

	loopTime = millis();
	loopDuration = millis();

	for (TableRow row : rows ) {
		// Extract the data
		date = row.getString("time");
		latitude = row.getDouble("latitude");
		longitude = row.getDouble("longitude");
		depth = row.getFloat("depth");
		magnitude = row.getFloat("mag");
		rms = row.getFloat("rms");
		dmin = row.getFloat("dmin");
		loopTime = millis() - loopDuration;

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
			delay += (diff/Configuration.MIDI.TimeCompression);

			int channel = getChannelFromCoordinates( latitude, longitude );
			int velocity = mapMagnitude( magnitude, Configuration.MIDI.Velocity.Min, Configuration.MIDI.Velocity.Max );
			int pitch = mapDepth( depth );
			int duration = quantize_duration( channel ); //mapMagnitude( magnitude, Configuration.MIDI.Note.Min, Configuration.MIDI.Note.Max );
			float animationTime = mapMagnitude( magnitude, Configuration.Animation.Duration.Min, Configuration.Animation.Duration.Max );
			float scale = mapMagnitude( magnitude, Configuration.Animation.Scale.Min, Configuration.Animation.Scale.Max );
			//float scale = Configuration.Animation.Scale.Max;
			//float scale = mapDepth( depth, Configuration.Animation.Scale.Min, Configuration.Animation.Scale.Max );
			float distance = mapexp( depth, 0, Configuration.Data.Depth.Max, Configuration.Data.Distance.Min, Configuration.Data.Distance.Max );
			//float distance = map(rms, 0.0, 2.5, 0, (Configuration.Palette.Mesh.Petals.length - 1));
			float mag = map( magnitude, 0.0, 10.0, 1.00, 1.05 );
			color colour = getColourFromMonth( d2 );
			color background = getBackgroundFromMonth( d2 );

			quantized_delay = quantize(delay, channel);

			if ( is2D ) {
				wbPoint = Geography.CoordinatesTo2DWBPoint( latitude, longitude, Configuration.Mesh.PulsarSignal.Width, Configuration.Mesh.PulsarSignal.Height );
			}
			else {
				wbPoint = Geography.CoordinatesToWBPoint( latitude, longitude, scale, Configuration.Mesh.GlobeSize );
			}

			GlobePoint newPoint = new GlobePoint( wbPoint );
			GlobePoint existingPoint = globe.getExistingPoint( newPoint );

			if ( Configuration.Optimisations.GroupPoints && existingPoint != null ) {
				existingPoint.addDelay( quantized_delay + millis() - Configuration.MIDI.AnimationOffset);
				existingPoint.addAnimationTime( animationTime );
				existingPoint.addDefaultScale( Configuration.Animation.Scale.Default );
				existingPoint.addScale( scale );
				existingPoint.addAnimation( scale, distance, animationTime );
				existingPoint.addDistance( distance );
				existingPoint.addMagnitude( mag );

				// If you do not want to tween distance or scale, call these methods
				// existingPoint.setTweenScale( false );
				existingPoint.setTweenDistance( false );
			}
			else {
				newPoint.addDelay( quantized_delay + millis() - Configuration.MIDI.AnimationOffset);
				newPoint.addAnimationTime( animationTime );
				newPoint.addScale( scale );
				newPoint.addDefaultScale( Configuration.Animation.Scale.Default );
				newPoint.addAnimation( scale, distance, animationTime );
				newPoint.addDistance( distance );
				newPoint.addMagnitude( mag );
				// If you do not want to tween distance or scale, call these methods
				// newPoint.setTweenScale( false );
				newPoint.setTweenDistance( false );
				points.add( newPoint );
			}

			graphPoints.add( new GraphPoint( delay + millis(), magnitude ) );
			states.add( new StateManager( d2, colour, background, (long)(diff/Configuration.MIDI.TimeCompression) ) );

			if ( !isDuplicateNote( quantized_delay, channel ) ) {
				setNote( channel, velocity, pitch, duration, quantized_delay );
				stub = new NoteStub( quantized_delay, channel );
				stubs.add( stub );
			}
			else {
				y++;
			}

			x++;
		}

		// Conditional based
		if ( magnitude > 6.5 ) {
			setNote( 9, 80, 60, 9000, quantized_delay );
		}

		// Conditional based
		if ( magnitude > 7.25 ) {
			setNote( 10, 80, 60, 9000, quantized_delay );
		}

		// Update the previous date to the current date for the next iteration
		previousDate = date;
		loopDuration = millis();
	}

	startTime = millis() - startTime;
}

boolean isDuplicateNote( long delay, int channel ) {
	for ( x = 0 ; x < stubs.size(); x++ ) {
		stub = stubs.get(x);
		if ( stub.delay == delay && stub.channel == channel ) {
			return true;
		}
	}

	return false;
}

void setNote( int channel, int velocity, int pitch, int duration, long delay ) {
	if (!Configuration.MIDI.SilentRunning) {
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

		// Time until note is played, this is to prevent duplicate notes playing at the same time causing out of phase weirdness
		note.delay = delay;

		// Add the note to task schedule
		timer.schedule( new ThreadTask(note), delay );
	}
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
	isHeMeshRenderer = Configuration.Mesh.Renderer.toBoolean();
}

void setupInfo() {
	println("Tempo: " + Configuration.MIDI.BeatsPerMinute + " BPM");
	println("Time Signature: " + Configuration.MIDI.BeatsPerBar + "/" + Configuration.MIDI.BeatNoteValue);
	println("Bar Length: " + barLength + "ms");
	println("Estimated song length: " + (float)diff_accelerated_ms/1000 + " seconds // "+ diff_accelerated_ms/1000/60 + " minutes // " + diff_accelerated_ms/1000/60/60 + " hours // " + diff_accelerated_ms/1000/60/60/24 + " days");
	println("Total " + diff_accelerated_ms + "ms");
	println("Quantized " + diff_quantized_ms + "ms");
	println("Total Data Points: " + points.size() );

	for ( x = 0; x < Configuration.MIDI.NoteType.length ; x++ ) {
		float sum = 0.0;
		for ( y = 0 ; y < Configuration.MIDI.NoteType[x].length ; y++ ) {
			sum += Configuration.MIDI.BeatNoteValue/Configuration.MIDI.NoteType[x][y].toFloat();
		}
		println("Note value sum for channels (" + join(nf(Configuration.MIDI.BarToChannel[x], 0), ", ") + ") "  + sum + " (expected " + Configuration.MIDI.BeatsPerBar + ")");
	}
}

String getDatePart( SimpleDateFormat dateFormat ) {
	long start = startDate.getTimeInMillis();
	long end = endDate.getTimeInMillis();
	long diff = start+(((long)millis()-setupTime)*Configuration.MIDI.TimeCompression);

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
	background = stateThread.getBackground();
	background( background );
}

void drawLights( color colour ) {
	directionalLight( red(Configuration.Palette.Lights.Outside), green(Configuration.Palette.Lights.Outside), blue(Configuration.Palette.Lights.Outside), -1, 0, -1);
}

void drawRotation() {
	// Move
	theta += Configuration.Animation.Speed;

	if (!is2D) {
		translate( width / 2, ( height / 2 ), 0 );
		//rotateY( theta );
		//rotateX( radians(-23.5) );
	}
}

void drawMesh( color colour, WB_Point5D[] points ) {
	hint(ENABLE_DEPTH_TEST);

	if ( isHeMeshRenderer ) {
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
			renderPoints( points );
			break;
		case EdgesPoints:
			renderEdgesPoints( globeMesh );
			break;
		case EdgesFacesPoints:
			renderEdgesFacesPoints( globeMesh );
			break;
		case Particles:
			renderParticles( points );
			break;
		case Rings:
			renderRings( points );
			break;
		case Explosions:
			renderExplosions( points );
			break;
		case Meteors:
			renderMeteors( points );
			break;
		case Plasma:
			renderPlasma( points );
			break;
		case PulsarSignal:
			renderPulsarSignal( points );
			break;
		case Waves:
			renderWaves( points );
			break;
		case Spikes:
			renderSpikes( points );
			break;
		case Petals:
			renderPetals( points );
			break;
		default:
			break;
	}
}

void renderWaves( WB_Point5D[] points ) {
	pushMatrix();
	translate( 0, (height / 2) - ((levels*Configuration.Mesh.Waves.Distance)/2), 300);
	rotateX(radians(6));
	rotateY(radians(-23));

	levels = Configuration.MIDI.Channels;

	amplitudes.clear();
	amplitudesSmoothed.clear();
	segments5D.clear();

	for ( x = 0 ; x < levels; x++ ) {
		segments5D.add(new ArrayList<WB_Point5D>());
	}

	for ( x = 0 ; x < levels * Configuration.Mesh.Waves.Density ; x++ ) {
		amplitudes.add(0.0);
	}

	// Add points
	for ( WB_Point5D point : points ) {
		mf = point.mf();

		int base = floor(mf);
		segments5D.get(base).add(point);
	}

	// Get the amplitudes for each row
	for ( y = 0 ; y < levels; y++ ) {
		amplitude = 0.0;

		for ( z = 0 ; z < segments5D.get(y).size(); z++ ) {
			segmentPoint5D = segments5D.get(y).get(z);
			wf = segmentPoint5D.wf();
			amplitude += wf;
		}

		amplitudes.set(y, amplitude);
	}

	levels *= Configuration.Mesh.Waves.Density;

	float nextAmplitude;
	float previousAmplitude;

	for ( x = 0 ; x < levels ; x++ ) {
		amplitude = amplitudes.get(x);
		nextAmplitude = (x+1) < levels ? amplitudes.get(x+1) : 0;
		for ( y = 0 ; y < Configuration.Mesh.Waves.Density; y++ ) {
			amplitudesSmoothed.add(lerp(amplitude, nextAmplitude, (float)y/Configuration.Mesh.Waves.Density));
		}
	}


	float dx = (TWO_PI / (width/Configuration.Mesh.Waves.WaveLength)) * Configuration.Mesh.Waves.Step;

	for ( y = 0 ; y < levels; y++ ) {
		amplitude = amplitudesSmoothed.get(y);
		noFill();

		xf = phi + y + (amplitude/Configuration.Data.Distance.Max);
		xf2 = xf;
		yf2 = y*Configuration.Mesh.Waves.Distance;

		for ( k = 0; k <= width; k+=Configuration.Mesh.Waves.Step ) {
			strokeWeight( 4.25 );

			xf2 = k + sin(xf);
			yf2 = (sin(xf)*amplitude) + (y*Configuration.Mesh.Waves.Distance);
			zf2 = 0;//(sin(xf)*amplitude);

			stroke( lerpColor( Configuration.Palette.Mesh.Waves[0], Configuration.Palette.Mesh.Waves[1], amplitude/Configuration.Data.Distance.Max ) );
			point( xf2, yf2, zf2 );

			xf += dx;
		}
	}

	phi += Configuration.Mesh.Waves.Velocity;

	popMatrix();
	hint(DISABLE_DEPTH_TEST);
}

void renderPulsarSignal( WB_Point5D[] points ) {
	hint(DISABLE_OPTIMIZED_STROKE);
	int offset = 0;
	translate( width / 2 - Configuration.Mesh.PulsarSignal.Width / 2, height / 2 - Configuration.Mesh.PulsarSignal.Height / 2 - offset );
	levels = (Configuration.Mesh.PulsarSignal.Height / Configuration.Mesh.PulsarSignal.Distance);

	segments5D.clear();

	for ( x = 0 ; x < levels ; x++ ) {
		segments5D.add(new ArrayList<WB_Point5D>());
	}

	for ( WB_Point5D point : points ) {
		yf = point.yf();
		level = (int)Math.floor(yf / Configuration.Mesh.PulsarSignal.Distance);
		segments5D.get((level < 0) ? 0 : level).add(point);
	}

	level = 0;
	xoff = 0;

	float barrier = 0.25;

	for ( y = Configuration.Mesh.PulsarSignal.Distance ; y < Configuration.Mesh.PulsarSignal.Height; y+=Configuration.Mesh.PulsarSignal.Distance ) {
		strokeWeight(2);
		stroke( Configuration.Palette.Mesh.Line );
		fill( background );
		beginShape();
		vertex(0, y);

		mid = (Configuration.Mesh.PulsarSignal.Width/2) - (map(noise(y, yoff, random(0.0, 0.005)), 0, 1, -(Configuration.Mesh.PulsarSignal.Width*barrier), (Configuration.Mesh.PulsarSignal.Width*barrier)));
		float xoffvalue = map(noise(y, yoff), 0, 1, 5, 75.0);
		float y3;
		y2 = y;

		for ( z = 0 ; z < segments5D.get(level).size(); z++ ) {
			segmentPoint = segments5D.get(level).get(z);
			wf = segmentPoint.wf();
			xoffvalue += wf;
		}

		for ( k = 0; k <= Configuration.Mesh.PulsarSignal.Width; k+=Configuration.Mesh.PulsarSignal.Step ) {
			float noise = random(0, 5);
			float percentile = (k<mid) ? ((float)k/mid) : 1.0-(((float)k-mid)/(Configuration.Mesh.PulsarSignal.Width-mid));

			y3 = noise;

			if (percentile > barrier) {
				percentile = mapexp(percentile, barrier, 1.0, 0.01, 1.0);
				y3 = (xoffvalue * percentile) + noise;
			}

			y2 = y;
			y2 -= map(noise(xoff, yoff), 0, 1, -2, y3);

			vertex( k, y2 );
			xoff += 0.06;
		}

		vertex( Configuration.Mesh.PulsarSignal.Width, y );
		vertex( Configuration.Mesh.PulsarSignal.Width, Configuration.Mesh.PulsarSignal.Height );
		vertex( 0, Configuration.Mesh.PulsarSignal.Height );

		endShape(CLOSE);

		level++;
	}
	yoff += 0.005;

	strokeWeight( 4 );
	stroke( background );
	noFill();

	beginShape();
	vertex(0, 0);
	vertex(0, Configuration.Mesh.PulsarSignal.Height);
	vertex(Configuration.Mesh.PulsarSignal.Width, Configuration.Mesh.PulsarSignal.Height);
	vertex(Configuration.Mesh.PulsarSignal.Width, 0);
	endShape();
	hint(ENABLE_OPTIMIZED_STROKE);
}

void renderPoints( WB_Point5D[] points ) {
	blendMode(ADD);
	strokeWeight(3.5);
	stroke(Configuration.Palette.Mesh.Line, 100);
	for ( WB_Point5D point : points ) {
		point(point.xf(), point.yf(), point.zf());
	}
	blendMode(NORMAL);
}

void renderPetals( WB_Point5D[] points ) {
	noStroke();
	b = new PVector(0, 0, 0);
	x = 0;

	fill( Configuration.Mesh.Petals.Sphere );
	sphere( 140 );
	//blendMode( ADD );

	for ( WB_Point5D point : points ) {
		fill(Configuration.Palette.Mesh.Petals[ floor(point.mf()) ], 110);
		a = new PVector(point.xf(), point.yf(), point.zf());
		curve = new BezierCurve(a, b);
		controlPoints = curve.getControlPoints();
		pushMatrix();

		//azimuth = atan2(point.yf(), point.xf());
		//elevation = atan2(sqrt(sq(point.xf()) + sq(point.yf())), point.zf());

		//rotateZ(azimuth);
		//rotateY(elevation);
		//rotateX(radians(point.wf()));
		//rotateY(point.wf());


		//rotateY(radians(point.mf()));
		//rotate(point.mf());
		//rotateZ(radians(x));
		//println(controlPoints[0].x + ":" + controlPoints[0].y + ":" + controlPoints[0].z + "-" + controlPoints[1].x + ":" + controlPoints[1].y + ":" + controlPoints[1].z + "-" + controlPoints[2].x + ":" + controlPoints[2].y + ":" + controlPoints[2].z + "-" + controlPoints[3].x + ":" + controlPoints[3].y + ":" + controlPoints[3].z);
		bezier(controlPoints[0].x, controlPoints[0].y, controlPoints[0].z, controlPoints[1].x, controlPoints[1].y, controlPoints[1].z, controlPoints[2].x, controlPoints[2].y, controlPoints[2].z, controlPoints[3].x, controlPoints[3].y, controlPoints[3].z);

		curve = new BezierCurve(b, a);
		controlPoints = curve.getControlPoints();
		bezier(controlPoints[0].x, controlPoints[0].y, controlPoints[0].z, controlPoints[1].x, controlPoints[1].y, controlPoints[1].z, controlPoints[2].x, controlPoints[2].y, controlPoints[2].z, controlPoints[3].x, controlPoints[3].y, controlPoints[3].z);
		popMatrix();
		x++;

		if (x == Configuration.Palette.Mesh.Petals.length) {
			x = 0;
		}
	}

	blendMode(NORMAL);
}

void renderSpikes( WB_Point5D[] points ) {
	noStroke();
	//strokeWeight(1.0);
	WB_Point4D endpoint;


	fill(Configuration.Palette.Mesh.Line);
	sphereDetail(90);
	sphere(Configuration.Mesh.GlobeSize);

	blendMode(MULTIPLY);

	x = 0;

	for ( WB_Point5D point : points ) {
		endpoint = point.mul(point.wf());
		float b = (points.length < Configuration.Mesh.Spikes.LerpSteps) ? points.length : Configuration.Mesh.Spikes.LerpSteps;
		float c = (x > points.length-b) ? ((points.length-x)/b) : 1.0;

		fill(lerpColor(color(30, 30, 30), Configuration.Palette.Mesh.Line, c), 110);
		pushMatrix();
		translate(point.xf(), point.yf(), point.zf());

		azimuth = atan2(endpoint.yf(), endpoint.xf());
		elevation = atan2(sqrt(sq(endpoint.xf()) + sq(endpoint.yf())), endpoint.zf());

		rotateZ(azimuth);
		rotateY(elevation);

		drawSpike(Configuration.Mesh.Spikes.Sides, point.mf(), 0, dist(0, 0, 0, endpoint.xf(), endpoint.yf(), endpoint.zf()));

		popMatrix();
		x++;
	}

	blendMode(NORMAL);

	theta += points.length / 10000;
}

void drawSpike( int sides, float r1, float r2, float h )
{
	float angle = 360 / sides;
	// top
	beginShape();
	for (int i = 0; i < sides; i++) {
		float x = cos( radians( i * angle ) ) * r1;
		float y = sin( radians( i * angle ) ) * r1;
		vertex( x, y, 0 );
	}
	endShape(CLOSE);
	// bottom
	beginShape();
	for (int i = 0; i < sides; i++) {
		float x = cos( radians( i * angle ) ) * r2;
		float y = sin( radians( i * angle ) ) * r2;
		vertex( x, y, h );
	}
	endShape(CLOSE);
	// draw body
	beginShape(TRIANGLE_STRIP);
	for (int i = 0; i < sides + 1; i++) {
		float x1 = cos( radians( i * angle ) ) * r1;
		float y1 = sin( radians( i * angle ) ) * r1;
		float x2 = cos( radians( i * angle ) ) * r2;
		float y2 = sin( radians( i * angle ) ) * r2;
		vertex( x1, y1, 0 );
		vertex( x2, y2, h );
	}
	endShape(CLOSE);
}

void renderExplosions( WB_Point5D[] points ) {
	noStroke();
	fill( Configuration.Palette.Mesh.Faces, 0.4 );
	sphereDetail( 60 );
	sphere( Configuration.Mesh.GlobeSize );

	stroke( Configuration.Palette.Mesh.Line, 0.085 );
	strokeWeight(2.4);

	pgl.depthMask( false );
	pgl.enable( PGL.BLEND );
	pgl.blendFunc( PGL.SRC_ALPHA, PGL.ONE );

	for ( WB_Point5D point : points ) {
		WB_Point4D endpoint = point.mul(point.mf());
		line(point.xf(), point.yf(), point.zf(), endpoint.xf(), endpoint.yf(), endpoint.zf());

		if (point.wf() >= 1.0) {
			if (!uuids.contains(point.getUUID())) {
				uuids.add(point.getUUID());
				emitter.addParticles( int(20 * point.wf()), point);
				counter++;
			}
		}
	}

	emitter.exist();
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

void renderMeteors( WB_Point5D[] points ) {
	hint(ENABLE_DEPTH_TEST);
	hint(ENABLE_DEPTH_SORT);
	noStroke();
	blendMode(ADD);

	fill( Configuration.Palette.Mesh.Faces, 10 );
	sphereDetail( 40 );
	sphere( Configuration.Mesh.GlobeSize );
	sphere( Configuration.Mesh.GlobeSize * .9 );

	noFill();
	y = 0;
	for ( WB_Point5D point : points ) {
		xf = point.xf();
		yf = point.yf();
		zf = point.zf();
		wf = point.wf();
		y++;

		opacity = (int)lerp(0, Configuration.Mesh.Meteors.TrailOpacity, invert( map(wf, 0, 3, 0, 1), 0, 1) );

		if (wf > 0) {
			for ( x = 0 ; x < Configuration.Mesh.Meteors.TrailLength ; x++ ) {
				interval = lerp(0, wf, (float)x/Configuration.Mesh.Meteors.TrailLength);
				trail = point.mul( 1 + interval );

				strokeWeight(lerp(Configuration.Mesh.Meteors.Min, Configuration.Mesh.Meteors.Max, 1-(float)x/Configuration.Mesh.Meteors.TrailLength));
				stroke( Configuration.Palette.Mesh.Line, opacity);
				point(trail.xf(), trail.yf(), trail.zf());
			}
			trail = null;
		}

		opacity = Configuration.Mesh.Meteors.RestingOpacity;

		strokeWeight( Configuration.Mesh.Meteors.Max );
		stroke( Configuration.Palette.Mesh.Line, opacity);
		point(xf, yf, zf);
	}

	blendMode(NORMAL);
	hint(DISABLE_DEPTH_TEST);
	hint(DISABLE_DEPTH_SORT);
}

void renderPlasma( WB_Point5D[] points ) {
	hint(ENABLE_DEPTH_TEST);
	hint(ENABLE_DEPTH_SORT);

	noStroke();

	y = 10;
	j = 0;

	axf = 0.0;
	ayf = 0.0;
	azf = 0.0;

	for ( WB_Point5D point : points ) {
		xf = point.xf();
		yf = point.yf();
		zf = point.zf();
		wf = point.wf();

		axf += xf;
		ayf += yf;
		azf += zf;
	}

	axf = axf/points.length;
	ayf = ayf/points.length;
	azf = azf/points.length;

	nxf = (axf < 0) ? -1 : 1;
	nyf = (ayf < 0) ? -1 : 1;
	nzf = (azf < 0) ? -1 : 1;

	spotLight( red(Configuration.Palette.Lights.Left), green(Configuration.Palette.Lights.Left), blue(Configuration.Palette.Lights.Left), axf, ayf, azf, nxf, nyf, nzf, PI, 1);
	spotLight( red(Configuration.Palette.Lights.Left), green(Configuration.Palette.Lights.Left), blue(Configuration.Palette.Lights.Left), axf, ayf, azf, -nxf, -nyf, -nzf, PI/3, 12);

	pushMatrix();
	rotateY(radians(-30));
	spotLight( red(Configuration.Palette.Lights.Inside), green(Configuration.Palette.Lights.Inside), blue(Configuration.Palette.Lights.Inside), axf, ayf, azf, nxf, nyf, nzf, PI, 1);
	rotateY(radians(100));
	spotLight( red(Configuration.Palette.Lights.Inside), green(Configuration.Palette.Lights.Inside), blue(Configuration.Palette.Lights.Inside), axf, ayf, azf, -nxf, -nyf, -nzf, PI/3, 12);
	popMatrix();

	pushMatrix();
	rotateX(radians(30));
	spotLight( red(Configuration.Palette.Lights.Right), green(Configuration.Palette.Lights.Right), blue(Configuration.Palette.Lights.Right), axf, ayf, azf, nxf, nyf, nzf, PI, 1);
	rotateX(radians(-100));
	spotLight( red(Configuration.Palette.Lights.Right), green(Configuration.Palette.Lights.Right), blue(Configuration.Palette.Lights.Right), axf, ayf, azf, -nxf, -nyf, -nzf, PI/3, 12);
	popMatrix();

	noStroke();
	fill( Configuration.Palette.Mesh.Faces, 250 );
	sphereDetail( 60 );
	sphere(50);
	noFill();
	curveDetail(20);
	blendMode(ADD);


	for ( WB_Point5D point : points ) {
		xf = point.xf();
		yf = point.yf();
		zf = point.zf();
		wf = point.wf();
		j++;

		strokeWeight( Configuration.Mesh.Plasma.Min );

		beginShape();
		vertex(0, 0, 0);
		xoff = 0.0;
		float xoffvalue = 0.01;

		for ( x = 0 ; x <= y ; x++ ) {
			interval = (float)x/y;

			if (interval <= wf) {
				xf2 = lerp(0.0, xf, interval);
				yf2 = lerp(0.0, yf, interval);
				zf2 = lerp(0.0, zf, interval);
				d2 = 180 * ((x<y/2) ? interval:1-interval);

				stroke( Configuration.Palette.Mesh.Plasma[ j ] );

				strokeWeight( invert( (float)map(x, y, 0, Configuration.Mesh.Plasma.Max, Configuration.Mesh.Plasma.Min ), Configuration.Mesh.Plasma.Min, Configuration.Mesh.Plasma.Max ) );

				xf3 = map(noise( sin(xf2) * PI, theta), 0, 1, xf2-d2, xf2+d2);
				yf3 = map(noise( cos(yf2) * PI, theta), 0, 1, yf2-d2, yf2+d2);
				zf3 = map(noise( tan(zf2) * PI, theta), 0, 1, zf2-d2, zf2+d2);

				curveVertex( xf3, yf3, zf3 );
				xoff += xoffvalue;
			}

			if (j == Configuration.Palette.Mesh.Plasma.length-1) {
				j = 0;
			}
		}

		curveVertex( xf3, yf3, zf3 );
		endShape();
		resetShader();

		if (wf == 1.0) {
			for ( x = 1 ; x < 10; x++ ) {
				stroke( Configuration.Palette.Mesh.Plasma[ j ], 150/x );
				strokeWeight( x );
				point(xf3, yf3, zf3);
			}
		}
	}

	noStroke();
	fill(255, 15);
	sphere(Configuration.Mesh.GlobeSize);

	hint(DISABLE_DEPTH_TEST);
	hint(DISABLE_DEPTH_SORT);
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

void renderLines( WB_Point5D[] points ) {
	for ( WB_Point5D point : points ) {
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

int getRingLevelFromPoint( WB_Point5D point ) {
	yf = point.yf();
	level = (int)Math.ceil((yf + Configuration.Mesh.GlobeSize) / Configuration.Mesh.Rings.Distance);
	return level < 0 ? 0 : level;
}

double getAngleFromVector(float xf, float zf) {
	return ((atan2(xf, zf) * ( 180 / Math.PI ) + 360) % 360);
}

float getRadiusOnYPlane( float y ) {
	return (float)Math.sqrt( Math.pow( Configuration.Mesh.GlobeSize, 2 ) - Math.pow( y, 2 ) );
}

void renderRings( WB_Point5D[] points ) {
	noFill();

	levels = ((Configuration.Mesh.GlobeSize * 2) * Configuration.Mesh.Rings.Distance);

	segments.clear();

	for ( x = 0 ; x < levels ; x++ ) {
		segments.add(new ArrayList<WB_Point5D>());
	}

	for ( WB_Point5D point : points ) {
		level = getRingLevelFromPoint( point );
		segments.get(level).add(point);
	}

	for ( y = 0-Configuration.Mesh.GlobeSize ; y < Configuration.Mesh.GlobeSize; y+=Configuration.Mesh.Rings.Distance) {
		r2 = abs((float)y/Configuration.Mesh.GlobeSize);
		eased_y = easing_cubic(r2) * (float)Configuration.Mesh.GlobeSize;

		if ( y < 0 ) {
			eased_y = -eased_y;
		}

		level = (int)((eased_y + Configuration.Mesh.GlobeSize) / Configuration.Mesh.Rings.Distance);
		radius = getRadiusOnYPlane(eased_y);

		pushMatrix();
		translate( 0, eased_y, 0 );
		rotateX(radians(-90));
		noFill();
		blendMode(ADD);
		strokeWeight(2.25);
		beginShape();


		for ( j = 0; j < 360; j+=Configuration.Mesh.Rings.RotationStep ) {
			boolean hasPoint = false;
			for ( k = 0 ; k < segments.get(level).size(); k++ ) {
				segmentPoint = segments.get(level).get(k);

				wf = segmentPoint.wf();
				xf = segmentPoint.xf();
				yf = segmentPoint.yf();
				zf = segmentPoint.zf();

				deg = getAngleFromVector(xf, zf);
				if (deg >= j && deg <= j+Configuration.Mesh.Rings.RotationStep && !hasPoint) {
					hasPoint = true;
					mid = j - (Configuration.Mesh.Rings.RotationStep/2);
					x2 = cos(radians(mid)) * (radius * wf);
					y2 = sin(radians(mid)) * (radius * wf);
					stroke( Configuration.Palette.Mesh.Line, opacity );
					vertex( x2, y2 );
				}
			}

			stroke( Configuration.Palette.Mesh.Line, opacity );
			vertex( cos(radians(j)) * radius, sin(radians(j)) * radius );
		}

		endShape(CLOSE);

		popMatrix();

		blendMode(NORMAL);
	}
}

void renderParticles( WB_Point5D[] points ) {

}

void drawGlobe() {
	meshPoints = globe.getPoints( Configuration.Mesh.MaxPoints );
	currentDate = (Calendar)stateThread.getDate();
	colour = stateThread.getColour();

	if ( currentDate != null && ((meshPoints != null && (meshPoints.length > 4 || !isHeMeshRenderer)))) {
		//drawLights( colour );
		pushMatrix();
		drawRotation();
		drawMesh( colour, meshPoints );
		popMatrix();
	} else {
		setupTime = millis();
	}
}

void drawGraph() {
	currentDate = (Calendar)stateThread.getDate();

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
	currentDate = (Calendar)stateThread.getDate();
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

color getBackgroundFromMonth( Calendar date ) {
	int daysinmonth = date.getActualMaximum( Calendar.DAY_OF_MONTH );
	return lerpColor( color( Configuration.Palette.Background.Start ), color( Configuration.Palette.Background.End ), (float)date.get(Calendar.DAY_OF_MONTH)/daysinmonth );
}

void saveFrames() {
	if ( isExporting ) {
		videoExport.saveFrame();
	}
}

void keyPressed() {
	if (key == 's') {
		isExporting = true;
		videoExport = new VideoExport(this, "../../../renders/october/render-" + day() + "-" + month() + "-" + year() + ".mp4");
		videoExport.startMovie();
	}

	if (key == 'q') {
		videoExport.endMovie();
		exit();
	}
}

int mapDepth( float depth ) {
	return invert( int( map( depth, 0, Configuration.Data.Depth.Max, Configuration.MIDI.Pitch.Min, Configuration.MIDI.Pitch.Max ) ), Configuration.MIDI.Pitch.Min, Configuration.MIDI.Pitch.Max );
}

int mapDepth( float depth, int min, int max ) {
	return invert( int( mapexp( depth, 0, Configuration.Data.Depth.Max, min, max ) ), min, max );
}

float mapDepth( float depth, float min, float max ) {
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

float easing_exp(float t) {
	return (float)1 - (float)Math.pow(2, -10 * t);
}

float easing_quadratic(float t) {
	return (float)t * (2 - t);
}

float easing_sin(float t) {
	return (float)sin(t * HALF_PI);
}

float easing_cubic(float t) {
	return (float)--t * t * t + 1;
}
