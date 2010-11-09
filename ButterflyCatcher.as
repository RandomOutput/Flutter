package {
		
	import flash.display.*;
	import flash.events.*;
	import flash.geom.Point;
	import flash.text.*;
	import flash.ui.*;
	
	import libs.Globals;
	import org.tuio.*;
	import org.tuio.connectors.*;
	import org.tuio.osc.*;
	import flashx.textLayout.accessibility.TextAccImpl;
	import flash.media.Sound;
	import flash.net.URLRequest;
	
	import flash.net.URLRequest; //required for handeling external files
	import flash.net.URLLoader; //required for XML load-in
	import flash.media.Sound; //required for sound
	import flash.media.SoundChannel;  //required for sound
	import flash.media.SoundTransform;
	
	public class ButterflyCatcher extends MovieClip {
		//Master controls for stage size 
		private var stageWidth:Number = 1280;
		private var stageHeight:Number = 800;
		private var isTuioEnabled:Boolean=true;
		private var percentControlled:Number = .50;//percentage of butterfiles controlled by game side
		private var numberControlled:Number = 0;//number of butterflies controlled by game side, used to calc percent
		private var totalButterflies:Number = 16;

		private const mode:String = "twoStick";
		
		private var lc:Boolean = true;
		private var tuio:TuioClient;
		private var tuioMngr:TuioManager;
		
		//Tuio point detection tracking
		private var point1Detected:Boolean = false;
		private var point2Detected:Boolean = false;
		private var point3Detected:Boolean = false;
		private var point4Detected:Boolean = false;
		
		//Control Points
		private var point1:ControlPoint = new ControlPoint(0,0);
		private var point2:ControlPoint = new ControlPoint(0,0);
		private var point3:ControlPoint = new ControlPoint(0,0);
		private var point4:ControlPoint = new ControlPoint(0,0);
		
		//catchers
		private var catcher1:Catcher = new Catcher();
		private var catcher2:Catcher = new Catcher();
		
		//butterfly
		//private var btrfly:MotionObject = new MotionObject();
		
		//Collision Arrays
		private var netCollisionPoints:Array = new Array();
		private var butterflies:Array = new Array();
		private var petals:Array = new Array();
		private var petalSpawnDelay:Number=0;
		
		//SOUND STUFF TRACK
		//Sound Object - holds the actual audio file for playing
		private static var track1:Sound = new Sound();
		private static var track2:Sound = new Sound();
		
		//Sound Channel Object - controls the sound object
		private static var track1Handler:SoundChannel;
		private static var track2Handler:SoundChannel;
		
		//URL Request - Holds filepath for audio files - this changes each time a new audio file is played
		private static var track1Req:URLRequest;
		private static var track2Req:URLRequest;
		
		//Keeps track of if a clip is currently playing
		private static var track1Playing:Boolean = false;
		private static var track2laying:Boolean = false;
		
		//sound transforms for tracks
		private var track1Transform:SoundTransform = new SoundTransform(0.5, 0);
		private var track2Transform:SoundTransform = new SoundTransform(0.5, 0);

		
		//SOUND STUFF FX
		//Sound Object - holds the actual audio file for playing
		private static var clip:Sound = new Sound();
		
		//Sound Channel Object - controls the sound object
		private static var clipHandler:SoundChannel;
		
		//URL Request - Holds filepath for audio files - this changes each time a new audio file is played
		private static var clipReq:URLRequest;
		
		//Keeps track of if a clip is currently playing
		private static var soundPlaying:Boolean = false;
		
		//array holding each sound qued to play
		private static var soundBuffer:Array = new Array();
		

		public function ButterflyCatcher(){
			Globals.StageWidth = stageWidth;
			Globals.StageHeight = stageHeight;
			Globals.PercentControlled = percentControlled;
			Globals.soundBuffer = soundBuffer;
			
			if (stage) { menu(); }
			else { addEventListener(Event.ADDED_TO_STAGE, menu); }
			
		}
		
		private function menu() {
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			butterflyNet.visible = false;
			/*
			* Input control method for either IR or mouse
			*/
			if(isTuioEnabled == true){
				this.tuio = new TuioClient(new UDPConnector());
				this.tuioMngr = TuioManager.init(stage, this.tuio);
				this.tuioMngr.addEventListener(TuioEvent.ADD, addHandler);
				this.tuioMngr.addEventListener(TuioEvent.UPDATE, updateHandler);
				this.tuioMngr.addEventListener(TuioEvent.REMOVE, removeHandler);
			}else{
				//butterflyNet.visible = true;
				stage.addEventListener(KeyboardEvent.KEY_DOWN, handleKeyDown);
			}
			trace("menu");
			startTracks();
			init();//this init bypasses the initial setup step
			//this.addEventListener(Event.ENTER_FRAME, waitForCatchers);
		}
		
		private function waitForCatchers(e:Event){
			trace();
			if(catcher1.ready && catcher2.ready) {
				this.removeEventListener(Event.ENTER_FRAME, waitForCatchers);
				init();
			}
		}
		
		private function init(e:Event = null):void {
			trace("init");
			//this.circleSize = 10;
			stage.addChild(catcher1);
			stage.addChild(catcher2);
			
			
			//push collision points into array
			//netCollisionPoints.push(butterflyNet.colSqr1, butterflyNet.colSqr2, butterflyNet.colSqr3, butterflyNet.colSqr4, butterflyNet.colSqr5, butterflyNet.colSqr6, butterflyNet.colSqr7, butterflyNet.colSqr8);
			netCollisionPoints.push(catcher1.colSqr1, catcher1.colSqr2, catcher1.colSqr3, catcher1.colSqr4, catcher1.colSqr5, catcher1.colSqr6, catcher1.colSqr7, catcher1.colSqr8);
			netCollisionPoints.push(catcher2.colSqr1, catcher2.colSqr2, catcher2.colSqr3, catcher2.colSqr4, catcher2.colSqr5, catcher2.colSqr6, catcher2.colSqr7, catcher2.colSqr8);
			//add master update loop
			stage.addEventListener(Event.ENTER_FRAME, update);
			this.addEventListener(Event.ENTER_FRAME, updateSoundBuffer);
			//create collision listener
			
			
			spawnBtrfliesAtStart();//spawn 30 butterflies
		}
		
		public function handleKeyDown(event:KeyboardEvent):void { 	
			
			if (event.keyCode == Keyboard.SPACE) {
				if(stage.displayState == StageDisplayState.NORMAL){
					stage.displayState = StageDisplayState.FULL_SCREEN;
				} else {
					stage.displayState = StageDisplayState.NORMAL;
				}
			}
		} 

		/**
		 * TuioEvent Handling
		 */
		private function addHandler(e:TuioEvent) {
				
			trace("addHandler tuioID: " + e.tuioContainer.sessionID.toString());
			
			// track which points are detected
			if(!point1Detected) { // does this point already exist
				trace("addPoint1");
				point1Detected = true; //this point new exists
				//set the controlling point and location
				point1.setController(e.tuioContainer.sessionID.toString());
				point1.x = e.tuioContainer.x*stage.stageWidth;
				point1.y = e.tuioContainer.y*stage.stageHeight;
				
				if(point1.x <= Globals.StageWidth / 2) {
					catcher1.addPoint(point1);
				} else if(point1.x > Globals.StageWidth / 2) {
					catcher2.addPoint(point1);
				}
			
			} else if(!point2Detected) { // does this point already exist
				trace("addPoint2");
				point2Detected = true; //this point now exists
				//set the controlling point and location
				point2.setController(e.tuioContainer.sessionID.toString());
				point2.x = e.tuioContainer.x*stage.stageWidth;
				point2.y = e.tuioContainer.y*stage.stageHeight;
				//butterflyNet.visible = true;
				
				if(point2.x <= Globals.StageWidth / 2) {
					catcher1.addPoint(point2);
				} else if(point2.x > Globals.StageWidth / 2) {
					catcher2.addPoint(point2);
				}
			
			} else if(!point3Detected) {
				trace("addPoint3");
				point3Detected = true; //this point now exists
				//set the controlling point and location
				point3.setController(e.tuioContainer.sessionID.toString());
				point3.x = e.tuioContainer.x*stage.stageWidth;
				point3.y = e.tuioContainer.y*stage.stageHeight;
				
				if(point3.x <= Globals.StageWidth / 2) {
					catcher1.addPoint(point3);
				} else if(point3.x > Globals.StageWidth / 2) {
					catcher2.addPoint(point3);
				}
			
			} else if(!point4Detected) {
				trace("addPoint4");
				point4Detected = true; //this point now exists
				//set the controlling point and location
				point4.setController(e.tuioContainer.sessionID.toString());
				point4.x = e.tuioContainer.x*stage.stageWidth;
				point4.y = e.tuioContainer.y*stage.stageHeight;
				
				if(point4.x <= Globals.StageWidth / 2) {
					catcher1.addPoint(point4);
				} else if(point4.x > Globals.StageWidth / 2) {
					catcher2.addPoint(point4);
				}
			}
		}
		
		private function updateHandler(e:TuioEvent) {
			//trace("update tuio object");
			if(point1.getController() == e.tuioContainer.sessionID.toString()) {
			
				point1.cpX = e.tuioContainer.x*stage.stageWidth;
				point1.cpY = e.tuioContainer.y*stage.stageHeight;
			}
			
			if(point2.getController() == e.tuioContainer.sessionID.toString()) {
				
				point2.cpX = e.tuioContainer.x*stage.stageWidth;
				point2.cpY = e.tuioContainer.y*stage.stageHeight;
			}
			
			if(point3.getController() == e.tuioContainer.sessionID.toString()) {
				
				point3.cpX = e.tuioContainer.x*stage.stageWidth;
				point3.cpY = e.tuioContainer.y*stage.stageHeight;
			}
			
			if(point4.getController() == e.tuioContainer.sessionID.toString()) {
				
				point4.cpX = e.tuioContainer.x*stage.stageWidth;
				point4.cpY = e.tuioContainer.y*stage.stageHeight;
			}
			
			updateNets();
		}
		
		private function removeHandler(e:TuioEvent) {
			
			if(point1.getController() == e.tuioContainer.sessionID.toString()) {
				point1.removeController();
				point1Detected = false;
				catcher1.removePoint(point1);
				catcher2.removePoint(point1);
			}
			
			if(point2.getController() == e.tuioContainer.sessionID.toString()) {
				point2.removeController();
				point2Detected = false;
				catcher1.removePoint(point2);
				catcher2.removePoint(point2);
			}
			
			if(point3.getController() == e.tuioContainer.sessionID.toString()) {
				point3.removeController();
				point3Detected = false;
				catcher1.removePoint(point3);
				catcher2.removePoint(point3);
			}
			
			if(point4.getController() == e.tuioContainer.sessionID.toString()) {
				point4.removeController();
				point4Detected = false;
				catcher1.removePoint(point4);
				catcher2.removePoint(point4);
			}
		}
		
		private function updateNets() {
			switch(mode) {
				case "oneStick":
					oneStickUpdate();
					break;
				case "twoStick":
					twoStickUpdate();
					break;
			}
		}
		
		/*
		* control the rotation of the stick
		* set the realtionship between each buttefly and the stick
		*
		*/
		
		//WE can reduce the number of iterations through the butterflies array by 50% by merging this with the update
		//I didn't want to fuck with it, assumed you had it seperate for a reason
		private function oneStickUpdate() {
			
			if(point1Detected && point2Detected) {
				var pointAngle:Number;
				var pointDegrees:Number;
				var distanceX:Number;
				var distanceY:Number;
				
				/****Calc Angle***/
				// get relative point location
				distanceX = point1.x - point2.x;
				distanceY = point1.y - point2.y;
				
				// determine angle, convert to degrees
				pointAngle = Math.atan2(distanceY,distanceX);
				pointDegrees = 360*(pointAngle/(2*Math.PI));
				
				butterflyNet.rotation = pointDegrees;
				butterflyNet.x = point1.x;
				butterflyNet.y = point1.y;
				
				for(var i=0; i<butterflies.length; i++) {
					butterflies[i].setNetPos(butterflyNet.x, butterflyNet.y);
				}
			}
		}
		
		private function twoStickUpdate() {
			var catcherArray = new Array(catcher1, catcher2);
			
			for each(var catcher in catcherArray) {
				if(catcher.ready) {				
					var pointAngle:Number;
					var pointDegrees:Number;
					var pt1:ControlPoint = catcher.cp1;
					var pt2:ControlPoint = catcher.cp2;
					var distanceX:Number;
					var distanceY:Number;
					
					/****Calc Angle***/
					// get relative point location
					distanceX = pt1.x - pt2.x;
					distanceY = pt1.y - pt2.y;
					
					// determine angle, convert to degrees
					pointAngle = Math.atan2(distanceY,distanceX);
					pointDegrees = 360*(pointAngle/(2*Math.PI));
					
					catcher.rotation = pointDegrees;
					catcher.x = pt1.x - (distanceX / 2);
					catcher.y = pt1.y - (distanceY / 2);
				}
				
			}
			
			for(var i=0; i<butterflies.length; i++) {
				butterflies[i].netLocs(catcher1, catcher2);
			}
		}
		
		private function update(event:Event){
			//spawn new petals
			petalSpawnDelay++;
			if(petalSpawnDelay >=40){
				petalSpawnDelay=0;
				var newPetal:FloatingPetal = new FloatingPetal();
				petals.push(newPetal);
				var spawnnerToSpawnFrom:Number = Math.floor(Math.random()*3);
				var spawnOffset:Number= 450;
				
				if(spawnnerToSpawnFrom == 0){
					newPetal.x = BG.gameBG.innerBG.spawnner_01.x - spawnOffset;
					newPetal.y = BG.gameBG.innerBG.spawnner_01.y;
				}
				
				if(spawnnerToSpawnFrom == 1){
					newPetal.x = BG.gameBG.innerBG.spawnner_02.x - spawnOffset;
					newPetal.y = BG.gameBG.innerBG.spawnner_02.y;
				}
				
				if(spawnnerToSpawnFrom == 2){
					newPetal.x = BG.gameBG.innerBG.spawnner_03.x - spawnOffset;
					newPetal.y = BG.gameBG.innerBG.spawnner_03.y;
				}
				
				stage.addChild(newPetal);
			}
			
			//petal motion
			for(var h:Number=0; h < petals.length; h++){
				petals[h].petalUpdate();
				if(petals[h].x> 1500){
					//remove the petal
					stage.removeChild(petals[h]);
					petals.splice(h,1);
					trace(petals.length);
				}
			}
		
			numberControlled=0;//reset number controlled
			for(var i:Number = 0; i < butterflies.length; i++) {
				
				/*
				* check collision with net for catcher1
				*/
				if(catcher1.ready) {			
					for(var j:Number = 0; j < 7; j++) {
						//switch the butterfly type if it hits the net
						if(netCollisionPoints[j].hitTestObject(butterflies[i])){
							butterflies[i].setButterflyType();
						}
					}
				}
				
				/*
				* check collision with net for catcher2
				*/
				if(catcher2.ready) {			
					for(var j:Number = 7; j < netCollisionPoints.length; j++) {
						//switch the butterfly type if it hits the net
						if(netCollisionPoints[j].hitTestObject(butterflies[i])){
							butterflies[i].setButterflyType();
						}
					}
				}
				
				//run through the butterfly's update loop
				butterflies[i].motionObjectUpdate();
				//count the number of game butterflies to determine the scaleing of the background masek
				if(butterflies[i].butterflyType == "game"){
					//recount the number of butterflies controled each frame
					numberControlled++;
				}
			}
			
			//mouse control if not using IR
			if(isTuioEnabled==false){
				followMouse();
			}
			
			updateBackground();
		}
		
		//update the scaling of the mask
		private function updateBackground(){
			//Adjust the mask based on the percentages of butterflies per side
			percentControlled = numberControlled / totalButterflies;
			//smooth out the movement of the mask
			if(BG.gameBG.gameBGMask.scaleX > percentControlled){
				BG.gameBG.gameBGMask.scaleX -= .01;
			}
			if(BG.gameBG.gameBGMask.scaleX < percentControlled){
				BG.gameBG.gameBGMask.scaleX += .01;
			}
			//allow individual butterflies to know the percentControlled
			Globals.PercentControlled = percentControlled;
		}
		
		/*
		* spawn 30 butterflies at the start of the game
		* 15 of each type
		* need to offset animation loop still
		*/
		private function spawnBtrfliesAtStart(){
			for(var i:int=0;i<totalButterflies;i++){
				// spawn butterflies on the art side
				var btrfly:MotionObject = new MotionObject();
				if(i <= 8){
					btrfly.butterflyType = "art";
					btrfly.setButterflyType(true);
					stage.addChild(btrfly);
					butterflies.push(btrfly);
				}
				//spawn butterflies on the game side
				else if(i > 8){
					btrfly.butterflyType = "game";
					btrfly.setButterflyType(true);
					stage.addChild(btrfly);
					butterflies.push(btrfly);
				}
			}
		}
		
		//mouse control when not in IR mode
		private function followMouse(){
			butterflyNet.x = mouseX;
			butterflyNet.y = mouseY;
		}
		
		private function startTracks() {
			//locate sound files
			track1Req = new URLRequest("flutterB.mp3");
			track2Req = new URLRequest("flutterA.mp3");
			
			//load files into tracks
			track1.load(track1Req);
			track2.load(track2Req);
			
			//play tracks
			track1Handler = track1.play(1, int.MAX_VALUE);
			track2Handler = track2.play(1, int.MAX_VALUE);
			
			//apply sound transforms
			track1Handler.soundTransform = track1Transform;
			track2Handler.soundTransform = track2Transform;
			
			this.addEventListener(Event.ENTER_FRAME, updateTracks);
		}
		
		private function updateTracks(e:Event) {
			track1Transform.volume = percentControlled;
			track2Transform.volume = 1-percentControlled;			
			track1Handler.soundTransform = track1Transform;
			track2Handler.soundTransform = track2Transform;
		}
		
		private function updateSoundBuffer(event:Event):void {
			if(Globals.soundBuffer.length == 0) {
				return;
			}

			for each(var req in soundBuffer) {
			var newClip = new Sound();
			newClip.load(req);
			var newClipHandler:SoundChannel = newClip.play();
			playingClips.push(newClip);
			playingClips.push(newClipHandler);
			}
		}
		
		public function soundOver(event:Event):void
		{
			clipHandler.removeEventListener(Event.SOUND_COMPLETE, soundOver);
			soundPlaying = false;
		}
	}
}