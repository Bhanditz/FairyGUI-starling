package fairygui
{
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	import fairygui.display.UIRichTextField;
	import fairygui.text.RichTextField;
	import fairygui.utils.ToolSet;
	
	import starling.events.Event;
	
	public class GRichTextField extends GTextField
	{
		private var _textField:RichTextField;
		
		public function GRichTextField()
		{
			super();
		}
		
		override protected function createDisplayObject():void
		{ 
			_textField = new UIRichTextField(this);
			setDisplayObject(_textField);
			_textField.addEventListener(Event.REMOVED_FROM_STAGE, __removeFromStage);
		}

		public function get ALinkFormat():TextFormat {
			return _textField.ALinkFormat;
		}
		
		public function set ALinkFormat(val:TextFormat):void {
			_textField.ALinkFormat = val;
			render();
		}

		override protected function render():void
		{
			renderNow(true);
		}
		
		override protected function renderNow(updateBounds:Boolean=true):void
		{
			if(_heightAutoSize)
				_textField.autoSize = TextFieldAutoSize.LEFT;
			else
				_textField.autoSize = TextFieldAutoSize.NONE;
			_textField.nativeTextField.filters = _textFilters;
			_textField.defaultTextFormat = _textFormat;
			_textField.multiline = !_singleLine;
			if(_ubbEnabled)
				_textField.text = ToolSet.parseUBB(_text);
			else
				_textField.text = _text;
			
			var renderSingleLine:Boolean = _textField.numLines<=1;
			
			_textWidth = Math.ceil(_textField.textWidth);
			if(_textWidth>0)
				_textWidth+=5;
			_textHeight = Math.ceil(_textField.textHeight);
			if(_textHeight>0)
			{
				if(renderSingleLine)
					_textHeight+=1;
				else
					_textHeight+=4;
			}
			
			if(_heightAutoSize)
			{
				var h:int = _textHeight/GRoot.contentScaleFactor;
				_textField.height = _textHeight+_fontAdjustment;
				
				_updatingSize = true;
				this.height = h;
				_updatingSize = false;
			}
		}
		
		override protected function handleSizeChanged():void
		{
			if(!_updatingSize)
			{
				_textField.width = this.width*GRoot.contentScaleFactor;
				_textField.height = this.height*GRoot.contentScaleFactor+_fontAdjustment;
			}
		}
		
		private function __removeFromStage(evt:Event):void
		{
			_textField.clearCanvas();
		}
	}
}
