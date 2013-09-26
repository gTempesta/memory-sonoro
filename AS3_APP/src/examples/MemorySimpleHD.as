﻿	package examples {	import com.transmote.flar.FLARManager;	import com.transmote.flar.marker.FLARMarkerEvent;	import com.transmote.flar.tracker.FLARToolkitManager;	import com.transmote.flar.marker.FLARMarker;	import com.transmote.flar.source.FLARCameraSource;		import examples.support.MarkerOutliner;		import flash.display.Sprite;	import flash.display.MovieClip;	import flash.events.MouseEvent;	import flash.events.TimerEvent;	import flash.events.ErrorEvent;	import flash.events.Event;	import flash.events.KeyboardEvent;	import flash.utils.Timer;	import org.fwiidom.osc.*;	import flash.display.Shape;		/**	 * FLARManagerExample_2D demonstrates how to access 2D information about detected markers,	 * including x, y, rotation, and scale, and the (x,y) position of the four corners of the marker's outline.	 * 	 * @author	Eric Socolofsky	 * @url		http://transmote.com/flar	 */	public class MemorySimpleHD extends Sprite {		private var flarManager:FLARManager;		private var markerOutliner:MarkerOutliner;				private static const STR_LOCAL_IP:String = "127.0.0.1";		private static const STR_REMOTE_IP:String = "127.0.0.1";		private static const NUM_PORT:Number = 12345;		private var oscConn:OSCConnection;						private var barWidth:uint;		private var barHeight:uint;					private var numMrk:int = 4;		private var frstMrk:int = 5;		private var guessId:Array = [];		private var sumGuess:int;				private var dist:Number;				private var coupleMatched:Boolean = false;		private var coupleId:int;		private var VICTORY:Boolean = false;		private var notSent:Boolean;			private var shapeWin:Shape;		private var container_shapeWin:Sprite;				private var mrkrsDetected:Vector.<FLARMarker>;		private var coupleVector:Vector.<FLARMarker>;				private var counter:int = 0;		private var padPos:int;				private var thresh:int;				public function MemorySimpleHD () {						this.addEventListener(Event.ADDED_TO_STAGE, this.onAdded);		}				private function onAdded (evt:Event) :void {			this.removeEventListener(Event.ADDED_TO_STAGE, this.onAdded);						this.flarManager = new FLARManager("../resources/flar/flarConfigHD.xml", new FLARToolkitManager(), this.stage);						flarManager.flarCameraSource.useDefaultCamera = true;						FLARCameraSource(flarManager.flarSource).cameraIndex = 0;						//this.flarManager.verbose = true;			this.flarManager.mirrorDisplay = false;			this.flarManager.markerUpdateThreshold = 80;			this.flarManager.markerRemovalDelay = 4; //default is 1			this.flarManager.markerMode = FLARManager.TRACKING_MODE_MULTI;			this.flarManager.patternMode = FLARManager.TRACKING_MODE_MULTI;						this.flarManager.thresholdAdapter = null;			thresh = 85;			this.flarManager.threshold = thresh;						this.flarManager.addEventListener(ErrorEvent.ERROR, this.onFlarManagerError);						this.addChild(Sprite(this.flarManager.flarSource));						this.flarManager.addEventListener(FLARMarkerEvent.MARKER_ADDED, this.onMarkerAdded);			this.flarManager.addEventListener(FLARMarkerEvent.MARKER_UPDATED, this.onMarkerUpdated);			this.flarManager.addEventListener(FLARMarkerEvent.MARKER_REMOVED, this.onMarkerRemoved);						this.markerOutliner = new MarkerOutliner();			this.addChild(this.markerOutliner);			this.markerOutliner.mouseChildren = false;						this.container_shapeWin = new Sprite();			this.addChild(this.container_shapeWin);			this.shapeWin = new Shape();			this.container_shapeWin.addChild(this.shapeWin);						oscConn = new OSCConnection(STR_LOCAL_IP, NUM_PORT);			oscConn.addEventListener(OSCConnectionEvent.ON_CONNECT, onConnect);			oscConn.addEventListener(OSCConnectionEvent.ON_CONNECT_ERROR, onConnectError);			oscConn.addEventListener(OSCConnectionEvent.ON_CLOSE, onClose);			//oscConn.addEventListener(OSCConnectionEvent.ON_PACKET_IN, onPacketIn);			oscConn.addEventListener(OSCConnectionEvent.ON_PACKET_OUT, onPacketOut);						this.addEventListener(Event.ENTER_FRAME, onEnterFrame);						stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPressed);						var btnBar:Sprite = new Sprite();			btnBar.graphics.beginFill(0x000000);			barWidth = stage.stageWidth;			barHeight = 40;			btnBar.graphics.drawRect(0, 0, barWidth, barHeight);			addChild(btnBar);						var btnConnect:Sprite = new Sprite();			btnConnect.graphics.beginFill(0xFFFFFF);			var uintWidth:uint = 20;			var uintHeight:uint = 20;			btnConnect.graphics.drawRect(20, barHeight / 2 - uintHeight / 2, uintWidth, uintHeight);			btnConnect.buttonMode = true;			btnConnect.addEventListener(MouseEvent.CLICK, onConnectClick);			addChild(btnConnect);						for(var i:int = 0; i < numMrk; i++){								guessId.push(0);							}						trace(guessId);		}				private function onFlarManagerError (evt:ErrorEvent) :void {			this.flarManager.removeEventListener(ErrorEvent.ERROR, this.onFlarManagerError);			this.flarManager.removeEventListener(FLARMarkerEvent.MARKER_ADDED, this.onMarkerAdded);			this.flarManager.removeEventListener(FLARMarkerEvent.MARKER_UPDATED, this.onMarkerUpdated);			this.flarManager.removeEventListener(FLARMarkerEvent.MARKER_REMOVED, this.onMarkerRemoved);						trace(evt.text);		}						private function onMarkerAdded (evt:FLARMarkerEvent) :void {			trace("["+evt.marker.patternId+"] added");						this.markerOutliner.drawOutlines(evt.marker, 8, this.getColorByPatternId(evt.marker.patternId));						counter = 0;						mrkrsDetected = this.flarManager.activeMarkers;			//trace(mrkrsDetected.length);						//dare un messaggio se la coppia di questo ID è stato già scoperto						if(guessId[evt.marker.patternId - frstMrk] == 1){				trace("ID is taken");			}						if(mrkrsDetected.length == 0){								//riscrivere mettendo patOne all'inizio, anche nelle altre parti								//mando di uno prima che parta l'altro solo per questo tipo di suono, 				//se voglio che vadano insieme magari no...								if(evt.marker.x > stage.width/2){					padPos = 10;					//oscConn.sendOSCPacket(new OSCPacket("/marker/deleteOne", [2], STR_REMOTE_IP, NUM_PORT));					oscConn.sendOSCPacket(new OSCPacket("/marker/padTwo", [evt.marker.patternId, evt.marker.x, evt.marker.y], STR_REMOTE_IP, NUM_PORT));				}else{					padPos = -10;					//oscConn.sendOSCPacket(new OSCPacket("/marker/deleteTwo", [2], STR_REMOTE_IP, NUM_PORT));					oscConn.sendOSCPacket(new OSCPacket("/marker/padOne", [evt.marker.patternId, evt.marker.x, evt.marker.y], STR_REMOTE_IP, NUM_PORT));				}													}else if (mrkrsDetected.length == 1){								if(mrkrsDetected[0].x < evt.marker.x){					//devo mandarne uno solo, non due, solo quello nuovo!					//oscConn.sendOSCPacket(new OSCPacket("/marker/deleteOne", [2], STR_REMOTE_IP, NUM_PORT));					oscConn.sendOSCPacket(new OSCPacket("/marker/padTwo", [evt.marker.patternId, evt.marker.x, evt.marker.y], STR_REMOTE_IP, NUM_PORT));				}else{					//oscConn.sendOSCPacket(new OSCPacket("/marker/deleteTwo", [2], STR_REMOTE_IP, NUM_PORT));					oscConn.sendOSCPacket(new OSCPacket("/marker/padOne", [evt.marker.patternId, evt.marker.x, evt.marker.y], STR_REMOTE_IP, NUM_PORT));				}			}		}				private function onMarkerUpdated (evt:FLARMarkerEvent) :void {			//trace("["+evt.marker.patternId+"] updated");			this.markerOutliner.drawOutlines(evt.marker, 1, this.getColorByPatternId(evt.marker.patternId));						mrkrsDetected = this.flarManager.activeMarkers;			coupleVector = new Vector.<FLARMarker>;					    if (mrkrsDetected.length == 1){								notSent = true;								counter = 0;								if(padPos > 0){ 					oscConn.sendOSCPacket(new OSCPacket("/marker/padTwo", [45, mrkrsDetected[0].x, mrkrsDetected[0].y], STR_REMOTE_IP, NUM_PORT));				}else{					oscConn.sendOSCPacket(new OSCPacket("/marker/padOne", [45, mrkrsDetected[0].x, mrkrsDetected[0].y], STR_REMOTE_IP, NUM_PORT));				}						}else if (mrkrsDetected.length == 2){										if(mrkrsDetected[0].x < mrkrsDetected[1].x){					coupleVector[0] = mrkrsDetected[0];					coupleVector[1] = mrkrsDetected[1];				}else{					coupleVector[0] = mrkrsDetected[1];					coupleVector[1] = mrkrsDetected[0];				}												oscConn.sendOSCPacket(new OSCPacket("/marker/padOne", [45, coupleVector[0].x, coupleVector[0].y], STR_REMOTE_IP, NUM_PORT));				oscConn.sendOSCPacket(new OSCPacket("/marker/padTwo", [45, coupleVector[1].x, coupleVector[1].y], STR_REMOTE_IP, NUM_PORT));												if(mrkrsDetected[0].patternId == mrkrsDetected[1].patternId){					coupleMatched = true;					coupleId = mrkrsDetected[0].patternId - frstMrk; 				}else{					coupleMatched = false;				}								dist = getDistance(mrkrsDetected[0].x, mrkrsDetected[0].y, mrkrsDetected[1].x, mrkrsDetected[1].y);								if (dist < 210 && coupleMatched){										counter++;															//mettere dentro a una funzione drawCoupleMatched che prende					//due marker, colore e spessore					this.shapeWin.graphics.lineStyle(8, this.getColorByPatternId(evt.marker.patternId));					this.shapeWin.graphics.moveTo(mrkrsDetected[0].x, mrkrsDetected[0].y);					this.shapeWin.graphics.lineTo(mrkrsDetected[1].x, mrkrsDetected[1].y);										if(counter>10){												VICTORY = true;																//i due messaggi vanno distanziati nel tempo altrimenti si rischia che si stoppi il segnale dopo che è già partito!!!						if (counter == 11){							//oscConn.sendOSCPacket(new OSCPacket("/marker/deleteOne", [2], STR_REMOTE_IP, NUM_PORT));							//oscConn.sendOSCPacket(new OSCPacket("/marker/deleteTwo", [2], STR_REMOTE_IP, NUM_PORT));						}else if (counter  == 12){							oscConn.sendOSCPacket(new OSCPacket("/victory", [mrkrsDetected[0].patternId, mrkrsDetected[0].x, mrkrsDetected[0].y], STR_REMOTE_IP, NUM_PORT));						}																		trace("you won!");						trace("Distance between these two markers is: " + dist);						trace(counter);												guessId[coupleId] = 1;												sumGuess = 0;												for(var i:int = 0; i< numMrk; i++){							sumGuess += guessId[i];							trace(sumGuess);						}												trace(guessId);												if(sumGuess == numMrk){							trace("finish");						}												VICTORY = false;											}				}else{					counter = 0;					notSent = true;				}								}else if (mrkrsDetected.length > 2){								counter = 0;				notSent = true;								//trace("too many markers!");			}					}				private function onMarkerRemoved (evt:FLARMarkerEvent) :void {			//trace("["+evt.marker.patternId+"] removed");						counter = 0;						//il messaggio di stop qui serve solamente se si usano loop;			//se si usa un suono che va una volta sola è meglio mettere lo stop prima che parta l'altro, no??						this.markerOutliner.drawOutlines(evt.marker, 4, this.getColorByPatternId(evt.marker.patternId));			mrkrsDetected = this.flarManager.activeMarkers; //non so se serva dirglielo tutte le volte...								if(mrkrsDetected.length == 0){								if(padPos > 0){					oscConn.sendOSCPacket(new OSCPacket("/marker/deleteTwo", [2], STR_REMOTE_IP, NUM_PORT));				}else{					oscConn.sendOSCPacket(new OSCPacket("/marker/deleteOne", [2], STR_REMOTE_IP, NUM_PORT));				}								}else if (mrkrsDetected.length == 1){												if (evt.marker.x > mrkrsDetected[0].x){					oscConn.sendOSCPacket(new OSCPacket("/marker/deleteTwo", [2], STR_REMOTE_IP, NUM_PORT));					padPos = -10;				}else{					oscConn.sendOSCPacket(new OSCPacket("/marker/deleteOne", [2], STR_REMOTE_IP, NUM_PORT));					padPos = 10;				}							}					}				function getDistance(x1:Number, y1:Number, x2:Number, y2:Number): Number {			var dx:Number = x1-x2;			var dy:Number = y1-y2;			return Math.sqrt((dx * dx) + (dy * dy));		}				private function onEnterFrame (evt:Event) :void {			this.shapeWin.graphics.clear();		}				private function getColorByPatternId (patternId:int) :Number {			//switch (patternId%12) {			  switch(patternId){					case 0:					return 0xFF1919;				case 1:					return 0xFF19E8;				case 2:					return 0x9E19FF;				case 3:					return 0x192EFF;				case 4:					return 0x1996FF;				case 5:					return 0x19FDFF;				case 6:					return 0x19FF5A;				case 7:					return 0x19FFAA;				case 8:					return 0x6CFF19;				case 9:					return 0xF9FF19;				case 10:					return 0xFFCE19;				case 11:					return 0xFF9A19;				case 12:					return 0xFF6119;				default:					return 0xCCCCCC;			}					}				private function onKeyPressed(evt:KeyboardEvent): void{			switch (evt.keyCode) {				case 38:					thresh ++;					this.flarManager.threshold = thresh;					trace("Threshold set to: " + this.flarManager.threshold);					break;				case 40:					thresh --;					this.flarManager.threshold = thresh;					trace("Threshold set to: " + this.flarManager.threshold);					break;				default:					trace("keycode: " +evt.keyCode);					break;				}		};						private function onConnectClick(evtClick:MouseEvent):void {			oscConn.connect();				}						private function onConnect(evtOSC:OSCConnectionEvent):void {			trace(this + ": onConnect");				}				private function onConnectError(evtOSC:OSCConnectionEvent):void {			trace(this + ": onConnectError");					}				private function onClose(evtOSC:OSCConnectionEvent):void {			trace(this + ": onClose");					}				private function onPacketOut(evtOSC:OSCConnectionEvent):void {			//trace(this + ": onPacketOut: " + evtOSC.data.name + " " + evtOSC.data.data);			}					}}//funzione counter?//funzione controlla se hai vinto//funzione per ricominciare da zero senza riavviare//funzione per cambiare la soglia se si riesce//aggiusta le misure in camer