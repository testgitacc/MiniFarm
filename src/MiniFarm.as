package {
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;

	public class MiniFarm extends Sprite {
		public function MiniFarm() {
			stage.scaleMode=StageScaleMode.NO_SCALE;
			stage.align=StageAlign.TOP_LEFT;

			var field:FarmField = new FarmField();
			addChild(field);			
			var tb:Toolbar = new Toolbar();
			addChild(tb);			
		}
	}
}	

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Loader;
import flash.display.Sprite;
import flash.events.*;
import flash.events.MouseEvent;
import flash.external.ExternalInterface;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.net.URLRequest;

class FarmField extends Sprite 
{
	private var urlBG:String = "../assets/BG.jpg";

	public function FarmField() {
		loadBG();		
		addEventListener(MouseEvent.CLICK, clickHandler);
		addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
		addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
		addEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelHandler);
	}
	
	
	private function loadBG():void {
		var loader:Loader = new Loader();
		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, completeHandler);
		loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
		
		var request:URLRequest = new URLRequest(urlBG);
		loader.load(request);
		addChild(loader);
	}
	
	private function completeHandler(event:Event):void {
		var loader:Loader = Loader(event.target.loader);
		var image:Bitmap = Bitmap(loader.content);
		addChild(image);
	}
	
	private function ioErrorHandler(event:IOErrorEvent):void {
		trace("Unable to load image: " + urlBG);
	}	
	
	
	private function clickHandler(event:MouseEvent):void {
		trace("clickHandler");
	}
	

	private function mouseDownHandler(event:MouseEvent):void {
		trace("mouseDownHandler");
		//draw(overSize, overSize, downColor);
		
		//var sprite:Sprite = Sprite(event.target);
		//sprite.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
		startDrag();
	}
	
	
	private function mouseWheelHandler(event:MouseEvent):void {
		trace("mouseWheelHandler delta: " + event.delta);
		scaleX=scaleX+event.delta/100;
		scaleY=scaleY+event.delta/100;
	}
	
	private function mouseUpHandler(event:MouseEvent):void {
		trace("mouseUpHandler");
		//var sprite:Sprite = Sprite(event.target);
		//sprite.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
		stopDrag();
		//draw(overSize, overSize, overColor);
	}		
	
}


class Toolbar extends Sprite {
	public function Toolbar(){
		var b1:Button=new Button("Посадить");
		b1.x=10;
		b1.y=10;
		addChild(b1);
		var b2:Button=new Button("Собрать");
		b2.x=10;
		b2.y=40;
		addChild(b2);
		var b3:Button=new Button("Сделать ход");
		b3.x=10;
		b3.y=70;
		addChild(b3);
	}
}

import flash.display.DisplayObject;
import flash.display.Shape;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;



class Button extends SimpleButton {
	private var upColor:uint   = 0xCCCCCC;
	private var overColor:uint = 0xAAAAAA;
	private var downColor:uint = 0xAAAAAA;
	private var sizeW:uint      = 80;
	private var sizeH:uint      = 20;
	private var text:String;
	
	public function Button(text:String) {
		this.text=text;
		downState      = new ButtonDisplayState(text, downColor, sizeW, sizeH);
		downState.x = x+3;
		downState.y = y+3;	
		overState      = new ButtonDisplayState(text, overColor, sizeW, sizeH);
		upState        = new ButtonDisplayState(text, upColor, sizeW, sizeH);
		hitTestState   = new ButtonDisplayState(text, overColor, sizeW, sizeH);
		useHandCursor  = true;
	}
}

class ButtonDisplayState extends Sprite {
	private var bgColor:uint;
	private var sizeW:uint;
	private var sizeH:uint;
	private var text:String;
	
	public function ButtonDisplayState(text:String, bgColor:uint, sizeW:uint, sizeH:uint) {
		this.text = text;
		this.bgColor = bgColor;
		this.sizeW    = sizeW;
		this.sizeH    = sizeH;
		draw();
		var label:TextField = new TextField();
		label.text=text;
		label.width=sizeW;
		label.height=sizeH;
		label.autoSize=TextFieldAutoSize.CENTER;
		addChild(label);			
	}
	
	private function draw():void {
		graphics.beginFill(bgColor);
		graphics.drawRect(0, 0, sizeW, sizeH);
		graphics.endFill();
	}
}