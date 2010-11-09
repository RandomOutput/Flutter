package {
	import flash.display.MovieClip;
	import flash.events.Event;

	public class ControlPoint extends MovieClip{
		
		public var cpX;
		public var cpY;
		private var controller:String = null;
		
		public function ControlPoint(startX:int = 0, startY:int = 0) {
			cpX = startX;
			cpY = startY;
			
			this.addEventListener(Event.ENTER_FRAME, updateLocation);
			this.visible = false;
		}
		
		public function updateLocation(event:Event) {
			this.x = cpX;
			this.y = cpY;
		}
		
		//accessors and modifiers
		
		public function setController(newController:String) {
			controller = newController;
			this.visible = true;
		}
		
		public function getController():String {
			return controller;
		}
		
		public function removeController() {
			controller = null;
			this.visible = false;
		}
	}
}