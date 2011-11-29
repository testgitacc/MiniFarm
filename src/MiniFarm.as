package {
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.*;
	import flash.geom.Point;
	import flash.net.XMLSocket;
	import flash.utils.flash_proxy;
	
	public class MiniFarm extends Sprite {
		private var field:FarmField = new FarmField();
		private var tb:Toolbar = new Toolbar();
		private var toPlant:ToPlant;
		
		private var xmlSocket:XMLSocket = new XMLSocket();
		
		public function MiniFarm() {
			stage.scaleMode=StageScaleMode.NO_SCALE;
			stage.align=StageAlign.TOP_LEFT;

			addChild(field);			
			addChild(tb);
			
			
			xmlSocket.connect("localhost", 11843);
			
			xmlSocket.addEventListener(DataEvent.DATA, onIncomingData);
			connect();
			//disconnect();
			
			
		}

		
		private function connect():void
		{
			xmlSocket.send("GET_FIELD");
		}
		
		private function disconnect():void
		{
			xmlSocket.send("DISCONNECT");
			//xmlSocket.close();
		}
		
		private function onIncomingData(event:DataEvent):void
		{
			trace("[" + event.type + "] " + event.data);
			var xmlField:XML = new XML(event.data);
			trace(xmlField);
			trace(xmlField.name());
			if (xmlField.name()=="field")
			{
				field.beginRedraw();
				for each (var xmlPlant:XML in xmlField.*) 
				{ 
					trace(" plant: " + xmlPlant.name()) 
					trace(" plant: " + xmlPlant.@id) 
					trace(" plant: " + xmlPlant.@x) 
					trace(" plant: " + xmlPlant.@y) 
					trace(" plant: " + xmlPlant.@stage) 
					field.updatePlant(xmlPlant.name(),Number(xmlPlant.@id),Number(xmlPlant.@x),Number(xmlPlant.@y),Number(xmlPlant.@stage));
				}
				field.endRedraw();
			}
		}
		
		
		
		
		
		public function startPlant():void
		{
			trace("startPlant");
			if (toPlant == null)
			{
				toPlant=new ToPlant();
				field.layerNew.addChild(toPlant);
			}
			var p:Point=new Point(mouseX,mouseY);
//			trace(mouseX);
			toPlant.x=field.globalToLocal(p).x-toPlant.width/2;
			toPlant.y=field.globalToLocal(p).y-toPlant.height/2;
			toPlant.startDrag();
			toPlant.visible=true;
		}
		
		public function finishPlant():void
		{
			toPlant.stopDrag();
			
			xmlSocket.send("<newPlant><"+toPlant.plantName+" x=\""+toPlant.x.toString()+"\""+" y=\""+toPlant.y.toString()+"\" /></newPlant>");
			
			toPlant.visible=false;
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
	public var plantName:String="sunflower";
	
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
		trace("Unable to load image: " + event.target.loader["url"]);
	}	
	
	
	private function clickHandler(event:MouseEvent):void {
		trace("clickHandler");
		root["finishPlant"]();
	}
	
	
	
	private function mouseWheelHandler(event:MouseEvent):void {
		trace("ToPlantmouseWheelHandler delta: " + event.delta);
		event.stopPropagation();
	}
	
	
}

import flash.display.Sprite;
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

class Plant extends Sprite
{
	public var checked:Boolean; 
	public var id:int;
	public var stageOfGrowth:int;
	public var plantName:String;

	private var image:Bitmap;
	
	public function Plant(plantName:String, plantId:int, plantX:int, plantY:int, plantStage:int)
	{
		this.id=plantId;
		this.plantName=plantName;
		this.x=plantX;
		this.y=plantY;
		this.stageOfGrowth=plantStage;
		redraw();
	}
	
	public function redraw():void
	{
		if (image!=null)
		{
			removeChild(image);
		}
		if(resources["../assets/"+plantName+"/"+stageOfGrowth.toString()+".png"] is BitmapData)
		{
			image=new Bitmap(resources["../assets/"+plantName+"/"+stageOfGrowth.toString()+".png"]);
			addChild(image);
		}
		else
		{
			loadPic("../assets/"+plantName+"/"+stageOfGrowth.toString()+".png");
		}
			
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
		
		resources[loader.url] = loader.content;
		trace("plant content loaded "+loader.url);
		trace(parent);
		trace(resources[loader.url]);
		if(resources[loader.url] is BitmapData)
		{
			image=new Bitmap(resources[loader.url]);
			addChild(image);
			trace("plant image loaded "+loader.url);
			trace(parent);
		}		
//		var image:Bitmap = Bitmap(loader.content);
//		addChild(image);
	}
	
	private function ioErrorHandler(event:IOErrorEvent):void {
		trace("Unable to load image: " + event.target.loader["url"]);
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
	private var plants:Object=new Object();
	private var layerBG:Sprite=new Sprite();
	private var layerPlants:Sprite=new Sprite();
	public var layerNew:Sprite=new Sprite();

	public function FarmField() {
		addChild(layerBG);
		addChild(layerPlants);
		addChild(layerNew);
		loadBG();		
		addEventListener(MouseEvent.CLICK, clickHandler);
		addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
		addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
		addEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelHandler);
	}

	public function beginRedraw():void
	{
		for each (var plant:Plant in plants)
		{
			plant.checked=false;
		}
	}
	
	public function updatePlant(plantName:String, plantId:int, plantX:int, plantY:int, plantStage:int):void
	{
		if (plants[plantId]== undefined)
		{
			plants[plantId]=new Plant(plantName,plantId,plantX,plantY,plantStage);
			
			layerPlants.addChild(plants[plantId]);
			trace("plant added at "+plantX+" "+plantY);
		}
		else if ( (plants[plantId].stageOfGrowth != plantStage) || (plants[plantId].x != plantX) || (plants[plantId].y != plantY) || (plants[plantId].plantName != plantName))
		{
			plants[plantId].x=plantX;
			plants[plantId].y=plantY;
			plants[plantId].stageOfGrowth=plantStage;
			plants[plantId].plantName=plantName;
			
			plants[plantId].redraw();
		}
		plants[plantId].checked=true;
			
	}

	public function endRedraw():void
	{
		for each (var plant:Plant in plants)
		{
			if (plant.checked===false)
			{
				layerPlants.removeChild(plant);
				plants[plant.id]=undefined;
			}
		}
	}
	
	
	
	private function loadBG():void {
		
		if(resources[urlBG] is BitmapData)
		{
			var image:Bitmap = Bitmap(resources[urlBG]);
			layerBG.addChild(image);
		}
		else
		{
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, completeHandler);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			
			var request:URLRequest = new URLRequest(urlBG);
			loader.load(request);
			layerBG.addChild(loader);
		}
	}
	
	private function completeHandler(event:Event):void {
		var loader:Loader = Loader(event.target.loader);
		resources[urlBG] = loader.content;
		layerBG.removeChild(loader);
		trace("BG content loaded");
		trace(resources[urlBG]);
		if(resources[urlBG] is Bitmap)
		{
			var image:Bitmap = Bitmap(resources[urlBG]);
			layerBG.addChild(image);
			trace("BG loaded");
		}		
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