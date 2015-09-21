package fairygui
{
	import fairygui.event.ItemEvent;
	import fairygui.event.GTouchEvent;
	import fairygui.event.StateChangeEvent;
	import fairygui.utils.GTimers;
	import fairygui.utils.ToolSet;
	
	import starling.events.Event;
	
	[Event(name = "___stateChanged", type = "fairygui.event.StateChangeEvent")]
	public class GComboBox extends GComponent
	{
		protected var _titleObject:GTextField;
		protected var _dropdownObject:GComponent;
		protected var _list:GList;
		
		private var _visibleItemCount:int;
		private var _items:Array;
		private var _values:Array;
		private var _itemsUpdated:Boolean;
		private var _selectedIndex:int;
		private var _buttonController:Controller;
		private var _over:Boolean;
		
		public function GComboBox()
		{
			_visibleItemCount = UIConfig.defaultComboBoxVisibleItemCount;
			_itemsUpdated = true;
			_selectedIndex = -1;
			_items = [];
			_values = [];
		}
		
		final override public function get text():String
		{
			if(_titleObject)
				return _titleObject.text;
			else
				return null;
		}
		
		override public function set text(value:String):void
		{
			if(_titleObject)
				_titleObject.text = value;
		}
		
		final public function get titleColor():uint
		{
			if(_titleObject)
				return _titleObject.color;
			else
				return 0;
		}
		
		public function set titleColor(value:uint):void
		{
			if(_titleObject)
				_titleObject.color = value;
		}
		
		final public function get visibleItemCount():int
		{
			return _visibleItemCount;
		}
		
		public function set visibleItemCount(value:int):void
		{
			_visibleItemCount = value;
		}
		
		final public function get items():Array
		{
			return _items;
		}
		
		public function set items(value:Array):void
		{
			if(!value)
				_items.length = 0;
			else
				_items = value.concat();
			if(_items.length>0)
			{
				if(_selectedIndex>=_items.length)
					_selectedIndex = _items.length-1;
				else if(_selectedIndex==-1)
					_selectedIndex = 0;
				
				this.text = _items[_selectedIndex];
			}
			else
				this.text = "";
			_itemsUpdated = true;
		}
		
		final public function get values():Array
		{
			return _values;
		}
		
		public function set values(value:Array):void
		{
			if(!value)
				_values.length = 0;
			else
				_values = value.concat();
		}
		
		final public function get selectedIndex():int
		{
			return _selectedIndex;
		}
		
		public function set selectedIndex(val:int):void
		{
			if(_selectedIndex==val)
				return;
			
			_selectedIndex = val;
			if(selectedIndex>=0 && selectedIndex<_items.length)
				this.text = _items[_selectedIndex];
			else
				this.text = "";
		}
		
		public function get value():String
		{
			return _values[_selectedIndex];
		}
		
		public function set value(val:String):void
		{
			this.selectedIndex = _values.indexOf(val);
		}
		
		protected function setState(val:String):void
		{
			if(_buttonController)
				_buttonController.selectedPage = val;
		}
		
		override protected function constructFromXML(xml:XML):void
		{
			super.constructFromXML(xml);
			
			xml = xml.ComboBox[0];
			
			var str:String;
			
			_buttonController = getController("button");
			_titleObject = getChild("title") as GTextField;
			str = xml.@dropdown;
			if(str)
			{
				_dropdownObject = UIPackage.createObjectFromURL(str) as GComponent;
				if(!_dropdownObject)
				{
					trace("下拉框必须为元件");
					return;
				}
				
				_list = _dropdownObject.getChild("list").asList;
				if (_list == null)
				{
					trace(this.resourceURL + ": 下拉框的弹出元件里必须包含名为list的列表");
					return;
				}
				_list.addEventListener(ItemEvent.CLICK, __clickItem);
				
				_list.addRelation(_dropdownObject, RelationType.Width);
				_list.removeRelation(_dropdownObject, RelationType.Height);
	
				_dropdownObject.addRelation(_list, RelationType.Height);
				_dropdownObject.removeRelation(_list, RelationType.Width);
				
				_dropdownObject.displayObject.addEventListener(Event.REMOVED_FROM_STAGE, __popupWinClosed);
			}
			
			if(!GRoot.touchScreen)
			{
				this.addEventListener(GTouchEvent.ROLL_OVER, __rollover);
				this.addEventListener(GTouchEvent.ROLL_OUT, __rollout);
			}
			
			this.addEventListener(GTouchEvent.BEGIN, __mousedown);
			this.addEventListener(GTouchEvent.END, __mouseup);
		}
		
		override public function setup_afterAdd(xml:XML):void
		{
			super.setup_afterAdd(xml);
			
			xml = xml.ComboBox[0];
			if(xml)
			{
				var str:String;
				str = xml.@titleColor;
				if(str)
					this.titleColor = ToolSet.convertFromHtmlColor(str);
				str = xml.@visibleItemCount;
				if(str)
					_visibleItemCount = parseInt(str);
				
				var col:XMLList = xml.item;
				for each(var cxml:XML in col)
				{
					_items.push(String(cxml.@title));
					_values.push(String(cxml.@value));
				}
				
				str = xml.@title;
				if(str)
				{
					this.text = str;
					_selectedIndex = _items.indexOf(str);
				}
				else if(_items.length>0)
				{
					_selectedIndex = 0;
					this.text = _items[0];
				}
				else
					_selectedIndex = -1;
			}				
		}
		
		protected function showDropdown():void
		{
			if(_itemsUpdated)
			{
				_itemsUpdated = false;
				
				_list.removeChildren();
				var cnt:int = _items.length;
				for(var i:int=0;i<cnt;i++)
				{
					var item:GObject = _list.addItemFromPool();
					item.name = i<_values.length?_values[i]:"";
					item.text = _items[i];
				}
				_list.resizeToFit(_visibleItemCount);
			}
			_list.selectedIndex = -1;
			_dropdownObject.width = this.width;
			
			var r:GRoot = this.root;
			if(r)
				r.togglePopup(_dropdownObject, this, true);
			if(_dropdownObject.parent)
				setState(GButton.DOWN);
		}
		
		private function __popupWinClosed(evt:Event):void
		{
			if(_over)
				setState(GButton.OVER);
			else
				setState(GButton.UP);
		}
		
		private function __clickItem(evt:ItemEvent):void
		{
			//延时消失使按钮的按下状态有显示的机会
			GTimers.inst.add(100, 1, __clickItem2, _list.getChildIndex(evt.itemObject));
		}
		
		private function __clickItem2(index:int):void
		{
			if(_dropdownObject.parent is GRoot)
				GRoot(_dropdownObject.parent).hidePopup(_dropdownObject);
			_selectedIndex = index;
			if(_selectedIndex>=0)
				this.text = _items[_selectedIndex];
			else
				this.text = "";
			dispatchEvent(new StateChangeEvent(StateChangeEvent.CHANGED));
		}
		
		private function __rollover(evt:GTouchEvent):void
		{
			_over = true;
			if(this.isDown || _dropdownObject && _dropdownObject.parent)
				return;
			
			setState(GButton.OVER);
		}
		
		private function __rollout(evt:GTouchEvent):void
		{
			_over = false;
			if(this.isDown || _dropdownObject && _dropdownObject.parent)
				return;
			
			setState(GButton.UP);
		}
		
		private function __mousedown(evt:GTouchEvent):void
		{
			if(_dropdownObject)
				showDropdown();
		}
		
		private function __mouseup(evt:GTouchEvent):void
		{
			if(_dropdownObject && !_dropdownObject.parent)
			{
				if(_over)
					setState(GButton.OVER);
				else
					setState(GButton.UP);
			}
		}
	}
}
