public enum RenderType {
	Edges, Faces, EdgesFaces, Points, FacesPoints, EdgesPoints, EdgesFacesPoints, Lines
}

public enum MeshType {
	Normal, Dual, Lattice, Twisted
}

public enum QuantizationType {
	FourWholeNotes(0.25f),
	ThreeWholeNotes(0.3333f),
	TwoWholeNotes(0.5f),
	OneWholeNote(1.0f),
	OneHalfNote(2.0f),
	OneQuarterNote(4.0f),
	OneEigthNote(8.0f),
	OneSixteenthNote(16.0f),
	OneThirtySecondNote(32.0f),
	OneSixtyFourthNote(64.0f),
	OneHundredTwentyEighthNote(128.0f);

	private float value;

	private QuantizationType( float value ) {
		this.value = value;
	}

	public float get() {
	 return this.value;
	}
}
