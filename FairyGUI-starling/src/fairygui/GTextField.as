package fairygui
{
	import flash.filters.DropShadowFilter;
	import flash.geom.Point;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	import fairygui.display.TextCanvas;
	import fairygui.display.UITextField;
	import fairygui.text.BMGlyph;
	import fairygui.text.BitmapFont;
	import fairygui.utils.CharSize;
	import fairygui.utils.ToolSet;
	
	import starling.events.Event;

	public class GTextField extends GObject implements IColorGear
	{
		protected var _ubbEnabled:Boolean;
		protected var _autoSize:int;
		protected var _widthAutoSize:Boolean;
		protected var _heightAutoSize:Boolean;
		protected var _textFormat:TextFormat;
		protected var _text:String;
		protected var _font:String;
		protected var _fontSize:int;
		protected var _align:int;
		protected var _verticalAlign:int;
		protected var _color:uint;
		protected var _leading:int;
		protected var _letterSpacing:int;
		protected var _underline:Boolean;
		protected var _bold:Boolean;
		protected var _italic:Boolean;
		protected var _singleLine:Boolean;
		protected var _stroke:Boolean;
		protected var _strokeColor:uint;
		protected var _displayAsPassword:Boolean;
		protected var _textFilters:Array;
		
		protected var _gearColor:GearColor;
		
		protected var _canvas:TextCanvas;

		protected var _updatingSize:Boolean;
		protected var _requireRender:Boolean;
		protected var _sizeDirty:Boolean;
		protected var _yOffset:int;
		protected var _textWidth:int;
		protected var _textHeight:int;
		protected var _fontAdjustment:int;
		protected var _minHeight:int; 
		
		protected var _bitmapFont:BitmapFont;
		protected var _lines:Vector.<LineInfo>;
		
		protected static var renderTextField:TextField = new TextField();
		private static var sHelperPoint:Point = new Point();
		
		private static const GUTTER_X:int = 2;
		private static const GUTTER_Y:int = 2;
		
		public function GTextField()
		{
			super();
			
			_textFormat = new TextFormat();
			_fontSize = 12;
			_color = 0;
			_align = AlignType.Left;
			_verticalAlign = VertAlignType.Top;
			_text = "";
			_leading = 3;
			
			_autoSize= AutoSizeType.Both;
			_widthAutoSize = true;
			_heightAutoSize = true;
			
			_gearColor = new GearColor(this);
		}
		
		override protected function createDisplayObject():void
		{ 
			_canvas = new UITextField(this);
			setDisplayObject(_canvas); 
			_canvas.addEventListener(Event.REMOVED_FROM_STAGE, __removeFromStage);
			_canvas.renderCallback = onRender;
		}
		
		override public function dispose():void
		{
			super.dispose();

			_requireRender = false;
			_bitmapFont = null;
		}

		override public function set text(value:String):void
		{
			_text = value;
			if(_text==null)
				_text = "";
			
			if(parent && parent._underConstruct)
				renderNow();
			else
				render();
		}
		
		override public function get text():String
		{
			return _text;
		}
		
		final public function get font():String
		{
			return _font;
		}
		
		public function set font(value:String):void
		{
			if(_font!=value)
			{
				_font = value;
				updateTextFormat();
			}
		}
		
		final public function get fontSize():int
		{
			return _fontSize;
		}
		
		public function set fontSize(value:int):void
		{
			if(value<0)
				return;
			
			if(_fontSize!=value)
			{
				_fontSize = value;
				updateTextFormat();
			}
		}
		
		final public function get color():uint
		{
			return _color;
		}
		
		public function set color(value:uint):void
		{
			if(_color!=value)
			{
				_color = value;
				if(_gearColor.controller)
					_gearColor.updateState();
				
				updateTextFormat();
			}
		}
		
		final public function get align():int
		{
			return _align;
		}
		
		public function set align(value:int):void
		{
			if(_align!=value)
			{
				_align = value;
				updateTextFormat();
			}
		}
		
		final public function get verticalAlign():int
		{
			return _verticalAlign;
		}
		
		public function set verticalAlign(value:int):void
		{
			if(_verticalAlign!=value)
			{
				_verticalAlign = value;
				doAlign();
			}
		}
		
		final public function get leading():int
		{
			return _leading;
		}
		
		public function set leading(value:int):void
		{
			if(_leading!=value)
			{
				_leading = value;
				updateTextFormat();
			}
		}
		
		final public function get letterSpacing():int
		{
			return _letterSpacing;
		}
		
		public function set letterSpacing(value:int):void
		{
			if(_letterSpacing!=value)
			{
				_letterSpacing = value;
				updateTextFormat();
			}
		}

		final public function get underline():Boolean
		{
			return _underline;
		}
		
		public function set underline(value:Boolean):void
		{
			if(_underline!=value)
			{
				_underline = value;
				updateTextFormat();
			}
		}
		
		final public function get bold():Boolean
		{
			return _bold;
		}
		
		public function set bold(value:Boolean):void
		{
			if(_bold!=value)
			{
				_bold = value;
				updateTextFormat();
			}
		}
		
		final public function get italic():Boolean
		{
			return _italic;
		}
		
		public function set italic(value:Boolean):void
		{
			if(_italic!=value)
			{
				_italic = value;
				updateTextFormat();
			}
		}
		
		public function get singleLine():Boolean
		{
			return _singleLine;
		}
		
		public function set singleLine(value:Boolean):void
		{
			if(_singleLine!=value)
			{
				_singleLine = value;
				render();
			}
		}
		
		final public function get stroke():Boolean
		{
			return _stroke;
		}
		
		public function set stroke(value:Boolean):void
		{
			if(_stroke!=value)
			{
				_stroke = value;
				if(_stroke)
					_textFilters = createStrokeFilters(_strokeColor);
				else
					_textFilters = null;
				render();
			}
		}
		
		private static function createStrokeFilters(color:uint):Array
		{
			return [new DropShadowFilter(1, 45, color, 1, 1, 1, 5, 1),
				new DropShadowFilter(1, 222, color, 1, 1, 1, 5, 1)];
		}
		
		final public function get strokeColor():uint
		{
			return _strokeColor;
		}
		
		public function set strokeColor(value:uint):void
		{
			if(_strokeColor!=value)
			{
				_strokeColor = value;
				if(_stroke)
					_textFilters = createStrokeFilters(_strokeColor);
				render();
			}
		}
		
		public function set ubbEnabled(value:Boolean):void
		{
			if(_ubbEnabled!=value)
			{
				_ubbEnabled = value;
				render();
			}
		}
		
		final public function get ubbEnabled():Boolean
		{
			return _ubbEnabled;
		}
		
		public function set autoSize(value:int):void
		{
			if(_autoSize!=value)
			{
				_autoSize = value;
				_widthAutoSize = value==AutoSizeType.Both;
				_heightAutoSize = value==AutoSizeType.Both||value==AutoSizeType.Height;
				render();
			}
		}
		
		final public function get autoSize():int
		{
			return _autoSize;
		}
		
		final public function get displayAsPassword():Boolean
		{
			return _displayAsPassword;
		}
		
		public function set displayAsPassword(val:Boolean):void
		{
			if(_displayAsPassword != val)
			{
				_displayAsPassword = val;
				render();
			}
		}
		
		public function get textWidth():int
		{
			this.ensureSizeCorrect();
			return _textWidth;
		}
		
		override public function ensureSizeCorrect():void
		{
			if(_sizeDirty && _requireRender)
				renderNow();
		}

		final public function get gearColor():GearColor
		{
			return _gearColor;
		}
		
		override public function handleControllerChanged(c:Controller):void
		{
			super.handleControllerChanged(c);
			
			if(_gearColor.controller==c)
				_gearColor.apply();
		}
		
		protected function updateTextFormat():void
		{
			_textFormat.size = _fontSize;
			if(ToolSet.startsWith(_font, "ui://"))
			{
				_bitmapFont = UIPackage.getBitmapFontByURL(_font);
				_fontAdjustment = 0;
				_minHeight = int.MAX_VALUE;
			}
			else
			{
				_bitmapFont = null;
				
				if(_font)
					_textFormat.font = _font;
				else
					_textFormat.font = UIConfig.defaultFont;
			
				var v:int = CharSize.getHeight(int(_textFormat.size), _textFormat.font, _bold);
				_minHeight = v+4-_fontAdjustment;
				
				//像微软雅黑这样的字体，默认的渲染顶部会产生很大的空间，这里加一个调整值，消除这些多余的空间
				v = v-int(_textFormat.size);
				if(v>3)
					_fontAdjustment = Math.ceil(v/2);
			}
			
			if(this.grayed)
				_textFormat.color = 0xAAAAAA;
			else
				_textFormat.color = _color;
			_textFormat.align = AlignType.toString(_align);
			_textFormat.leading = _leading-_fontAdjustment;
			if(_textFormat.leading<0)
				_textFormat.leading = 0;
			_textFormat.letterSpacing = _letterSpacing;
			_textFormat.bold = _bold;
			_textFormat.underline = _underline;
			_textFormat.italic = _italic;

			if(!_underConstruct)
				render();
		}
		
		protected function render():void
		{
			_requireRender = true;
			if(_widthAutoSize || _heightAutoSize)
			{
				_sizeDirty = true;
				_dispatcher.dispatch(this, GObject.SIZE_DELAY_CHANGE);
			}
		}
		
		private function onRender():void
		{
			if(_requireRender)
				renderNow();
		}

		private function __removeFromStage(evt:Event):void
		{
			clearCanvas();
		}
		
		protected function renderNow(updateBounds:Boolean=true):void
		{
			_requireRender = false;
			_sizeDirty = false;
			
			if(_bitmapFont!=null)
			{
				renderWithBitmapFont(updateBounds);
				return;
			}
			
			renderTextField.defaultTextFormat = _textFormat;
			renderTextField.selectable = false;
			if(_widthAutoSize)
			{
				renderTextField.autoSize = TextFieldAutoSize.LEFT;
				renderTextField.wordWrap = false;
			}
			else
			{
				renderTextField.autoSize = TextFieldAutoSize.NONE;
				renderTextField.wordWrap = !_singleLine;
			}
			renderTextField.width = this.width;
			renderTextField.height = Math.max(this.height, int(_textFormat.size));
			renderTextField.multiline = !_singleLine;
			renderTextField.antiAliasType = AntiAliasType.ADVANCED;
			renderTextField.filters = _textFilters;
			
			updateTextFieldText();
			
			var renderSingleLine:Boolean = renderTextField.numLines<=1;
			
			_textWidth = Math.ceil(renderTextField.textWidth);
			if(_textWidth>0)
				_textWidth+=5;
			_textHeight = Math.ceil(renderTextField.textHeight);
			if(_textHeight>0)
			{
				if(renderSingleLine)
					_textHeight+=1;
				else
					_textHeight+=4;
			}
			
			var w:int, h:int;
			if(_widthAutoSize)
				w = _textWidth;
			else
				w = this.width;

			if(_heightAutoSize)
			{
				h = _textHeight;
				if(!_widthAutoSize)
					renderTextField.height = _textHeight+_fontAdjustment+3;
			}
			else
			{
				h = this.height;
				var h2:int = Math.ceil(h);
				if(h2>0 && h2<_minHeight)
				{
					h2 = _minHeight;
					h = h2;
				}
				if(_textHeight>h2)
					_textHeight = h2;
				renderTextField.height = _textHeight+_fontAdjustment+3;
			}

			if(updateBounds)
			{
				_updatingSize = true;
				this.setSize(w,h);
				_updatingSize = false;
				
				doAlign();
			}
			
			_canvas.renderText(renderTextField, _textWidth, _textHeight, _fontAdjustment, clearCanvas);
			renderTextField.text = "";
		}
		
		protected function updateTextFieldText():void
		{
			if(_displayAsPassword)
			{
				var str:String = "";
				var cnt:int = _text.length;
				for(var i:int=0;i<cnt;i++)
					str += "*";
				renderTextField.text = str; 
			}
			else if(_ubbEnabled)
				renderTextField.htmlText = ToolSet.parseUBB(ToolSet.encodeHTML(_text));
			else
				renderTextField.text = _text;
		}
		
		private function clearCanvas():void
		{
			if(_canvas.textureMemory>0)
			{
				_canvas.clear();
				_requireRender = true;
			}
		}
		
		private function renderWithBitmapFont(updateBounds:Boolean):void
		{
			if(!_lines)
				_lines = new Vector.<LineInfo>();
			else
				LineInfo.returnList(_lines);
			
			var letterSpacing:int = _letterSpacing;
			var lineSpacing:int = _leading - 1;
			var fontSize:int = int(_textFormat.size);
			var rectWidth:int = this.width - GUTTER_X * 2;
			var lineWidth:int = 0, lineHeight:int = 0, lineTextHeight:int = 0;
			var glyphWidth:int = 0, glyphHeight:int = 0;
			var wordChars:int = 0, wordStart:int = 0, wordEnd:int = 0;
			var lastLineHeight:int = 0;
			var lineBuffer:String = "";
			var lineY:int = GUTTER_Y;
			var line:LineInfo;
			var textWidth:int, textHeight:int;
			var wordWrap:Boolean = !_widthAutoSize && !_singleLine;
			
			var textLength:int = _text.length;
			for (var offset:int = 0; offset < textLength; ++offset)
			{
				var ch:String = _text.charAt(offset);
				var cc:int = ch.charCodeAt(offset);
				
				if (ch == "\n")
				{
					lineBuffer += ch;
					line = LineInfo.borrow();
					line.width = lineWidth;
					if (lineTextHeight == 0)
					{
						if (lastLineHeight == 0)
							lastLineHeight = fontSize;
						if (lineHeight == 0)
							lineHeight = lastLineHeight;
						lineTextHeight = lineHeight;
					}
					line.height = lineHeight;
					lastLineHeight = lineHeight;
					line.textHeight = lineTextHeight;
					line.text = lineBuffer;
					line.y = lineY;
					lineY += (line.height + lineSpacing);
					if (line.width > textWidth)
						textWidth = line.width;
					_lines.push(line);
					
					lineBuffer = "";
					lineWidth = 0;
					lineHeight = 0;
					lineTextHeight = 0;
					wordChars = 0;
					wordStart = 0;
					wordEnd = 0;
					continue;
				}
				
				if (cc > 256 || cc <= 32)
				{
					if (wordChars > 0)
						wordEnd = lineWidth;
					wordChars = 0;
				}
				else
				{
					if (wordChars == 0)
						wordStart = lineWidth;
					wordChars++;
				}
				
				if(ch==" ")
				{
					glyphWidth = fontSize/2;
					glyphHeight = fontSize;
				}
				else
				{
					var glyph:BMGlyph = _bitmapFont.glyphs[ch];				
					if(glyph)
					{
						glyphWidth = glyph.advance;
						glyphHeight = glyph.lineHeight;
					}
					else if(ch==" ")
					{
						glyphWidth = Math.ceil(_bitmapFont.lineHeight/2);
						glyphHeight = _bitmapFont.lineHeight;
					}
					else
					{
						glyphWidth = 0;
						glyphHeight = 0;
					}
				}
				if (glyphHeight > lineTextHeight)
					lineTextHeight = glyphHeight;
				
				if (glyphHeight > lineHeight)
					lineHeight = glyphHeight;
				
				if (lineWidth != 0)
					lineWidth += letterSpacing;
				lineWidth += glyphWidth;
				
				if (!wordWrap || lineWidth <= rectWidth)
				{
					lineBuffer += ch;
				}
				else
				{
					line = LineInfo.borrow();
					line.height = lineHeight;
					line.textHeight = lineTextHeight;
					
					if (lineBuffer.length == 0) //the line cannt fit even a char
					{
						line.text = ch;
					}
					else if (wordChars > 0 && wordEnd > 0) //if word had broken, move it to new line
					{
						lineBuffer += ch;
						var len:int = lineBuffer.length - wordChars;
						line.text = ToolSet.trimRight(lineBuffer.substr(0, len));
						line.width = wordEnd;
						lineBuffer = lineBuffer.substr(len+1);	
						lineWidth -= wordStart;
					}
					else
					{
						line.text = lineBuffer;
						line.width = lineWidth - (glyphWidth + letterSpacing);
						lineBuffer = ch;
						lineWidth = glyphWidth;
						lineHeight = glyphHeight;
						lineTextHeight = glyphHeight;
					}
					line.y = lineY;
					lineY += (line.height + lineSpacing);
					if (line.width > textWidth)
						textWidth = line.width;
					
					wordChars = 0;
					wordStart = 0;
					wordEnd = 0;
					_lines.push(line);
				}
			}
			
			if (lineBuffer.length > 0
				|| _lines.length>0 && ToolSet.endsWith(_lines[_lines.length - 1].text, "\n"))
			{
				line = LineInfo.borrow();
				line.width = lineWidth;
				if (lineHeight == 0)
					lineHeight = lastLineHeight;
				if (lineTextHeight == 0)
					lineTextHeight = lineHeight;
				line.height = lineHeight;
				line.textHeight = lineTextHeight;
				line.text = lineBuffer;
				line.y = lineY;
				if (line.width > textWidth)
					textWidth = line.width;
				_lines.push(line);
			}
			
			if (textWidth > 0)
				textWidth += GUTTER_X * 2;
			
			var count:int = _lines.length;
			if(count==0)
			{
				textHeight = 0;
			}
			else
			{
				line = _lines[_lines.length - 1];
				textHeight = line.y + line.height + GUTTER_Y;
			}
			
			var w:int, h:int;
			if(_widthAutoSize)
			{
				if(textWidth==0)
					w = 0;
				else
					w = textWidth;
			}
			else
				w = this.width;
			
			if(_heightAutoSize)
			{
				if(textHeight==0)
					h = 0;
				else
					h = textHeight;
			}
			else
				h = this.height;;
			
			if(updateBounds)
			{
				_updatingSize = true;
				this.setSize(w,h);
				_updatingSize = false;
				
				doAlign();
			}
			
			_canvas.clear();
			_canvas.setSize(w, h);
			
			if(w==0 || h==0)
				return;
			
			var charX:int = GUTTER_X;
			var lineIndent:int;
			var charIndent:int;
			
			var lineCount:int = _lines.length;
			for(var i:int=0;i<lineCount;i++)
			{
				line = _lines[i];
				charX = GUTTER_X;
				
				if (_align ==  AlignType.Center)
					lineIndent = (rectWidth - line.width) / 2;
				else if (_align == AlignType.Right)
					lineIndent = rectWidth - line.width;
				else
					lineIndent = 0;
				textLength = line.text.length;
				for (var j:int = 0; j < textLength; j++)
				{
					ch = line.text.charAt(j);
					
					glyph = _bitmapFont.glyphs[ch];
					if (glyph != null)
					{
						charIndent = (line.height + line.textHeight) / 2 - glyph.lineHeight;
						sHelperPoint.x = charX + lineIndent;
						sHelperPoint.y = line.y + charIndent;
						_canvas.drawChar(_bitmapFont, glyph, sHelperPoint, _color);
						
						charX += letterSpacing + glyph.advance;
					}
					else if(ch==" ")
					{
						charX += letterSpacing + Math.ceil(_bitmapFont.lineHeight/2);
					}
					else
					{
						charX += letterSpacing;
					}
				}//text loop
			}//line loop
		}
		
		override protected function handleXYChanged():void
		{
			displayObject.x = this.x;
			displayObject.y = this.y+_yOffset;
		}
		
		override protected function handleSizeChanged():void
		{
			if(!_updatingSize)
			{
				if(!_widthAutoSize)
					render();
				else
					doAlign();
			}
		}
		
		override protected function handleGrayChanged():void
		{
			if(_bitmapFont!=null)
				super.handleGrayChanged();
			
			updateTextFormat();
		}
		
		private function doAlign():void
		{
			if(_verticalAlign==VertAlignType.Top || _textHeight==0)
				_yOffset = 0;
			else
			{
				var dh:Number = this.height-_textHeight;
				if(dh<0)
					dh = 0;
				if(_verticalAlign==VertAlignType.Middle)
					_yOffset = int(dh/2)-_fontAdjustment;
				else
					_yOffset = int(dh)-_fontAdjustment;
			}
			displayObject.y = this.y+_yOffset;
		}
		
		override public function setup_beforeAdd(xml:XML):void
		{
			super.setup_beforeAdd(xml);

			var str:String;
			_displayAsPassword = xml.@password=="true";
			str = xml.@font;
			if(str)
				_font = str;
			
			str = xml.@fontSize;
			if(str)
				_fontSize = parseInt(str);

			str = xml.@color;
			if(str)
				_color = ToolSet.convertFromHtmlColor(str);
			
			str = xml.@align;
			if(str)
				_align = AlignType.parse(str);
			
			str = xml.@vAlign;
			if(str)
				_verticalAlign = VertAlignType.parse(str);
			
			str = xml.@leading;
			if(str)
				_leading = parseInt(str);
			else
				_leading = 3;
			
			str = xml.@letterSpacing;
			if(str)
				_letterSpacing = parseInt(str);
			
			_ubbEnabled = xml.@ubb=="true";
			
			str = xml.@autoSize;
			if(str)
			{
				_autoSize = AutoSizeType.parse(str);
				_widthAutoSize = _autoSize==AutoSizeType.Both;
				_heightAutoSize = _autoSize==AutoSizeType.Both||_autoSize==AutoSizeType.Height;
			}

			_underline = xml.@underline == "true";
			_italic = xml.@italic == "true";
			_bold = xml.@bold == "true";
			_singleLine = xml.@singleLine == "true";
			str = xml.@strokeColor;
			if(str)
			{
				_strokeColor = ToolSet.convertFromHtmlColor(str);
				_stroke = true;
				_textFilters = createStrokeFilters(_strokeColor);
			}
		}
		
		override public function setup_afterAdd(xml:XML):void
		{
			super.setup_afterAdd(xml);
			
			updateTextFormat();
			var str:String =  xml.@text;
			if(str)
				this.text = str; 		
			_sizeDirty = false;
			
			var cxml:XML = xml.gearColor[0];
			if(cxml)
				_gearColor.setup(cxml);
		}
	}
}

class LineInfo
{
	public var width:int;
	public var height:int;
	public var textHeight:int;
	public var text:String;
	public var y:int;
	
	private static var pool:Array = [];
	
	public static function borrow():LineInfo
	{
		if(pool.length)
		{
			var ret:LineInfo = pool.pop();
			ret.width = 0;
			ret.height = 0;
			ret.textHeight = 0;
			ret.text = null;
			ret.y = 0;
			return ret;
		}
		else
			return new LineInfo();
	}
	
	public static function returns(value:LineInfo):void
	{
		pool.push(value);
	}
	
	public static function returnList(value:Vector.<LineInfo>):void
	{
		for each(var li:LineInfo in value)
		{
			pool.push(li);
		}
		value.length = 0;
	}
	
	public function LineInfo()
	{
	}
}

