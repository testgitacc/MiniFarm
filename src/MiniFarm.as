package {
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.*;
	import flash.geom.Point;
	import flash.net.XMLSocket;
	
	public class MiniFarm extends Sprite {
		private var field:FarmField = new FarmField();
		private var tb:Toolbar = new Toolbar();
		private var newPlant:NewPlant;
		
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
			if (newPlant == null)
			{
				newPlant=new NewPlant();
				field.layerNew.addChild(newPlant);
			}
			var p:Point=new Point(mouseX,mouseY);
			newPlant.x=field.globalToLocal(p).x-newPlant.width/2;
			newPlant.y=field.globalToLocal(p).y-newPlant.height/2;
			newPlant.startDrag();
			newPlant.visible=true;
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
			stage.focus=stage;
		}
		
		private function keyDownHandler(event:KeyboardEvent):void 
		{
			trace("stage keyDownHandler "+event.charCode);
			if(event.charCode==27)
			{
				newPlant.stopDrag();
				newPlant.visible=false;
			}
		}		
		
		
		public function finishPlant():void
		{
			newPlant.stopDrag();
			xmlSocket.send("<newPlant><"+newPlant.plantName+" x=\""+Math.round(newPlant.x).toString()+"\""+" y=\""+Math.round(newPlant.y).toString()+"\" /></newPlant>");
			newPlant.visible=false;
		}
		
		
	}
}	

import flash.display.Bitmap;
import flash.display.Loader;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.events.*;
import flash.geom.Point;
import flash.net.URLRequest;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;

class Resources extends Object
{
	private var cache:Object=new Object();
	private var loaders:Object=new Object();
	
	public function load(url:String,onLoad:Function):void
	{
		if (cache[url] != undefined)
		{
			trace("resource from cache " + url);
			onLoad(cache[url]);
		}
		else if(loaders[url] == undefined)
		{
			var loader:ResourceLoader = new ResourceLoader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, completeHandler);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			loader.url=url;
			loader.onLoads.push(onLoad);
			var request:URLRequest = new URLRequest(url);
			loader.load(request);
			loaders[url]=loader;
		}
		else
		{
			loaders[url].onLoads.push(onLoad);
		}
	}
	
	private function completeHandler(event:Event):void 
	{
		var loader:ResourceLoader = ResourceLoader(event.target.loader);
		
		cache[loader.url] = loader.content;
		trace("Resources content loaded "+loader.url);
		trace(cache[loader.url]);
		trace("Resources image loaded "+loader.url);
		for each (var onLoad:Function in loader.onLoads)
		{
			onLoad(cache[loader.url]);
		}
	}
	
	private function ioErrorHandler(event:IOErrorEvent):void {
		trace("Unable to load image: " + event.target.loader["url"]);
	}			
	
}

var resources:Resources=new Resources();

class ResourceLoader extends Loader
{
	public var url:String;
	public var onLoads:Array=new Array();
}

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
		resources.load("../assets/"+plantName+"/"+stageOfGrowth.toString()+".png",onLoad);
	}
	
	protected function onLoad(img:Bitmap):void
	{
		trace("plant onLoad "+img);
		trace(this);
		trace(id);
		image=new Bitmap(img.bitmapData);
		addChild(image);
		afterLoad();
	}
	
	protected  function afterLoad():void
	{
		y=y-height;
	}
	
}

class NewPlant extends Plant 
{
	private var plantNames:Array=["sunflower","clover","potato"];
	
	public function NewPlant() 
	{
		super(plantNames[0], 0, 0, 0, 5);
		addEventListener(MouseEvent.CLICK, clickHandler);
		addEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelHandler);
		addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
		startDrag();
	}
	
	protected override function afterLoad():void
	{
		var p:Point=new Point(mouseX,mouseY);
		p=parent.globalToLocal(localToGlobal(p));
		x=p.x-width/2;
		y=p.y-height/2;
	}
	
	private function keyDownHandler(event:KeyboardEvent):void {
		trace("newPlant keyDownHandler "+event.charCode);
		if(event.charCode==27)
		{
			stopDrag();
			visible=false;
		}
	}
	
	
	private function clickHandler(event:MouseEvent):void {
		trace("newPlant clickHandler");
		root["finishPlant"]();
		event.stopPropagation();
	}
	
	private function mouseWheelHandler(event:MouseEvent):void {
		trace("NewPlantmouseWheelHandler delta: " + event.delta);
		if(event.delta>0)
		{
			nextPlant();
		}
		else
		{
			previousPlant();
		}
		redraw();
		event.stopPropagation();
	}
	
	private function nextPlant():void
	{
		var i:int=plantNames.indexOf(plantName);
		if(i==plantNames.length-1)
		{
			plantName=plantNames[0];
		}
		else
		{
			plantName=plantNames[i+1];
		}
	}
	private function previousPlant():void
	{
		var i:int=plantNames.indexOf(plantName);
		if(i==0)
		{
			plantName=plantNames[plantNames.length-1];
		}
		else
		{
			plantName=plantNames[i-1];
		}
	}
}

import flash.display.LineScaleMode;
import flash.display.CapsStyle;
import flash.display.JointStyle;
import flash.display.Shape;

class FarmField extends Sprite 
{
	private var urlBG:String = "../assets/BG.jpg";
	private var plants:Object=new Object();
	private var layerBG:Sprite=new Sprite();
	private var layerPlants:Sprite=new Sprite();
	public var layerNew:Sprite=new Sprite();
	
	public function FarmField() 
	{
		addChild(layerBG);
		addChild(layerPlants);
		addChild(layerNew);
		loadBG();		
		addEventListener(MouseEvent.CLICK, clickHandler);
		addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
		addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
		addEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelHandler);
		

		var grid:Shape = new Shape();    
		
		grid.graphics.lineStyle(3, 0x00FF00, 0.6, false, LineScaleMode.VERTICAL,
			CapsStyle.NONE, JointStyle.MITER, 10);
		
		
		
		grid.graphics.moveTo(tr3Dto2D(0,0).x, tr3Dto2D(0,0).y);
		grid.graphics.lineTo(tr3Dto2D(0,889).x, tr3Dto2D(0,889).y);
		grid.graphics.lineTo(tr3Dto2D(889,889).x, tr3Dto2D(889,889).y);
		grid.graphics.lineTo(tr3Dto2D(889,0).x, tr3Dto2D(889,0).y);
		grid.graphics.lineTo(tr3Dto2D(0,0).x, tr3Dto2D(0,0).y);

		trace("0,0: "+tr3Dto2D(0,0).x+", "+tr3Dto2D(0,0).y);
		trace("0,0: "+tr2Dto3D(tr3Dto2D(0,0).x,tr3Dto2D(0,0).y).x+", "+tr2Dto3D(tr3Dto2D(0,0).x,tr3Dto2D(0,0).y).y);

		trace("0,889: "+tr3Dto2D(0,889).x+", "+tr3Dto2D(0,889).y);
		trace("0,889: "+tr2Dto3D(tr3Dto2D(0,889).x,tr3Dto2D(0,889).y).x+", "+tr2Dto3D(tr3Dto2D(0,889).x,tr3Dto2D(0,889).y).y);
		
		trace("889,889: "+tr3Dto2D(889,889).x+", "+tr3Dto2D(889,889).y);
		trace("889,889: "+tr2Dto3D(tr3Dto2D(889,889).x,tr3Dto2D(889,889).y).x+", "+tr2Dto3D(tr3Dto2D(889,889).x,tr3Dto2D(889,889).y).y);

		trace("889,0: "+tr3Dto2D(889,0).x+", "+tr3Dto2D(889,0).y);
		trace("889,0: "+tr2Dto3D(tr3Dto2D(889,0).x,tr3Dto2D(889,0).y).x+", "+tr2Dto3D(tr3Dto2D(889,0).x,tr3Dto2D(889,0).y).y);
		
		for (var x3D:Number=74.1;x3D<880;x3D+=74.1)
		{
			grid.graphics.moveTo(tr3Dto2D(x3D,0).x, tr3Dto2D(x3D,0).y);
			grid.graphics.lineTo(tr3Dto2D(x3D,889).x, tr3Dto2D(x3D,889).y);
		}		
		for (var y3D:Number=74.1;y3D<880;y3D+=74.1)
		{
			grid.graphics.moveTo(tr3Dto2D(0,y3D).x, tr3Dto2D(0,y3D).y);
			grid.graphics.lineTo(tr3Dto2D(889,y3D).x, tr3Dto2D(889,y3D).y);
		}

		layerNew.addChild(grid);	
		
		for (x3D=0;x3D<=880;x3D+=74.1*2)
		{
			for (y3D=0;y3D<=880;y3D+=74.1*2)
			{
				var p:Point=tr3Dto2D(x3D-34,y3D+39);
				var plantX:Number=p.x;
				var plantY:Number=p.y;
				layerPlants.addChildAt(new Plant("sunflower",Math.random()*100000,plantX,plantY,5),0);
			}
		}
		
	}
	
	private function tr3Dto2D(x3D:Number,y3D:Number):Point
	{
		var x2D:Number = y3D * 0.7071 + x3D * 0.7071;
		var y2D:Number = y3D * 0.3694 - x3D * 0.3694;
		x2D=x2D+114;
		y2D=y2D+432;
		return new Point(x2D,y2D);
	}
	
	private function tr2Dto3D(x2D:Number,y2D:Number):Point
	{
		x2D=x2D-114;
		y2D=y2D-432;
		var x3D:Number=x2D * 0.7071 - y2D * 1.3535;
		var y3D:Number=x2D * 0.7071 + y2D * 1.3535;
		return new Point(x3D,y3D);
	}
	
//	private function tr2Dto3D(sX:Number,sY:Number):Point
//	{
//		var sX:Number = y * Math.cos(45*Math.PI/180) + x * Math.sin(45*Math.PI/180);
//		var z1:Number = -x * Math.cos(45*Math.PI/180) + y * Math.sin(45*Math.PI/180);
//		var sY:Number = z * Math.cos(-31.5*Math.PI/180) - z1 * Math.sin(-31.5*Math.PI/180);
//		var z2:Number = z1 * Math.cos(-31.5*Math.PI/180) + z * Math.sin(-31.5*Math.PI/180);		
//		return new Point(sX+114,sY+432);
//	}

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
	
	
	private function loadBG():void 
	{
		resources.load(urlBG,onLoad);
	}
	
	private function onLoad(img:Bitmap):void 
	{
		var image:Bitmap = new Bitmap(img.bitmapData);
		layerBG.addChild(image);
		trace("BG loaded");
	}
	
	private function clickHandler(event:MouseEvent):void 
	{
		trace("clickHandler");
	}
	
	
	private function mouseDownHandler(event:MouseEvent):void 
	{
		trace("mouseDownHandler");
		startDrag();
	}
	
	
	private function mouseWheelHandler(event:MouseEvent):void 
	{
		trace("mouseWheelHandler delta: " + event.delta);
		scaleX=scaleX+event.delta/100;
		scaleY=scaleY+event.delta/100;
	}
	
	private function mouseUpHandler(event:MouseEvent):void 
	{
		trace("mouseUpHandler");
		stopDrag();
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