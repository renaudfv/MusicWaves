int y = 0;
int x = 0;

void setup() {
  size(500, 500);
  background(0, 0, 0);
  noStroke();
}

void draw() {
    x = (int)random(0,500);
    translate(x, y);
   //background(random(255));
   if(x %2 == 0)
      triangle(5,0,2.5,5,7.5,5);
    delay(10);
    y += 10;
    
    if(y >= 500)
      y = 0;
}
