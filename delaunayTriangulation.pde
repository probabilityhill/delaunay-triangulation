import java.util.Deque;
import java.util.LinkedList;


DelaunayTriangulation dt;


void setup(){
  size(1000, 1000);
  dt = new DelaunayTriangulation();
  
  // ランダムな座標をもつ30個の点を追加する
  for(int i = 0; i < 30; i++){
    dt.addPoint(new PVector(random(width-200)+100,random(height-200)+100));
  }
}


void draw(){
  background(#ffffff);
  stroke(#000000);
  smooth();
  
  dt.draw();
  
  fill(#3889CE);
  textSize(20);
  PFont font = createFont("游ゴシック Medium", 20);
  textFont(font);
  text("Cを押す→初期化", 10, 40);
  text("Fを押す→メッシュ完成", 10, 20);
}


/***** クリックしたところに点を打ち、ドロネー三角形分割を再構築する ******/
void mousePressed(){
  dt.addPoint(new PVector(mouseX,mouseY));
}


/***** 「F」を押したら巨大な三角形とそれに付随する辺を削除する ******/
/***** 「C」を押したら画面を初期化する ******/
void keyPressed(){
  if(key == 'f'){
    dt.finalize();
  }
  if(key == 'c'){
    setup();
  }
}

/***** 点(x, y)に黒丸の点を打つ ******/
void point(float x, float y)
{
  fill(#000000);
  circle(x, y, 7);
}


/* ##### ドロネー三角形分割をするクラス ##### */
class DelaunayTriangulation{
  Deque<PVector> points = new LinkedList<PVector>();       // 点群 points
  Deque<Triangle> triangles = new LinkedList<Triangle>();  // 三角形の集合 triangles
  Triangle superTriangle;                                  // 巨大な三角形 superTriangle

  // コンストラクタ
  DelaunayTriangulation(){
    superTriangle = getSuperTriangle();                    // 巨大な三角形を作成
    triangles.add(superTriangle);                          // 巨大な三角形を追加
  }
  
  // ドロネー三角形分割を描画する
  void draw(){
    // 点群points内のすべての点を描画する
    for(PVector p : points){
      point(p.x, p.y);
    }
    
    // triangles内のすべての三角形を描画する
    for(Triangle t : triangles){
      strokeWeight(2);
      t.draw();
    }
  }
  
  /***** 点群pointsに点pを追加し、三角形分割を行う ******/
  void addPoint(PVector p){
    points.add(p);
    triangulation(p);
  }
  
  /***** 三角形分割を行う ******/
  void triangulation(PVector p){
    
    Deque<Triangle> s = getStack(triangles);              // スタックs
    Deque<Triangle> ns = new LinkedList<Triangle>();      // 三角形分割後のスタックns
    
    // 点pを内包する△ABCを見つける
    Triangle ABC = isInsideOfTriangle(s, p);
    
    // 点pで△ABCを分割してスタックnsに入れる
    for(Triangle t : divide(s, ABC, p)){
      ns.push(t);
    }
    
    while(s.size() > 0){
      ns.push(s.pop());
    }
    
    // スタックを更新する
    triangles = getStack(ns);
  }
  
  /***** 点pで△ABCを分割する ******/
  Deque<Triangle> divide(Deque<Triangle> s, Triangle triangle, PVector p){
    
    Deque<Triangle> sDivided = new LinkedList<Triangle>();      // △ABC分割後のスタックsDivided
    sDivided.push(new Triangle(triangle.A,triangle.B,p));       // sDividedに△ABPを追加
    sDivided.push(new Triangle(triangle.B,triangle.C,p));       // sDividedに△BCPを追加
    sDivided.push(new Triangle(triangle.C,triangle.A,p));       // sDividedに△CAPを追加
    
    Deque<Triangle> ns = new LinkedList<Triangle>();

    while(sDivided.size() > 0){
      Triangle ABC = sDivided.pop();                            // スタックsDividedから三角形を1つ取り出し△ABCとする
      Edge AB = getOppositeEdge(ABC, p);                        // △ABにおけるC点Pの向かいの辺ABを取得する
      Triangle ADB = getOppositeTriangle(ABC,AB,s);             // △ABCでない方の辺ABを含む三角形ABDを取得する
      if(isEqual(ABC,ADB)){
          ns.push(ABC);
          continue;
      }

      // △ABCの外接円にDが含まれる場合は、辺ABをフリップ
      PVector D = getOppositePoint(ADB, AB);
      if(contains(ABC,D)){
        Deque<Triangle> sFliped = flip(ADB, AB, p);
        for(Triangle t : sFliped){
          sDivided.push(t);
        }
      }
      else{
        ns.push(ABC);
        ns.push(ADB);
      }
    }
    return ns;
  }
  
  /***** 辺ABをフリップする ******/
  Deque<Triangle> flip(Triangle ADB, Edge AB, PVector p){
    Deque<Triangle> sFliped = new LinkedList<Triangle>();

    PVector D = getOppositePoint(ADB,AB);

    sFliped.push(new Triangle(AB.e1,D,p));
    sFliped.push(new Triangle(D,AB.e2,p));

    return sFliped;
  }

  /***** スタックsを返す ******/
  Deque<Triangle> getStack(Deque<Triangle> triangles){
    Deque<Triangle> s = new LinkedList<Triangle>();
    for(Triangle t : triangles){
        s.push(t);
    }
    return s;
  }
  
  /***** super triangleとそれに関するダミー頂点を破棄する ******/
  void finalize(){
      Deque<Triangle> s = getStack(triangles);
      triangles.clear();
      while(s.size()>0)
      {
          Triangle checking = s.pop();
          if(!isSharingPoint(checking, superTriangle))
          {
              triangles.push(checking);
          }
      }
  }
}



/* ##### 点e1と点e2を結ぶ辺 ##### */
class Edge{
  PVector e1;
  PVector e2;

  // コンストラクタ
  Edge(PVector e1, PVector e2){
    this.e1 = e1;
    this.e2 = e2;
  }
  
  // e1とe2を結ぶ辺を描く
  void draw(){
    line(e1.x, e1.y, e2.x, e2.y);
  }
}


/* ##### 三角形ABC ##### */
class Triangle{
  PVector A, B, C;
  Edge AB, BC, CA;
  color triangleColor;
  
  // コンストラクタ
  Triangle(PVector A, PVector B, PVector C){
    this.A = A;
    this.B = B;
    this.C = C;
    
    AB = new Edge(A,B);
    BC = new Edge(B,C);
    CA = new Edge(C,A);
    
    triangleColor = color(255, 255, 255, 0);
  }
  
  // △ABCを描く
  void draw(){
    stroke(#000000);
    fill(triangleColor);
    triangle(A.x, A.y, B.x, B.y, C.x, C.y);
  }
}


/* ##### 中心c, 半径rの円 ##### */
public class Circle{
  PVector c;
  float r;
  
  // コンストラクタ
  public Circle(PVector c, float r){
    this.c = c;
    this.r = r;
  }
}



/***** 外積ABxBCを計算する ******/
public PVector calcCross(PVector A, PVector B, PVector C){
  PVector AB = PVector.sub(A, B);
  PVector BC = PVector.sub(B, C);
  
  return AB.cross(BC);
}



/***** 巨大な三角形を返す ******/
Triangle getSuperTriangle(){
  // 画面（長方形）の外接円を考える
  PVector c = new PVector(width/2, height/2);         // 外接円の中心c
  float r = mag(width/2, height/2);                   // 外接円の半径r
  
  // 上の円に外接する正三角形△を巨大な三角形とする
  PVector t1 = new PVector(c.x, c.y+2*r);             // 頂点t1（上）
  PVector t2 = new PVector(c.x-sqrt(3)*r, c.y-r);     // 頂点t2（左）
  PVector t3 = new PVector(c.x+sqrt(3)*r, c.y-r);     // 頂点t3（右）
  
  return new Triangle(t1, t2, t3);
}



/***** △ABCの外接円を返す ******/
public Circle getCircumscribedCircle(Triangle triangle)
{
  float ax = triangle.A.x;
  float ay = triangle.A.y;
  float bx = triangle.B.x;
  float by = triangle.B.y;
  float cx = triangle.C.x;
  float cy = triangle.C.y;
  
  // 中心(x, y)とすると (ax-x)^2+(ay-y)^2 = (bx-x)^2+(by-y)^2 = (cx-x)^2+(cy-y)^2
  float k = 2 * ((bx - ax) * (cy - ay) - (by - ay) * (cx - ax));
  float x = ((cy - ay) * (bx * bx - ax * ax + by * by - ay * ay) + (ay - by) * (cx * cx - ax * ax + cy * cy - ay * ay)) / k;
  float y = ((ax - cx) * (bx * bx - ax * ax + by * by - ay * ay) + (bx - ax) * (cx * cx - ax * ax + cy * cy - ay * ay)) / k;
 
  PVector c = new PVector(x, y);
  float r = PVector.dist(c, triangle.A);

  return new Circle(c, r);
}



/***** 点pを内包する△ABCを返す ******/
public Triangle isInsideOfTriangle(Deque<Triangle> triangles, PVector p){
  Triangle t = triangles.peek();
  Deque<Triangle> s = new LinkedList<Triangle>();
  
  while(triangles.size() > 0){
    Triangle tmp = triangles.pop();
    if(isInsideOfTriangle(tmp, p))
    {
        t = tmp;
        break;
    }
    else
    {
        s.push(tmp);
    } 
  }
  
  while(s.size() > 0){
    triangles.push(s.pop());
  }
  
  return t;
}



/***** 三角形triangleにおいて辺edgeと対になる点を返す ******/
PVector getOppositePoint(Triangle triangle, Edge edge){
  if(isEqual(edge, triangle.BC)){
    return triangle.A;
  }
  else if(isEqual(edge, triangle.CA)){
    return triangle.B;
  }
  else{
    return triangle.C;
  }
}

/***** 点Pによる分割後の三角形における点Pの向かいの辺を返す ******/
public Edge getOppositeEdge(Triangle triangle, PVector p){
  if(isEqual(p, triangle.C)){
    return triangle.AB;                           // △ABPなら辺AB
  }
  else if(isEqual(p, triangle.A)){
    return triangle.BC;                           // △BCPなら辺BC
  }
  else{
    return triangle.CA;                           // △CAPなら辺CA
  }
}

/***** スタックsから△ABCと辺ABを共有する三角形△ABDを返す ******/
public Triangle getOppositeTriangle(Triangle ABC, Edge AB, Deque<Triangle> s){
  Triangle ABD = ABC;
  Deque<Triangle> ns = new LinkedList<Triangle>();
  
  while(s.size() > 0){
    // スタックsから三角形を1つ取り出す
    Triangle tmp = s.pop();
    
    if(contains(tmp, AB)){
      // 三角形が辺ABを持っていた場合、△ABCでなければ△ABD
      if(isEqual(tmp, ABC)){
         ns.push(tmp);
      }
      else{
        PVector D = getOppositePoint(tmp, AB);
        color Color = tmp.triangleColor;
        ABD = new Triangle(AB.e1,AB.e2,D);
        ABD.triangleColor = Color;
        break; 
      }
    }
    else{
      ns.push(tmp);
    }
  }
  
  while(ns.size() > 0){
    s.push(ns.pop());
  }
  
  return ABD;
}



/***** △ABCの内部に点pがあるかどうか判定する ******/
boolean isInsideOfTriangle(Triangle triangle, PVector p){
  // 外積を計算する
  PVector c1 = calcCross(triangle.A, triangle.B , p);
  PVector c2 = calcCross(triangle.B, triangle.C , p);
  PVector c3 = calcCross(triangle.C, triangle.A , p);
  
  // 外積の正負が一致する⇒△ABCの内部に点pがある（true）
  return (c1.z >=0 && c2.z >=0 && c3.z>=0) || (c1.z <=0 && c2.z <=0 && c3.z<=0);
}



/***** 三角形triangle1と三角形triangle2に共有点があるかどうか判定する ******/
public boolean isSharingPoint(Triangle triangle1, Triangle triangle2){
  return isEqual(triangle1.A, triangle2.A) || isEqual(triangle1.A, triangle2.B)|| isEqual(triangle1.A, triangle2.C)||
         isEqual(triangle1.B, triangle2.A) || isEqual(triangle1.B, triangle2.B)|| isEqual(triangle1.B, triangle2.C)||
         isEqual(triangle1.C, triangle2.A) || isEqual(triangle1.C, triangle2.B)|| isEqual(triangle1.C, triangle2.C);
}



/***** 三角形triangleが点pointを含むどうか判定する ******/
public boolean contains(Triangle triangle, PVector point){
  return contains(getCircumscribedCircle(triangle),point);
}

/***** 三角形triangleが辺edgeを含むどうか判定する ******/
public boolean contains(Triangle triangle, Edge edge){
  return isEqual(triangle.AB, edge) || isEqual(triangle.BC, edge) || isEqual(triangle.CA, edge);
}

/***** 円circleが点pointを含むどうか判定する ******/
public boolean contains(Circle circle, PVector point){
  return circle.c.dist(point) < circle.r;
}



/***** 点point1と点point2が一致するどうか判定する ******/
public boolean isEqual(PVector point1,PVector point2){
  return (point1.x == point2.x)&&(point1.y == point2.y);
}

/*****辺edge1と辺edge2が一致するどうか判定する ******/
public boolean isEqual(Edge edge1,Edge edge2){
  return  (isEqual(edge1.e1, edge2.e1) && isEqual(edge1.e2, edge2.e2))||
          (isEqual(edge1.e1, edge2.e2) && isEqual(edge1.e2, edge2.e1));
}

/***** 三角形triangle1と三角形triangle2が一致するどうか判定する ******/
public boolean isEqual(Triangle triangle1, Triangle triangle2){
  return (isEqual(triangle1.AB, triangle2.AB) || isEqual(triangle1.AB, triangle2.BC) || isEqual(triangle1.AB, triangle2.CA))&&
         (isEqual(triangle1.BC, triangle2.AB) || isEqual(triangle1.BC, triangle2.BC) || isEqual(triangle1.BC, triangle2.CA));
}
