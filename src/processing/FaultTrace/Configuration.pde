public static final class Configuration {

	public static final class MIDI {
		// Approximate time to parse CSV file (milliseconds)
		public static final long StartOffset = 3000;

		// Time acceleration
		public static final long Acceleration = 5000;

		// BPM for time quantization
		public static final int BeatsPerMinute = 150;

		// BPM for time quantization
		public static final float BeatsPerBar = 3;

		// Number of MIDI channels to use
		public static final int Channels = 13;

		public static final float BeatUnit = QuantizationType.OneQuarterNote.get();


		public static final class Pitch {
			// Minimum pitch (0 - 127)
			public static final int Min = 32;

			// Maximum pitch (0 - 127)
			public static final int Max = 80;
		}

		public static final class Velocity {
			// Minimum velocity (0 - 127)
			public static final int Min = 60;

			// Maximum velocity (0 - 127)
			public static final int Max = 127;
		}


		public static final class Note {
			// Minimum note duration in milliseconds
			public static final int Min = 10;

			// Maximum note duration in milliseconds
			public static final int Max = 50;
		}
	}

	public static final class UI {
		// Debug flag. Hit 'd' key to enable.
		public static final boolean DEBUG = false;

		// Frames per second
		public static final int FPS = 60;


		public static final class HUD {
			// Size of the HUD font
			public static final int FontSize = 42;

			// The HUD font
			public static final String Font = "HelveticaNeue-Bold-42.vlw";
		}

		public static final int GridWidth = 100;

		public static final int Margin = 10;
	}

	public static final class Animation {
		public static final class Duration {
			// Minimum tween time
			public static final float Min = 1.0;

			// Maximum tween time
			public static final float Max = 10.0;
		}

		public static final class Scale {
			// Minimum tween scale factor
			public static final float Min = 1.0;

			// Maximum tween scale factor
			public static final float Max = 1.05;
		}

		// Rotation speed
		public static final float Speed = 0.01;


		public static final class Zoom {
			// Zoom time
			public static final float Time = 5.0;
		}
	}

	public static final class Mesh {
		// Size of the globe
		public static final int GlobeSize = 400;

		// Maximum amount of faces to render
		public static final int MaxFaces = 10000;

		// Show bounding wireframe
		public static final boolean ShowWireframe = false;

		// Available types:
		// - Normal
		// - Dual
		// - Lattice
		// - Twisted
		public static final MeshType Type = MeshType.Normal;

		// Available types:
		// - Edges
		// - Faces
		// - EdgesFaces
		// - Points
		// - EdgesPoints
		// - EdgesFacesPoints
		public static final RenderType Renderer = RenderType.EdgesPoints;
	}

	public static final class Data {
		public static final class Depth {
			public static final int Min = 0;

			public static final int Max = 1000;
		}

		public static final String TimeZone = "Australia/Melbourne";
	}

	public static final class Timing {
		// Start date offset
		public static final String StartDate = "2017-02-01T00:00:00.000Z";

		// End date
		public static final String EndDate = "2017-02-28T23:59:59.999Z";
	}

	public static final class IO {
		// Save frames to disk
		public static final boolean SaveFrames = false;

		// CSV File
		public static final String CSV = "quakes.csv";
	}
}
