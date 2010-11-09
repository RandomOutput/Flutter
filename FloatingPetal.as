package {
	
	import flash.events.*;
	import flash.display.MovieClip;
	
	public class FloatingPetal extends MovieClip {
		private var xSpeed:Number = Math.random()* 4 + 4;
		private var ySpeed:Number = Math.random()* 5;
		private var rotSpeed:Number = Math.random()*10 - 4;
		public function FloatingPetal() {
			
		}
		
		public function petalUpdate(){
			this.x += xSpeed;
			this.y -=ySpeed;
			this.rotation += rotSpeed;
		}
	}
}
