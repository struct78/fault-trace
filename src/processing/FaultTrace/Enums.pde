public enum RenderType {
	Edges, Faces, EdgesFaces, Points, FacesPoints, EdgesPoints, EdgesFacesPoints, Lines
}

public enum MeshType {
	Normal, Dual, Lattice, Twisted, Voronoi, Extrude
}

public enum QuantizationType {
  FourWholeNotes(0.125f),
  ThreeWholeNotes(0.25f),
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

	public float get() {
	 return this.value;
	}
}
