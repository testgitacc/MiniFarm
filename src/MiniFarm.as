package {
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.geom.Point;
	import flash.utils.flash_proxy;

	
	public class MiniFarm extends Sprite {
		private var field:FarmField = new FarmField();
		private var tb:Toolbar = new Toolbar();
		private var toPlant:ToPlant;
		public function MiniFarm() {
			stage.scaleMode=StageScaleMode.NO_SCALE;
			stage.align=StageAlign.TOP_LEFT;

			addChild(field);			
			addChild(tb);			
		}
		
		public function startPlant():void
		{
			trace("startPlant");
			if (toPlant == null)
			{
				toPlant=new ToPlant();
				field.addChild(toPlant);
			}
			var p:Point=new Point(mouseX,mouseY);
//			trace(mouseX);
			toPlant.x=field.globalToLocal(p).x-toPlant.width/2;
			toPlant.y=field.globalToLocal(p).y-toPlant.height/2;
			toPlant.startDrag();
			toPlant.visible=true;
		}
		
	}
}	

var resources:Object=new Object();

import flash.display.Loader;
class ResourceLoader extends Loader
{
	public var url:String;
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
class ToPlant extends Sprite 
{
	private var url:String = "../assets/sunflower/5.png";
	
	public function ToPlant() {
		loadPic(url);
		addEventListener(MouseEvent.CLICK, clickHandler);
		addEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelHandler);
		startDrag();
	}
	
	
	private function loadPic(url:String):void {
		var loader:ResourceLoader = new ResourceLoader();
		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, completeHandler);
		loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
		loader.url=url;
		var request:URLRequest = new URLRequest(url);
		loader.load(request);
		addChild(loader);
	}
	
	private function completeHandler(event:Event):void {
		var loader:ResourceLoader = ResourceLoader(event.target.loader);
		trace(loader.url);
		var image:Bitmap = Bitmap(loader.content);
		addChild(image);
		
		var p:Point=new Point(mouseX,mouseY);
		p=parent.globalToLocal(localToGlobal(p));
		x=p.x-width/2;
		y=p.y-height/2;
	}
	
	private function ioErrorHandler(event:IOErrorEvent):void {
		trace("Unable to load image: " + url);
	}	
	
	
	private function clickHandler(event:MouseEvent):void {
		trace("clickHandler");
		stopDrag();
		visible=false;
	}
	
	
	
	private function mouseWheelHandler(event:MouseEvent):void {
		trace("ToPlantmouseWheelHandler delta: " + event.delta);
		event.stopPropagation();
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
		b1.addEventListener(MouseEvent.CLICK, b1ClickHandler);
		var b2:Button=new Button("Собрать");
		b2.x=10;
		b2.y=40;
		addChild(b2);
		var b3:Button=new Button("Сделать ход");
		b3.x=10;
		b3.y=70;
		addChild(b3);
	}
	private function b1ClickHandler(event:MouseEvent):void {
		root["startPlant"]();
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