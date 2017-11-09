public class WB_Point5D extends WB_Vector4D {
  private float _mf;

  public WB_Point5D( double x, double y, double z ) {
    super(x, y, z);
  }

  public WB_Point5D( WB_Point v ) {
    super(v);
  }

  public WB_Point5D( WB_Coord v ) {
    super(v);
  }

  public WB_Point4D mul(double f) {
    return new WB_Point4D(this).mul(f);
  }

  public float mf() {
    return _mf;
  }

  public void setM(float m) {
    _mf = m;
  }
}
