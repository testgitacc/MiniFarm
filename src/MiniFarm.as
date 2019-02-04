package {
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.*;
	import flash.geom.Point;
	import flash.net.XMLSocket;
	import flash.system.Security;
	
	public class MiniFarm extends Sprite {
		public var field:FarmField = new FarmField();
		private var tb:Toolbar = new Toolbar();
		public var newPlant:NewPlant;
		
		public var xmlSocket:XMLSocket = new XMLSocket();

		public function MiniFarm() {
			stage.scaleMode=StageScaleMode.NO_SCALE;
			stage.align=StageAlign.TOP_LEFT;
			
			addChild(field);			
			addChild(tb);

			tb.buttonPlant.addEventListener(MouseEvent.CLICK, buttonPlantClickHandler);
			tb.buttonGrow.addEventListener(MouseEvent.CLICK, buttonGrowClickHandler);
			tb.buttonHarvest.addEventListener(MouseEvent.CLICK, buttonHarvestClickHandler);
			
			//Security.loadPolicyFile("xmlsocket://jp8000.shellmix.com:11843");
			//Security.loadPolicyFile("http://minifarm.shellmix.com/crossdomain.xml");
			
			//xmlSocket.connect("jp8000.shellmix.com", 11843);
			xmlSocket.connect("localhost", 11843);

			xmlSocket.addEventListener(DataEvent.DATA, xmlSocketIncomingDataHandler);
			xmlSocket.addEventListener(Event.CONNECT, xmlSocketConnectHandler);
			

			stage.addEventListener(KeyboardEvent.KEY_DOWN, stageKeyDownHandler);
			stage.focus=stage;
		}

		private function buttonPlantClickHandler(event:MouseEvent):void
		{
			stopHarvest();
			startPlant();
		}		
		
		private function buttonGrowClickHandler(event:MouseEvent):void
		{
			cancelPlant();
			stopHarvest();
			xmlSocket.send("GROW_UP");
		}		
		
		private function buttonHarvestClickHandler(event:MouseEvent):void
		{
			cancelPlant();
			startHarvest();
		}		
		
		
		private function xmlSocketConnectHandler(event:Event):void
		{
		      xmlSocket.send("GET_FIELD");
		}

		private function xmlSocketIncomingDataHandler(event:DataEvent):void
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

		private function stageKeyDownHandler(event:KeyboardEvent):void 
		{
			trace("stage keyDownHandler "+event.charCode);
			if(event.charCode==27)
			{
				cancelPlant();
				stopHarvest();
			}
		}		
		
		
		public function startPlant():void
		{
			trace("startPlant");
			if (newPlant == null)
			{
				newPlant=new NewPlant();
				field.layerNew.addChild(newPlant);
				newPlant.redraw();
				newPlant.addEventListener(MouseEvent.CLICK,newPlantClickHandler);
			}
			newPlant.x=field.layerNew.mouseX-newPlant.width/2;
			newPlant.y=field.layerNew.mouseY-newPlant.height+30;
			newPlant.alpha=0.6;
			newPlant.startDrag();
			field.layerNew.visible=true;
			field.addEventListener(MouseEvent.MOUSE_MOVE, field.mouseMoveHandlerToPlant);
			field.mouseMoveHandlerToPlant();
		}
		
		private function newPlantClickHandler(event:MouseEvent):void 
		{
			if(newPlant.gridX>0 && newPlant.gridY>0)
			{
				trace("newPlantClickHandler "+newPlant.gridX+", "+newPlant.gridY);
				finishPlant();
				startPlant();
			}
		}		
		
		
		public function cancelPlant():void
		{
			if(newPlant != null)
			{
				newPlant.stopDrag();
				field.layerNew.visible=false;
			}
			field.removeEventListener(MouseEvent.MOUSE_MOVE, field.mouseMoveHandlerToPlant);
		}		
		
		public function finishPlant():void
		{
			cancelPlant();
			xmlSocket.send("<newPlant><"+newPlant.plantName+" x=\""+newPlant.gridX.toString()+"\""+" y=\""+newPlant.gridY.toString()+"\" /></newPlant>");
		}
		
		public function startHarvest():void
		{
			field.addEventListener(MouseEvent.MOUSE_MOVE, field.mouseMoveHandlerToHarvest);
			
		}
		
		public function stopHarvest():void
		{
			field.removeEventListener(MouseEvent.MOUSE_MOVE, field.mouseMoveHandlerToHarvest);
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
import flash.utils.Timer;

class Resources extends Object
{
	//private const BASE_URL:String="http://minifarm.shellmix.com/";
	private const BASE_URL:String="../";
	
	private var cache:Object=new Object();
	private var loaders:Object=new Object();
	
	public function load(relurl:String,onLoad:Function):void
	{
		var url:String=BASE_URL+relurl;
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
	public var gridX:int=0;
	public var gridY:int=0;
	
	private var image:Bitmap;
	
	public function Plant(plantName:String, plantId:int, plantX:int, plantY:int, plantStage:int,draw:Boolean=true)
	{
		this.id=plantId;
		this.plantName=plantName;
		this.x=plantX;
		this.y=plantY;
		this.stageOfGrowth=plantStage;
		if (draw)
		{
			redraw();
		}
	}
	
	public function redraw():void
	{
		if (image!=null)
		{
			removeChild(image);
		}
		resources.load("assets/"+plantName+"/"+stageOfGrowth.toString()+".png",onLoad);
	}
	
	protected function onLoad(img:Bitmap):void
	{
		trace("plant onLoad "+img);
		trace(this);
		trace(this.id);
		image=new Bitmap(img.bitmapData);
		addChild(image);
		afterLoad();
	}
	
	protected  function afterLoad():void
	{
		y=y-height;
	}
	
	public function index():String
	{
		return this.gridX+":"+this.gridY;
	}
	
}

class NewPlant extends Plant 
{
	private var plantNames:Array=["sunflower","clover","potato"];
	
	public function NewPlant() 
	{
		super(plantNames[0], 0, 0, 0, 5, false);
		addEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelHandler);
		addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
		addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
	}
	
	protected override function afterLoad():void
	{
		var field:FarmField=root["field"];
		field.mouseMoveHandlerToPlant();
	}
	
	

	private function mouseDownHandler(event:MouseEvent):void 
	{
		event.stopPropagation();
	}
	
	private function mouseUpHandler(event:MouseEvent):void 
	{
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
import flash.ui.MouseCursor;
import flash.ui.Mouse;

class FarmField extends Sprite 
{
	private var urlBG:String = "assets/BG.jpg";
	private var plants:Object=new Object();
	private var layerBG:Sprite=new Sprite();
	private var layerPlants:Sprite=new Sprite();
	private var lastPlant:Plant;
	
	public var layerNew:Sprite=new Sprite();
	
	public function FarmField() 
	{
		addChild(layerBG);
		addChild(layerPlants);
		layerNew.visible=false;
		addChild(layerNew);
		loadBG();		
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

	}
	
	
	public function mouseMoveHandlerToPlant(event:MouseEvent=null):void 
	{
		var newPlant:NewPlant=root["newPlant"];
		var p3D:Point=tr2Dto3D(mouseX,mouseY);
		if(p3D.x>0 && p3D.y>0 && p3D.x<889 && p3D.y<889)
		{
			newPlant.gridX=int(p3D.x/74.1)+1;
			newPlant.gridY=int(p3D.y/74.1)+1;
			var p2D:Point=tr3Dto2D((newPlant.gridX-1)*74.1-34,(newPlant.gridY-1)*74.1+39);
			newPlant.x=p2D.x;
			newPlant.y=p2D.y-newPlant.height;
			newPlant.alpha=0.9;
			if (plants[newPlant.index()]!=undefined && plants[newPlant.index()]!=null)
			{
				newPlant.visible=false;
			}
			else
			{
				newPlant.visible=true;
			}
			
		}
		else
		{
			newPlant.gridX=0;
			newPlant.gridY=0;
			newPlant.x=mouseX-newPlant.width/2;
			newPlant.y=mouseY-newPlant.height+30;
			newPlant.alpha=0.6;
			newPlant.visible=true;
		}
	}	
	
	public function mouseMoveHandlerToHarvest(event:MouseEvent=null):void 
	{
		var p3D:Point=tr2Dto3D(mouseX,mouseY);
		var gridX:int=0;
		var gridY:int=0;
		var index:String=gridX+":"+gridY;

		if(p3D.x>0 && p3D.y>0 && p3D.x<889 && p3D.y<889)
		{
			gridX=int(p3D.x/74.1)+1;
			gridY=int(p3D.y/74.1)+1;
			index=gridX+":"+gridY;
			if(lastPlant!=null && lastPlant!=plants[index])
			{
				plantStopHarvest(lastPlant);
				lastPlant=null;
			}
			if (plants[index]!=undefined && plants[index]!=null)
			{
				trace(index);
				Mouse.cursor=MouseCursor.HAND;
				plants[index].addEventListener(MouseEvent.MOUSE_DOWN,mouseClickHandlerToHarvest);
				plants[index].addEventListener(MouseEvent.MOUSE_OUT,mouseOutHandlerToHarvest);
				if(plants[(gridX-1)+":"+(gridY+1)] != undefined && plants[(gridX-1)+":"+(gridY+1)] != null)
				{
					if (layerPlants.getChildIndex(plants[index])<layerPlants.getChildIndex(plants[(gridX-1)+":"+(gridY+1)]))
					{
						layerPlants.swapChildren(plants[index],plants[(gridX-1)+":"+(gridY+1)]);
					}
					plants[index].alpha=0.7;
				}
				lastPlant=plants[index];
			}
			else
			{
				Mouse.cursor=MouseCursor.ARROW;
			}
		}
		else
		{
			Mouse.cursor=MouseCursor.ARROW;
		}
			
	}	
	private function plantStopHarvest(plant:Plant):void
	{
		plant.removeEventListener(MouseEvent.MOUSE_DOWN,mouseClickHandlerToHarvest);
		plant.removeEventListener(MouseEvent.MOUSE_OUT,mouseOutHandlerToHarvest);
		if(plants[(plant.gridX-1)+":"+(plant.gridY+1)] != undefined && plants[(plant.gridX-1)+":"+(plant.gridY+1)] != null)
		{
			layerPlants.swapChildren(plant,plants[(plant.gridX-1)+":"+(plant.gridY+1)]);
		}
		plant.alpha=1;
		Mouse.cursor=MouseCursor.ARROW;
	}
	public function mouseClickHandlerToHarvest(event:MouseEvent):void 
	{
		trace("harvest: "+event.currentTarget);
		event.stopPropagation();
		plantStopHarvest(Plant(event.currentTarget));
		plantStopHarvest(lastPlant);
		lastPlant=null;
		root["xmlSocket"].send("<harvestPlant id=\""+event.currentTarget.id+"\" />");
	}	
	
	public function mouseOutHandlerToHarvest(event:MouseEvent):void 
	{
		plantStopHarvest(Plant(event.currentTarget));
	}	
	
	public function tr3Dto2D(x3D:Number,y3D:Number):Point
	{
		var x2D:Number = y3D * 0.7071 + x3D * 0.7071;
		var y2D:Number = y3D * 0.3694 - x3D * 0.3694;
		x2D=x2D+114;
		y2D=y2D+432;
		return new Point(x2D,y2D);
	}
	
	public function tr2Dto3D(x2D:Number,y2D:Number):Point
	{
		x2D=x2D-114;
		y2D=y2D-432;
		var x3D:Number=x2D * 0.7071 - y2D * 1.3535;
		var y3D:Number=x2D * 0.7071 + y2D * 1.3535;
		return new Point(x3D,y3D);
	}
	
	public function beginRedraw():void
	{
		for each (var plant:Plant in plants)
		{
			if(plant!=null)
			{
				plant.checked=false;
			}
		}
	}
	
	public function updatePlant(plantName:String, plantId:int, gridX:int, gridY:int, plantStage:int):void
	{
		var p2D:Point=tr3Dto2D((gridX-1)*74.1-34,(gridY-1)*74.1+39);
		var index:String=gridX+":"+gridY;
		if (plants[index]==undefined || plants[index]==null)
		{
			plants[index]=new Plant(plantName,plantId,p2D.x,p2D.y,plantStage);
			plants[index].gridX=gridX;
			plants[index].gridY=gridY;
			layerPlants.addChildAt(plants[index],getPlace(plants[index]));
		}
		else if ( (plants[index].stageOfGrowth != plantStage) || (plants[index].plantName != plantName))
		{
			plants[index].id=plantId;
			plants[index].x=p2D.x;
			plants[index].y=p2D.y;
			plants[index].gridX=gridX;
			plants[index].gridY=gridY;
			plants[index].stageOfGrowth=plantStage;
			plants[index].plantName=plantName;
			plants[index].redraw();
		}
		plants[index].checked=true;
		
	}
	
	private function getPlace(plant:Plant):int
	{
		for (var i:int=0;i<layerPlants.numChildren;i++)
		{
			if((Plant(layerPlants.getChildAt(i)).gridY>plant.gridY) || ((Plant(layerPlants.getChildAt(i)).gridY=plant.gridY) && (Plant(layerPlants.getChildAt(i)).gridX<plant.gridX)))
			{
				return i;
			}
		}
		return layerPlants.numChildren;
	}
	
	public function endRedraw():void
	{
		for each (var plant:Plant in plants)
		{
			if (plant!=null && !plant.checked)
			{
				layerPlants.removeChild(plant);
				plants[plant.index()]=null;
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

class Toolbar extends Sprite 
{
	public var buttonPlant:Button=new Button("Посадить");
	public var buttonGrow:Button=new Button("Сделать ход");
	public var buttonHarvest:Button=new Button("Собрать");

	public function Toolbar()
	{
		buttonPlant.x=10;
		buttonPlant.y=10;
		addChild(buttonPlant);
		buttonGrow.x=10;
		buttonGrow.y=40;
		addChild(buttonGrow);
		buttonHarvest.x=10;
		buttonHarvest.y=70;
		addChild(buttonHarvest);
	}
}


class Button extends SimpleButton 
{
	private var upColor:uint   = 0xCCCCCC;
	private var overColor:uint = 0xAAAAAA;
	private var downColor:uint = 0xAAAAAA;
	private var sizeW:uint      = 80;
	private var sizeH:uint      = 20;
	public var text:String;
	
	public function Button(text:String) 
	{
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

class ButtonDisplayState extends Sprite 
{
	private var bgColor:uint;
	private var sizeW:uint;
	private var sizeH:uint;
	private var text:String;
	
	public function ButtonDisplayState(text:String, bgColor:uint, sizeW:uint, sizeH:uint) 
	{
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
	
	private function draw():void 
	{
		graphics.beginFill(bgColor);
		graphics.drawRect(0, 0, sizeW, sizeH);
		graphics.endFill();
	}
}