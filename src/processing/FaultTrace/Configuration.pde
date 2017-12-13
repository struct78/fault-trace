public static final class Configuration {

	public static final class Palette {
		public static final class Background {
			public static final int Start = 0xff000000;

			public static final int End = 0xff000000;
		}

		public static final class UI {

			public static final int Foreground = 0xffFAFAFA;

			public static final class Start {
				// Background colour of HUD
				public static final int Background = 0xffFF948F;
			}

			public static final class End {
				// Background colour of HUD
				public static final int Background = 0xffFF948F;
			}
		}

		public static final class Lights {
			// Left Light
			public static final int Left = 0xffED049C;

			// Inside Light
			public static final int Inside = 0xff9D31AE;

			// Right Light
			public static final int Right = 0xff16B3BA;

			// Right Light
			public static final int Outside = 0xffffffff;

			// Bottom light
			public static final int Bottom = 0xff0688D9;

			// Centre Light
			public static final int Centre = 0xffffffff;
		}

		public static final class Mesh {
			// Wireframe colour
			public static final int Wireframe = 0xff808080;

			// Face colour
			public static final int Faces = 0xff404040;

			// Line colour
			public static final int Line = 0xff29877B;

			public static final int[] Plasma = {
				0xffED049C,
				0xff0688D9,
				0xffD90265,
				0xff4B11AB,
				0xff003372,
				0xffE038B8,
				0xffB20232,
				0xffC27310
			};

			public static final int[] Waves = {
				0xff0E5159,
				0xff28E8FF
			};

			public static final int[] Petals = {
				0xff3E606F,
				0xff00A388,
				0xff79BD8F,
				0xff88A34F,
				0xffBEEB9F,
				0xffF2EBBF,
				0xffE8476D,
				0xffF0433A,
				0xffF24C27,
				0xffFF6138
			};
		}
	}

	public static final class MIDI {
		// Approximate time to parse CSV file (milliseconds)
		public static final long StartOffset = 3000;

		// If you're using an easing type such as elastic or bounce, you will need to adjust
		// this value to sync objects colliding
		public static final long AnimationOffset = 0;

		// Time compression
		public static final long TimeCompression = 4000;

		// BPM for time quantization
		public static final int BeatsPerMinute = 180;

		// Beats per bar X/4
		public static final float BeatsPerBar = 16;

		// 4/X
		public static final float BeatNoteValue = 8;

		// Bar structure
		public static final QuantizationType[][] NoteType = new QuantizationType[][] {
			// 2
			new QuantizationType[] {
				QuantizationType.OneHalfNote,
				QuantizationType.OneHalfNote,
				QuantizationType.OneHalfNote,
				QuantizationType.OneHalfNote,
			},

			// 3
			new QuantizationType[] {
				QuantizationType.OneEighthNoteDotted,
				QuantizationType.OneEighthNoteDotted,
				QuantizationType.OneEighthNoteDotted,
				QuantizationType.OneEighthNoteDotted,
				QuantizationType.OneEighthNote,
				QuantizationType.OneEighthNoteDotted,
				QuantizationType.OneEighthNoteDotted,
				QuantizationType.OneEighthNoteDotted,
				QuantizationType.OneEighthNote
			},

			// 4
			new QuantizationType[] {
				QuantizationType.OneEighthNote,
				QuantizationType.OneEighthNote,
				QuantizationType.OneEighthNote,
				QuantizationType.OneEighthNote,
				QuantizationType.OneEighthNote,
				QuantizationType.OneEighthNote,
				QuantizationType.OneEighthNote,
				QuantizationType.OneEighthNoteTriplet,
				QuantizationType.OneEighthNoteTriplet,
				QuantizationType.OneEighthNoteTriplet,
				QuantizationType.OneEighthNote,
				QuantizationType.OneEighthNote,
				QuantizationType.OneEighthNote,
				QuantizationType.OneEighthNote,
				QuantizationType.OneEighthNote,
				QuantizationType.OneEighthNote,
				QuantizationType.OneEighthNote
			},

			// 5
			new QuantizationType[] {
				QuantizationType.OneSixteenthNote,
				QuantizationType.OneSixteenthNote,
				QuantizationType.OneSixteenthNote,
				QuantizationType.OneSixteenthNote,
				QuantizationType.OneSixteenthNote,
				QuantizationType.OneSixteenthNote,
				QuantizationType.OneSixteenthNote,
				QuantizationType.OneSixteenthNote,
				QuantizationType.OneSixteenthNote,
				QuantizationType.OneSixteenthNote,
				QuantizationType.OneSixteenthNote,
				QuantizationType.OneSixteenthNote,
				QuantizationType.OneSixteenthNote,
				QuantizationType.OneSixteenthNote,
				QuantizationType.OneSixteenthNote,
				QuantizationType.OneSixteenthNote,
				QuantizationType.OneSixteenthNote,
				QuantizationType.OneSixteenthNote,
				QuantizationType.OneSixteenthNote,
				QuantizationType.OneSixteenthNote,
				QuantizationType.OneSixteenthNote,
				QuantizationType.OneSixteenthNote,
				QuantizationType.OneSixteenthNote,
				QuantizationType.OneSixteenthNote,
				QuantizationType.OneSixteenthNote,
				QuantizationType.OneSixteenthNote,
				QuantizationType.OneSixteenthNote,
				QuantizationType.OneSixteenthNoteTriplet,
				QuantizationType.OneSixteenthNote,
				QuantizationType.OneSixteenthNoteTriplet,
				QuantizationType.OneSixteenthNote,
				QuantizationType.OneSixteenthNote,
				QuantizationType.OneSixteenthNoteTriplet
			}
		};

		// Bar to channel
		public static final int[][] BarToChannel = new int[][] {
			new int[] { 7, 8 },
			new int[] { 9, 5, 3 },
			new int[] { 10 },
			new int[] { 1, 2, 4, 6 }
		};

		// Stitch notes
		public static final boolean ModuloNotes = false;

		// Number of MIDI channels to use
		public static final int Channels = 10;

		// Set this to true if you want to supress audio, useful for debugging or working next to your sleeping wife
		public static final boolean SilentRunning = false;

		public static final class Pitch {
			// Minimum pitch (0 - 127)
			public static final int Min = 20;

			// Maximum pitch (0 - 127)
			public static final int Max = 80;
		}

		public static final class Velocity {
			// Minimum velocity (0 - 127)
			public static final int Min = 110;

			// Maximum velocity (0 - 127)
			public static final int Max = 127;
		}


		public static final class Note {
			// Minimum note duration in milliseconds
			public static final int Min = 345;

			// Maximum note duration in milliseconds
			public static final int Max = 2950;
		}
	}

	public static final class UI {
		// Frames per second
		public static final int FPS = 60;

		// Processing rendering mode
		public static final String Mode = OPENGL;

		public static final class HUD {
			// Size of the HUD font
			public static final int FontSize = 40;

			// The HUD font
			public static final String Font = "HelveticaNeue-Bold-42.vlw";
		}

		public static final int GridWidth = 100;

		public static final int Margin = 10;
	}

	public static final class Animation {
		public static final class Duration {
			// Minimum tween time
			public static final float Min = 2.0;

			// Maximum tween time
			public static final float Max = 5.0;
		}

		public static final class Scale {
			// Minimum tween scale factor
			public static final float Min = 0.8;

			// Maximum tween scale factor
			public static final float Max = 1.2;

			// Starting scale, 0.0 for points that start in the middle, some big number for RenderType.Meteors
			public static final float Default = 0.001;

			public static boolean UseTicks = true;
		}

		// Rotation speed
		public static final float Speed = 0.002;


		public static final class Zoom {
			// Zoom time
			public static final float Time = 8.0;
		}
	}

	public static final class Optimisations {
		// In an effort to keep animation speed consistent, increase this number to group neighbouring points into a single point
		public static final float PointDistanceTolerance = 1.2;

		// Re-use existing points
		public static final boolean GroupPoints = false;
	}

	public static final class Mesh {
		// Size of the globe
		public static final int GlobeSize = 400;

		// Maximum amount of points to render
		public static final int MaxPoints = 100;

		// Show bounding wireframe
		public static final boolean ShowWireframe = false;

		// Opacity of globe ( 0 - 255 )
		public static final int FillOpacity = 200;

		// Available types:
		// - Normal
		// - Dual
		// - Lattice
		// - Twisted
		// - Voronoi
		// - Extrude
		public static final MeshType Type = MeshType.Normal;

		// Available types:
		// - Edges
		// - Faces
		// - EdgesFaces
		// - Points
		// - EdgesPoints
		// - EdgesFacesPoints
		// - Lines
		// - Particles
		// - Rings
		// - Explosions
		// - Meteors
		// - Plasma
		// - PulsarSignal
		// - Waves
		// - Spikes
		// - Petals

		public static final RenderType Renderer = RenderType.Explosions;

		public static final boolean UseIcosahedronBase = false;

		public static final class Rings {
			// Distance between rings
			public static final int Distance = 8;

			// Rotation step
			public static final int RotationStep = 6;
		}

		public static final class Meteors {
			// Minimum point size for the end of the trail
			public static final float Min = 0.25;

			// Maximum point size for the meteor
			public static final float Max = 4.25;

			// Trail length in pixels
			public static final int TrailLength = 200;

			// Opacity when in flight
			public static final int TrailOpacity = 120;

			// Resting Opacity
			public static final int RestingOpacity = 200;
		}

		public static final class Plasma {
			// Minimum ribbon width
			public static final float Min = 1.0;

			// Maximum ribbon width
			public static final float Max = 6.0;
		}

		public static final class PulsarSignal {
			// Width of the viewport
			public static final int Width = 800;

			// Height of the viewport
			public static final int Height = 800;

			// Distance between lines
			public static final int Distance = 20;

			// Distance between points
			public static final int Step = 5;
		}

		public static final class Waves {
			public static final int Distance = 6;

			public static final int Step = 6;

			public static final float Velocity = 0.1368;

			public static final int Density = 5;

			public static final int WaveLength = 6;
		}

		public static final class Spikes {
			public static final int Steps = 20;

			public static final int Sides = 3;

			public static final int LerpSteps = 100;

			public static final class Radius {
				public static final float Min = 1.0;

				public static final float Max = 100.0;
			}
		}

		public static final class Petals {
			public static final int Sphere = 0xffF7F6F2;
		}

		public static final class Easings {
			public static final Easing In = Ani.ELASTIC_OUT;

			public static final Easing Out = Ani.QUAD_IN;
		}
	}

	public static final class Data {
		public static final class Depth {
			public static final int Min = 0;

			public static final int Max = 1000;
		}

		public static final class Distance {
			public static final float Min = 0.0;

			public static final float Max = 4.0;
		}

		public static final String TimeZone = "Australia/Melbourne";
	}

	public static final class Timing {
		// Start date offset
		public static final String StartDate = "2017-12-01T10:00:00.000Z";

		// End date
		public static final String EndDate = "2017-12-30T23:59:59.999Z";
	}

	public static final class IO {
		// Save frames to disk
		public static final boolean SaveFrames = false;

		// CSV File
		public static final String CSV = "quakes.csv";
	}
}
