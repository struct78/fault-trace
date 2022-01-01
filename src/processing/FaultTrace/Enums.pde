public enum RenderType {
	Edges(true),
	Faces(true),
	EdgesFaces(true),
	Points(false),
	FacesPoints(true),
	EdgesPoints(true),
	EdgesFacesPoints(true),
	Lines(false),
	Particles(false),
	Rings(false),
	Explosions(false),
	Meteors(false),
	Plasma(false),
	PulsarSignal(false),
	Waves(false),
	Spikes(false),
	Petals(false);

	private boolean value;

	private RenderType( boolean value ) {
		this.value = value;
	}

	public boolean toBoolean() {
	 return this.value;
	}
}

public enum MeshType {
	Normal,
	Dual,
	Lattice,
	Twisted,
	Voronoi,
	Extrude
}

public enum QuantizationType {
  EightWholeNotes(0.125f),
	FourWholeNotes(0.25f),
	ThreeWholeNotes(0.33f),
	TwoWholeNotes(0.5f),
	TwoWholeNotesDotted(0.25f),
	TwoWholeNotesTriplet(0.75f),
	OneWholeNote(1.0f),
	OneWholeNoteDotted(0.5f),
	OneWholeNoteTriplet(1.5f),
	OneHalfNote(2.0f),
	OneHalfNoteDotted(1.0f),
	OneHalfNoteTriplet(3.0f),
	OneQuarterNote(4.0f),
	OneQuarterNoteDotted(2.0f),
	OneQuarterNoteTriplet(6.0f),
	OneEighthNote(8.0f),
	OneEighthNoteDotted(4.0f),
	OneEighthNoteTriplet(12.0f),
	OneSixteenthNote(16.0f),
	OneSixteenthNoteDotted(8.0f),
	OneSixteenthNoteTriplet(24.0f),
	OneThirtySecondNote(32.0f),
	OneThirtySecondNoteDotted(16.0f),
	OneThirtySecondNoteTriplet(48.0f),
	OneSixtyFourthNote(64.0f),
	OneSixtyFourthNoteDotted(32.0f),
	OneSixtyFourthNoteTriplet(96.0f),
	OneHundredTwentyEighthNote(128.0f),
	OneHundredTwentyEighthNoteDotted(64.0f),
	OneHundredTwentyEighthNoteTriplet(192.0f);

	private float value;

	private QuantizationType( float value ) {
		this.value = value;
	}

	public float toFloat() {
	 return this.value;
	}
}
