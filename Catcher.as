package  {
	import flash.display.MovieClip;
	
	public class Catcher extends MovieClip{
		public var cp1:ControlPoint = null;
		public var cp2:ControlPoint = null;
		public var ready:Boolean = false;


		public function Catcher() {
			// constructor code
		}
		
		public function addPoint(newPoint:ControlPoint) {
			if(cp1 == null) {
				trace("add cp1");
				cp1 = newPoint;
			} else if(cp2 == null) {
				trace("add cp2");
				cp2 = newPoint;
			} else {
				trace("overloaded");
			}
			
			if(cp1 != null && cp2 != null) {
				trace("catcher ready");
				ready = true;
				this.visible = true;
			}
		}
		
		public function removePoint(deadCp) {
			if (deadCp == cp1) {
				cp1 = null;
				ready = false;
				this.visible = false;
			} else if(deadCp == cp2) {
				cp2 = null;
				ready = false;
				this.visible = false;
			}
		}
	}
}
