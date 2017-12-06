public class BezierCurve {
  PVector a, b, m;

  BezierCurve(PVector a, PVector b) {
    this.a = a;
    this.b = b;
  }

  public PVector[] getControlPoints() {
    PVector m = PVector.lerp(a, b, 0.5f);
    PVector p = PVector.sub(a, b);
    PVector n = new PVector(-p.y, p.x, p.z);

    float l = sqrt((n.x*n.x)+(n.y*n.y)+(n.z*n.z));
    n.x /= l;
    n.y /= l;
    n.z /= l;

    m = PVector.add(m, PVector.mult(n, PVector.dist(a, b)*0.1));

    float t = 0.1;
    float d1 = sqrt(pow(m.x-a.x, 2) + pow(m.y-a.y, 2) + pow(m.z-a.z, 2));
    float d2 = sqrt(pow(b.x-m.x, 2) + pow(b.y-m.y, 2) + pow(b.z-m.z, 2));

    float fa = t*d1/(d1+d2);
    float fb = t*d2/(d1+d2);

    PVector c = new PVector(m.x-fa*(b.x-a.x), m.y-fa*(b.y-a.y), m.z-fa*(b.z-a.z));
    PVector d = new PVector(m.x+fb*(b.x-a.x), m.y+fb*(b.y-a.y), m.z+fb*(b.z-a.z));

    return new PVector[] { a, c, d, b };
  }
}
