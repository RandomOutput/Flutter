package {
	
	import flash.events.*;
	import flash.events.MouseEvent;
	import flash.geom.Point;

	import flash.display.MovieClip;
	import libs.Globals;

	public class MotionObject extends MovieClip {
		//private var Globals.StageWidth:Number = 1280;
		//private var Globals.StageHeight:Number = 800;
		public var butterflyType:String = "";
		private var switchDelay:Number=36;
		private var switchTimer:Number=36;
		
		private var xSpeed:Number=8;//speed on x
		private var ySpeed:Number=8;//speed on y
		private var xSpeedOld:Number=8;//speed on x
		private var ySpeedOld:Number=8;//speed on y
		private var runAwaySpeed:Number = 27.5;
		private var net1Pos:Point = new Point();
		private var net2Pos:Point = new Point();
		
		//vars for rotation
				
		//public var circleSpeed = 15;//speed of movement around center
		public var circleSpeed = (Math.random() * 60) - 30;
		public var xCenter:Number= (Math.random()* 600) - 100;
		public var yCenter:Number= (Math.random()* 400) - 100
		
		public var degree = (Math.random()* 358) - 179;
		public var radian;
		private var multiplier:Number=1;
		
		protected var startingPlanetFuel:Number;
		private var startLocX:Number;
		private var startLocY:Number;
		
		private var timeToRotate:Number = 15;
		private var frameTime:Number=0;
		public var circleRadius:Number=50;
		//public var circleRadius = (radius /5 ) + (Math.random() * 150);
		protected var gravity:Number;
		protected var swf;
		private var collisionDist:Number;
		
		private var minRadius:Number;
		private var maxRadius:Number;

		private var oldButterflyX:Number=0;
		private var oldButterflyY:Number=0;
		private var directionSwitch:Number=1;
		
		//vars for rand movement
		private var frameNumber:Number=0;//current number of frames in cycle
		private var timer:Number = 30;//frames before reset
		
		private var xSpeedDegrade:Number=1;//slowly reduce speed of travel
		private var ySpeedDegrade:Number=1;
		
		private static var butterFlyCount:Number=0;
	
		public var newPoint:Point = new Point(500,500);//create new point for butterfly to track
		
		
		public function MotionObject() {
			//set butterflies to rotate either clockwise or counter clockwise on spawn
			butterFlyCount++;
			if(butterFlyCount % 2 == 0) //even
			{
				directionSwitch = 1;
				//trace("even");
			}
			else { //odd
				directionSwitch = -1;
				//trace("odd");
			}
		}
		//all the enterframe listeners condensed to this, called from ButterflyCatcher.as
		public function motionObjectUpdate(){
			moveToPoint();// move to the next point
			circleMotion();//move in a circle
			runAwayOnVector();//run away when the zapper is too close
			delayButterflySwitch();//prevent infinite art style switchin
		}
		
		/*
		* quasi-randomly generated points for butterflies to fly to
		* flight jitteryness
		* speed slowdown
		*
		*/
		private function moveToPoint(){
			//jitteryness if desired
			xCenter += Math.random()* 1 - .5;//random motion if desired
			yCenter += Math.random()*1 - .5;
			
			//slow down speed after each speed change
			xSpeedDegrade -=.25;
			ySpeedDegrade -=.25;
			//set minimum speed degradation
			if(xSpeedDegrade <=0){
				xSpeedDegrade = 0;
			}
			if(ySpeedDegrade <=0){
				ySpeedDegrade = 0;
			}
			if(xSpeed >= 7.25){//set minimum speeds
				xSpeed-=.25;
			}
			if(ySpeed >= 7.25){
				ySpeed-=.25;
			}
			
			//move the butterfly towards the point it is following
			if(xCenter < newPoint.x){
				xCenter += xSpeed;
			}
			if(xCenter > newPoint.x){
				xCenter -= xSpeed;
			}
			if(yCenter > newPoint.y){
				yCenter -= ySpeed;
			}
			if(yCenter < newPoint.y){
				yCenter += ySpeed;
			}
			
			
			//if we collided with the borders then pick a new point
			if(xCenter <=50 || xCenter > Globals.StageWidth || yCenter < 50 || yCenter > Globals.StageHeight){
				recalculateMovement();
			}
			
			//if we reached the point then pick a new point
			if(Math.abs(xCenter-newPoint.x) <=10 && Math.abs(yCenter-newPoint.y) <=10){
				recalculateMovement();
			}
		}
		
		/*
		* circular motion based on a center point, NOT on the actual x,y of the butterfly
		* all motion modifies the xCenter and yCenter execept in this function
		* here we modify the this.x and this.y using xCenter and yCenter
		*/
		public function circleMotion()
		{
			var mousePoint:Point = this.localToGlobal(new Point(mouseX, mouseY));			
			var vX:Number = this.x - mousePoint.x;
			var vY:Number = this.y - mousePoint.y;
			var vL:Number = Math.sqrt((vX*vX) + (vY*vY));
			
			circleSpeed = 5;
			degree += circleSpeed;
			radian = (degree/180)*Math.PI;
			
			if(radian >= 2*Math.PI || radian <= -2*Math.PI)
			{
				degree = 0;
				radian=0;
			}
			if(directionSwitch == 1){
				this.x = xCenter - ( Math.cos(radian)*circleRadius);
				this.y = yCenter + ( Math.sin(radian)*circleRadius);
			}
			if(directionSwitch == -1){
				this.x = xCenter - (  -1 * Math.cos(radian)*circleRadius);
				this.y = yCenter + ( Math.sin(radian)*circleRadius);
			}
			frameTime++;
			if(frameTime >= timeToRotate){
				frameTime=0;
			}
			//no longer necessary to prevent feakouts
			if(Math.abs(radian) == 0){
				//trace("0");
			}
			//no longer necessary to prevent feakouts
			if(Math.abs(radian) == Math.PI){
				//trace("0");
			}
		}
		
		//makes the butterflies fly away based on distance and angle from zapper
		private function runAwayOnVector()	{
			var mousePoint:Point = this.localToGlobal(new Point(mouseX, mouseY));
			/*var vX:Number = this.x - mousePoint.x;
			var vY:Number = this.y - mousePoint.y;
			var vL:Number = Math.sqrt((vX*vX) + (vY*vY));
			var dX:Number = vX/vL;
			var dY:Number = vY/vL;
			//if witin a 150 px then run away
			if(vL < 150) {
				xCenter += dX * runAwaySpeed;
				yCenter += dY * runAwaySpeed;
			}
			
			*/
			
			var vX1:Number = this.x - net1Pos.x;
			var vY1:Number = this.y - net1Pos.y;
			var vX2:Number = this.x - net2Pos.x;
			var vY2:Number = this.y - net2Pos.y;
			var vL1:Number = Math.sqrt((vX1*vX1) + (vY1*vY1));
			var vL2:Number = Math.sqrt((vX2*vX2) + (vY2*vY2));
			var dX1:Number = vX1/vL1;
			var dY1:Number = vY1/vL1;
			var dX2:Number = vX2/vL2;
			var dY2:Number = vY2/vL2;
			var dX3:Number;
			var dY3:Number;
			
			if(vL1 < 150 && vL2 < 150) {
				dX3 = (dX1 + dX2);
				dY3 = (dY1 + dY2);
				
				xCenter += dX3 * runAwaySpeed;
				yCenter += dY3 * runAwaySpeed;
			} else if(vL1 < 150) {
				xCenter += dX1 * runAwaySpeed;
				yCenter += dY1 * runAwaySpeed;
			} else if(vL2 < 150) {
				xCenter += dX2 * runAwaySpeed;
				yCenter += dY2 * runAwaySpeed;
			}
		}
		
		/*
		* when a butterfly reaches its destination, it chooses a new point to follow to
		* 
		*/
		private function recalculateMovement():void{//reset speed, point, degrade, etc
			//reset the circulation speed of the butterfly
			circleSpeed = (Math.random() * 60) - 30;
			
			xSpeed = xSpeedOld;//reset initial speeds
			ySpeed = ySpeedOld;
			
			//find the edge of the mask(middle) on the x axis
			var middle:Number = Globals.PercentControlled * Globals.StageWidth;
			//if the butterfly is art, move to the game side
			if(this.butterflyType == "art"){
				newPoint.x = middle - (Math.random()* middle);
				newPoint.y = Math.random()* Globals.StageHeight;
			}
			
			//if the butterfly is game, move to the art side
			if(this.butterflyType == "game"){
				newPoint.x = middle + (Math.random()* (Globals.StageWidth - middle));
				newPoint.y = Math.random()* Globals.StageHeight;
			}
			
			
			//if the butterfly is too close to the borders
			//set the butterfly to fly back towards the center
			
			if(newPoint.x < 50){
				newPoint.x = middle;
			}
			if(newPoint.x > Globals.StageWidth - 50){
				newPoint.x = middle;
			}
			if(newPoint.y < 50){
				newPoint.y = Globals.StageHeight/2;
			}
			if(newPoint.y > Globals.StageHeight - 50){
				newPoint.y = Globals.StageHeight/2;
			}
			//reset speed degradation everytime a new point is picked
			xSpeedDegrade = .25;
			ySpeedDegrade = .25;
		}
		
		//find distance between butterfly and net
		public function distance(x1:Number,y1:Number,x2:Number,y2:Number) {//distance for later use
			return Math.abs(Math.sqrt(Math.pow(x2-x1,2)+Math.pow(y2-y1,2)));
		}
		
		//get the net position from the doc class
		public function netLocs(catcher1:Catcher,catcher2:Catcher){
			net1Pos = new Point(catcher1.x, catcher1.y);
			net2Pos = new Point(catcher2.x, catcher2.y);
		}
		
		/*
		* set which kind of butterfly it is
		* if its art butterfly, switch to game
		* if its game, switch to art
		* delay switching back and forth with a timer to prevent spazzing
		*/
		
		public function setButterflyType(noSound:Boolean = false){
			if(butterflyType == "art" && switchTimer >= switchDelay){
				butterflyType = "game";
				this.anim.gotoAndStop("game");
				switchTimer = 0;
				if(!noSound){Globals.soundBuffer.push("TransformB.mp3");}
				trace("SWITCH FROM ART");
				}
			if(butterflyType == "game" && switchTimer >= switchDelay){
				butterflyType = "art";
				this.anim.gotoAndStop("art");
				switchTimer = 0;
				if(!noSound){Globals.soundBuffer.push("TransformA.mp3");}
			}
			
		}
		
		/*
		* gives a brief delay between when you can switch a butterfly and then switch it again
		* prevents infinite switch looping on collisions
		*/
		private function delayButterflySwitch(){
			switchTimer++;
			if(switchTimer >= switchDelay){
				//switchTimer = 0;
			}
		}
	}
}
