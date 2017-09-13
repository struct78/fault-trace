public static class Geography {
	public static WB_Point CoordinatesToWBPoint( double latitude, double longitude, double depth, double radius ) {
		double phi = (90-latitude)*(Math.PI/180);
		double theta = (longitude+180)*(Math.PI/180);
		double x = ((radius) * Math.sin(phi)*Math.cos(theta));
		double z = ((radius) * Math.sin(phi)*Math.sin(theta)) * depth;
		double y = -((radius) * Math.cos(phi));

		return new WB_Point( x, y, z );
	}

	public static WB_Point CoordinatesTo2DWBPoint( double latitude, double longitude, double width, double height ) {
		double d2r = PI / 180;
		double scale = 512;
		double lambda = longitude * d2r;
		double phi = latitude * d2r;
		double x = scale * (lambda + PI) / (TWO_PI);
		double y = scale * (PI - Math.log(Math.tan(PI/4 + (phi / 2)))) / (TWO_PI);

		return new WB_Point( x, y, 0 );
	}
}
