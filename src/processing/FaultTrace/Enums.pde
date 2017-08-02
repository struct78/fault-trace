public enum RenderType {
	Edges, Faces, EdgesFaces, Points, FacesPoints, EdgesPoints, EdgesFacesPoints, Lines, Particles, Rings, Explosions, Meteors, Plasma
}

public enum MeshType {
	Normal, Dual, Lattice, Twisted, Voronoi, Extrude
}

public enum QuantizationType {
	OneWholeNote(1.0f),
	OneHalfNote(2.0f),
	OneHalfNoteTriplet(3.0f),
	OneQuarterNote(4.0f),
	OneQuarterNoteTriplet(6.0f),
	OneEighthNote(8.0f),
	OneEighthNoteTriplet(12.0f),
	OneSixteenthNote(16.0f),
	OneSixteenthNoteTriplet(24.0f),
	OneThirtySecondNote(32.0f),
	OneThirtySecondNoteTriplet(48.0f),
	OneSixtyFourthNote(64.0f),
	OneSixtyFourthNoteTriplet(96.0f),
	OneHundredTwentyEighthNote(128.0f),
	OneHundredTwentyEighthNoteTriplet(192.0f);

	private float value;

	private QuantizationType( float value ) {
		this.value = value;
	}

	public float get() {
	 return this.value;
	}
}
