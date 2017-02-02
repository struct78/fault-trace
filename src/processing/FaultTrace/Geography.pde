public static class Geography {
	public static WB_Point CoordinatesToWBPoint( double latitude, double longitude, double radius, double depth ) {
		double phi = (90-latitude)*(Math.PI/180);
		double theta = (longitude+180)*(Math.PI/180);
		double x = ((radius) * Math.sin(phi)*Math.cos(theta));
		double z = ((radius) * Math.sin(phi)*Math.sin(theta));
		double y = -((radius) * Math.cos(phi));
		double scale = ( depth / Configuration.Data.Depth.Max );

		return new WB_Point(x, y, z).mulSelf( 1-scale );
	}
}
