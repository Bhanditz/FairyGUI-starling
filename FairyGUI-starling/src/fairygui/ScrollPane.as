package fairygui
{
	import com.greensock.TweenLite;
	import com.greensock.easing.Ease;
	import com.greensock.easing.EaseLookup;
	
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Mouse;
	import flash.utils.getTimer;
	
	import fairygui.event.GTouchEvent;
	import fairygui.utils.GTimers;
	
	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.events.Event;
	
	public class ScrollPane
	{
		private var _owner:GComponent;
		private var _container:Sprite;
		private var _maskHolder:Sprite;
		private var _maskContentHolder:Sprite;

		private var _maskWidth:Number;
		private var _maskHeight:Number;
		private var _contentWidth:Number;
		private var _contentHeight:Number;
	
		private var _scrollType:int;
		private var _scrollSpeed:int;
		private var _mouseWheelSpeed:int;
		private var _margin:Margin;
		private var _scrollBarMargin:Margin;
		private var _bouncebackEffect:Boolean;
		private var _touchEffect:Boolean;
		private var _scrollBarDisplayAuto:Boolean;
		private var _vScrollNone:Boolean;
		private var _hScrollNone:Boolean;
		
		private var _displayOnLeft:Boolean;
		private var _snapToItem:Boolean;
		private var _displayInDemand:Boolean;
		private var _mouseWheelEnabled:Boolean;
		
		private var _yPerc:Number;
		private var _xPerc:Number;
		private var _vScroll:Boolean;
		private var _hScroll:Boolean;
		
		private static var _easeTypeFunc:Ease;
		private var _throwTween:ThrowTween;
		private var _tweening:int;
		
		private var _time1:uint, _time2:uint;
		private var _y1:Number, _y2:Number, _yOverlap:Number, _yOffset:Number;
		private var _x1:Number, _x2:Number, _xOverlap:Number, _xOffset:Number;
		
		private var _isMouseMoved:Boolean;
		private var _holdAreaPoint:Point;
		private var _isHoldAreaDone:Boolean;
		private var _aniFlag:Boolean;
		private var _scrollBarVisible:Boolean;
		
		private var _hzScrollBar:GScrollBar;
		private var _vtScrollBar:GScrollBar;
		
		private static var sHelperPoint:Point = new Point();
		
		public function ScrollPane(owner:GComponent, 
								   scrollType:int,
								   margin:Margin,
								   scrollBarMargin:Margin,
								   scrollBarDisplay:int,
								   flags:int,								   
								   vtScrollBarRes:String,
								   hzScrollBarRes:String):void
		{	
			if(_easeTypeFunc==null)
				_easeTypeFunc = EaseLookup.find("Cubic.easeOut");
			_throwTween = new ThrowTween();
			
			_owner = owner;
			_container = _owner._rootContainer;
			
			_maskHolder = new Sprite();
			_container.addChild(_maskHolder);
	
			_maskContentHolder = _owner._container;
			_maskContentHolder.x = 0;
			_maskContentHolder.y = 0;
			_maskHolder.addChild(_maskContentHolder);

			_holdAreaPoint = new Point();
			_margin = margin;
			_scrollBarMargin = scrollBarMargin;
			_bouncebackEffect = UIConfig.defaultScrollBounceEffect;
			_touchEffect = UIConfig.defaultScrollTouchEffect;
			_xPerc = 0;
			_yPerc = 0;
			_aniFlag = true;
			_scrollBarVisible = true;
			_scrollSpeed = UIConfig.defaultScrollSpeed;
			_mouseWheelSpeed = _scrollSpeed*2;
			_displayOnLeft = (flags & 1)!=0;
			_snapToItem = (flags & 2)!=0;
			_displayInDemand = (flags & 4)!=0;
			_scrollType = scrollType;
			_mouseWheelEnabled = true;
			
			if(scrollBarDisplay==ScrollBarDisplayType.Default)
				scrollBarDisplay = UIConfig.defaultScrollBarDisplay;
			
			if(scrollBarDisplay!=ScrollBarDisplayType.Hidden)
			{
				if(_scrollType==ScrollType.Both || _scrollType==ScrollType.Vertical)
				{
					var res:String = vtScrollBarRes?vtScrollBarRes:UIConfig.verticalScrollBar;
					if(res)
					{
						_vtScrollBar = UIPackage.createObjectFromURL(res) as GScrollBar;
						if(!_vtScrollBar)
							throw new Error("cannot create scrollbar from " + res);
						_vtScrollBar.setScrollPane(this, true);
						_container.addChild(_vtScrollBar.displayObject);
					}
				}
				if(_scrollType==ScrollType.Both || _scrollType==ScrollType.Horizontal)
				{
					res = hzScrollBarRes?hzScrollBarRes:UIConfig.horizontalScrollBar;
					if(res)
					{
						_hzScrollBar = UIPackage.createObjectFromURL(res) as GScrollBar;
						if(!_hzScrollBar)
							throw new Error("cannot create scrollbar from " + res);
						_hzScrollBar.setScrollPane(this, false);
						_container.addChild(_hzScrollBar.displayObject);
					}
				}
				
				_scrollBarDisplayAuto = scrollBarDisplay==ScrollBarDisplayType.Auto;
				if(_scrollBarDisplayAuto)
				{
					_scrollBarVisible = false;
					if(_vtScrollBar)
						_vtScrollBar.displayObject.visible = false;
					if(_hzScrollBar)
						_hzScrollBar.displayObject.visible = false;
					
					if(Mouse.supportsCursor)
					{
						_owner.addEventListener(GTouchEvent.ROLL_OVER, __rollOver);
						_owner.addEventListener(GTouchEvent.ROLL_OUT, __rollOut);
					}
				}
			}
			else
				_mouseWheelEnabled = false;
			
			if(_displayOnLeft && _vtScrollBar)
				_maskHolder.x = int(_margin.left + _vtScrollBar.width);
			else
				_maskHolder.x = _margin.left;
			_maskHolder.y = _margin.top;
			
			_contentWidth = 0;
			_contentHeight = 0;
			setSize(owner.width, owner.height);
			setContentSize(owner.bounds.width, owner.bounds.height);
			
			Starling.current.nativeStage.addEventListener(MouseEvent.MOUSE_WHEEL, __mouseWheel);
			_owner.addEventListener(GTouchEvent.BEGIN, __mouseDown);
			_owner.addEventListener(GTouchEvent.END, __mouseUp);
		}
		
		public function dispose():void
		{
			Starling.current.nativeStage.removeEventListener(MouseEvent.MOUSE_WHEEL, __mouseWheel);
			
			_owner.removeEventListener(GTouchEvent.BEGIN, __mouseDown);
			_owner.removeEventListener(GTouchEvent.DRAG, __mouseMove);
			_owner.removeEventListener(GTouchEvent.END, __mouseUp);
			_owner.removeEventListener(GTouchEvent.ROLL_OVER, __rollOver);
			_owner.removeEventListener(GTouchEvent.ROLL_OUT, __rollOut);
			_container.removeChildren();
			_maskContentHolder.x = 0;
			_maskContentHolder.y = 0;
			_container.addChild(_maskContentHolder);
		}
		
		public function get owner():GComponent
		{
			return _owner;
		}
		
		public function get bouncebackEffect():Boolean
		{
			return _bouncebackEffect;
		}
		
		public function set bouncebackEffect(sc:Boolean):void
		{
			_bouncebackEffect = sc;
		}
		
		public function get touchEffect():Boolean
		{
			return _touchEffect;
		}
		
		public function set touchEffect(sc:Boolean):void
		{
			_touchEffect = sc;
		}
		
		public function set scrollSpeed(val:int):void
		{
			_scrollSpeed = val;
			if(_scrollSpeed==0)
				_scrollSpeed = UIConfig.defaultScrollSpeed;
			_mouseWheelSpeed = _scrollSpeed*2;
		}
		
		public function get scrollSpeed():int
		{
			return _scrollSpeed;
		}
		
		public function get snapToItem():Boolean
		{
			return _snapToItem;
		}
		
		public function set snapToItem(value:Boolean):void
		{
			_snapToItem = value;
		}
		
		public function get mouseWheelEnabled():Boolean
		{
			return _mouseWheelEnabled;
		}
		
		public function set mouseWheelEnabled(value:Boolean):void
		{
			_mouseWheelEnabled = value;
		}
		
		public function get percX():Number
		{
			return _xPerc;
		}
		
		public function set percX(sc:Number):void
		{
			setPercX(sc, false);
		}
		
		public function setPercX(sc:Number, ani:Boolean=false):void
		{
			if(sc>1)
				sc = 1;
			else if(sc<0)
				sc = 0;
			if(sc != _xPerc)
			{
				_xPerc = sc;
				_owner.dispatchEventWith(Event.SCROLL);
				posChanged(ani);				
			}
		}
		
		public function get percY():Number
		{
			return _yPerc;
		}
		
		public function set percY(sc:Number):void
		{
			setPercY(sc, false);
		}
		
		public function setPercY(sc:Number, ani:Boolean=false):void
		{
			if(sc>1)
				sc = 1;
			else if(sc<0)
				sc = 0;
			if(sc != _yPerc)
			{
				_yPerc = sc;
				_owner.dispatchEventWith(Event.SCROLL);
				posChanged(ani);
			}
		}
		
		public function get posX():Number
		{
			return _xPerc*Math.max(0, _contentWidth-_maskWidth);
		}
		
		public function set posX(val:Number):void 
		{
			setPosX(val, false);
		}
		
		public function setPosX(val:Number, ani:Boolean=false):void
		{
			if (_contentWidth > _maskWidth)
				this.setPercX(val/(_contentWidth-_maskWidth), ani);
			else
				this.setPercX(0, ani);
		}
		
		public function get posY():Number 
		{
			return _yPerc*Math.max(0, _contentHeight-_maskHeight);
		}
		
		public function set posY(val:Number):void
		{
			setPosY(val, false);
		}
		
		public function setPosY(val:Number, ani:Boolean=false):void
		{
			if (_contentHeight > _maskHeight)
				this.setPercY(val/(_contentHeight-_maskHeight), ani);
			else
				this.setPercY(0, ani);
		}

		public function get isBottomMost():Boolean
		{
			return _yPerc==1 || _contentHeight<=_maskHeight;
		}
		
		public function get isRightMost():Boolean
		{
			return _xPerc==1 || _contentWidth<=_maskWidth;
		}
		
		public function get contentWidth():Number
		{
			_owner.ensureBoundsCorrect();
			return _contentWidth;
		}
		
		public function get contentHeight():Number
		{
			_owner.ensureBoundsCorrect();
			return _contentHeight;
		}
		
		public function get viewWidth():int
		{
			return _maskWidth;
		}
		
		public function set viewWidth(value:int):void
		{
			value = value + _margin.left + _margin.right;
			if (_vtScrollBar != null)
				value += _vtScrollBar.width;
			_owner.width = value;
		}
		
		public function get viewHeight():int
		{
			return _maskHeight;
		}
		
		public function set viewHeight(value:int):void
		{
			value = value + _margin.top + _margin.bottom;
			if (_hzScrollBar != null)
				value += _hzScrollBar.height;
			_owner.height = value;
		}
		
		private function getDeltaX(move:Number):Number
		{
			return move/(_contentWidth-_maskWidth);
		}
		
		private function getDeltaY(move:Number):Number
		{
			return move/(_contentHeight-_maskHeight);
		}
		
		public function scrollTop(ani:Boolean=false):void 
		{
			this.setPercY(0, ani);
		}
		
		public function scrollBottom(ani:Boolean=false):void 
		{
			this.setPercY(1, ani);
		}
		
		public function scrollUp(speed:Number=1, ani:Boolean=false):void 
		{
			this.setPercY(_yPerc - getDeltaY(_scrollSpeed*speed), ani);
		}
		
		public function scrollDown(speed:Number=1, ani:Boolean=false):void
		{
			this.setPercY(_yPerc + getDeltaY(_scrollSpeed*speed), ani);
		}
		
		public function scrollLeft(speed:Number=1, ani:Boolean=false):void
		{
			this.setPercX(_xPerc - getDeltaX(_scrollSpeed*speed), ani);
		}
		
		public function scrollRight(speed:Number=1, ani:Boolean=false):void　
		{
			this.setPercX(_xPerc + getDeltaX(_scrollSpeed*speed), ani);
		}
		
		public function scrollToView(obj:GObject, ani:Boolean=false):void
		{
			_owner.ensureBoundsCorrect();
			if(GTimers.inst.exists(refresh))
				refresh();
			
			if(_vScroll)
			{
				var top:Number = (_contentHeight-_maskHeight)*_yPerc;
				var bottom:Number = top+_maskHeight;
				if(obj.y<top)
					this.setPosY(obj.y, ani);
				else if(obj.y+obj.height>bottom)
				{
					if (obj.y + obj.height * 2 >= top)
						this.setPosY(obj.y+obj.height*2-_maskHeight, ani);
					else
						this.setPosY(obj.y+obj.height-_maskHeight, ani);
				}
			}
			if(_hScroll)
			{
				var left:Number = (_contentWidth-_maskWidth)*_xPerc;
				var right:Number = left+_maskWidth;
				if(obj.x<left)
					this.setPosX(obj.x, ani);
				else if(obj.x+obj.width>right)
				{
					if (obj.x + obj.width * 2 >= left)
						this.setPosX(obj.x+obj.width*2-_maskWidth, ani);
					else
						this.setPosX(obj.x+obj.width-_maskWidth, ani);
				}
			}
			
			if(!ani && GTimers.inst.exists(refresh))
				refresh();
		}
		
		public function isChildInView(obj:GObject):Boolean
		{
			if(_vScroll)
			{
				var top:Number = (_contentHeight-_maskHeight)*_yPerc;
				var bottom:Number = top+_maskHeight;
				if(obj.y+obj.height<top || obj.y>bottom)
					return false;
			}
			
			if(_hScroll)
			{
				var left:Number = (_contentWidth-_maskWidth)*_xPerc;
				var right:Number = left+_maskWidth;
				if(obj.x+obj.width<left || obj.x>right)
					return false;
			}
			
			return true;
		}

		internal function setSize(aWidth:Number, aHeight:Number):void 
		{
			if(_hzScrollBar)
			{
				_hzScrollBar.y = aHeight - _hzScrollBar.height;
				if(_vtScrollBar)
				{
					_hzScrollBar.width = aWidth - _vtScrollBar.width - _scrollBarMargin.left - _scrollBarMargin.right;
					if(_displayOnLeft)
						_hzScrollBar.x = _scrollBarMargin.left + _vtScrollBar.width;
					else
						_hzScrollBar.x = _scrollBarMargin.left;
				}
				else
				{
					_hzScrollBar.width = aWidth - _scrollBarMargin.left - _scrollBarMargin.right;
					_hzScrollBar.x = _scrollBarMargin.left;
				}
			}
			if(_vtScrollBar)
			{
				if(!_displayOnLeft)
					_vtScrollBar.x = aWidth - _vtScrollBar.width;
				if(_hzScrollBar)
					_vtScrollBar.height = aHeight - _hzScrollBar.height - _scrollBarMargin.top - _scrollBarMargin.bottom;
				else
					_vtScrollBar.height = aHeight - _scrollBarMargin.top - _scrollBarMargin.bottom;
				_vtScrollBar.y = _scrollBarMargin.top;
			}
			
			_maskWidth = aWidth;
			_maskHeight = aHeight;
			if(_hzScrollBar && !_hScrollNone)
				_maskHeight -= _hzScrollBar.height;
			if(_vtScrollBar && !_vScrollNone)
				_maskWidth -= _vtScrollBar.width;
			_maskWidth -= (_margin.left+_margin.right);
			_maskHeight -= (_margin.top+_margin.bottom);
			
			_maskWidth = Math.max(1, _maskWidth);
			_maskHeight = Math.max(1, _maskHeight);
			
			handleSizeChanged();
			posChanged(false);
		}

		internal function setContentSize(aWidth:Number, aHeight:Number):void
		{
			if(_contentWidth==aWidth && _contentHeight==aHeight)
				return;
			
			_contentWidth = aWidth;
			_contentHeight = aHeight;
			handleSizeChanged();
			_aniFlag = false;
			refresh();
		}
		
		private function handleSizeChanged():void
		{
			if(_displayInDemand)
			{
				if(_vtScrollBar)
				{
					if(_contentHeight<=_maskHeight)
					{
						if(!_vScrollNone)
						{
							_vScrollNone = true;
							_maskWidth += _vtScrollBar.width;
						}
					}
					else
					{
						if(_vScrollNone)
						{
							_vScrollNone = false;
							_maskWidth -= _vtScrollBar.width;
						}
					}
				}
				if(_hzScrollBar)
				{
					if(_contentWidth<=_maskWidth)
					{
						if(!_hScrollNone)
						{
							_hScrollNone = true;
							_maskHeight += _vtScrollBar.height;
						}
					}
					else
					{
						if(_hScrollNone)
						{
							_hScrollNone = false;
							_maskHeight -= _vtScrollBar.height;
						}
					}
				}
			}
			
			if(_vtScrollBar)
			{
				if(_maskHeight<_vtScrollBar.minSize)
					//没有使用_vtScrollBar.visible是因为ScrollBar用了一个trick，它并不在owner的DisplayList里，因此_vtScrollBar.visible是无效的
					_vtScrollBar.displayObject.visible = false;
				else
				{
					_vtScrollBar.displayObject.visible = _scrollBarVisible && !_vScrollNone;
					if(_contentHeight==0)
						_vtScrollBar.displayPerc = 0;
					else
						_vtScrollBar.displayPerc = Math.min(1, _maskHeight/_contentHeight);
				}
			}
			if(_hzScrollBar)
			{
				if(_maskWidth<_hzScrollBar.minSize)
					_hzScrollBar.displayObject.visible = false;
				else
				{
					_hzScrollBar.displayObject.visible = _scrollBarVisible && !_hScrollNone;
					if(_contentWidth==0)
						_hzScrollBar.displayPerc = 0;
					else
						_hzScrollBar.displayPerc = Math.min(1, _maskWidth/_contentWidth);
				}
			}
			
			_maskHolder.clipRect = new Rectangle(0,0,_maskWidth,_maskHeight);
			
			_xOverlap = Math.ceil(Math.max(0, _contentWidth - _maskWidth));
			_yOverlap = Math.ceil(Math.max(0, _contentHeight - _maskHeight));
			
			switch(_scrollType)
			{
				case ScrollType.Both:
					
					if(_contentWidth > _maskWidth && _contentHeight <= _maskHeight)
					{
						_hScroll = true;
						_vScroll = false;
					}
					else if(_contentWidth <= _maskWidth && _contentHeight > _maskHeight)
					{
						_hScroll = false;
						_vScroll = true;
					}
					else if(_contentWidth > _maskWidth && _contentHeight > _maskHeight)
					{
						_hScroll = true;
						_vScroll = true;
					}
					else
					{
						_hScroll = false;
						_vScroll = false;
					}
					break;
				
				case ScrollType.Vertical:
					
					if(_contentHeight > _maskHeight)
					{
						_hScroll = false;
						_vScroll = true;
					}
					else
					{
						_hScroll = false;
						_vScroll = false;
					}
					break;
				
				case ScrollType.Horizontal:
					
					if(_contentWidth > _maskWidth)
					{
						_hScroll = true;
						_vScroll = false;
					}
					else
					{
						_hScroll = false;
						_vScroll = false;
					}
					break;
			}
		}
		
		private function posChanged(ani:Boolean):void
		{
			if(_aniFlag)
				_aniFlag = ani;
			GTimers.inst.callLater(refresh);
		}
		
		private function refresh():void
		{
			if(_isMouseMoved)
			{
				GTimers.inst.callLater(refresh);
				return;
			}
			GTimers.inst.remove(refresh);
			
			var contentYLoc:Number;
			var contentXLoc:Number;

			if(_vScroll)
				contentYLoc = _yPerc * (_contentHeight - _maskHeight);
			if(_hScroll)
				contentXLoc = _xPerc * (_contentWidth - _maskWidth);
			
			if(_snapToItem)
			{
				var pt:Point = _owner.findObjectNear(_xPerc==1?0:contentXLoc, _yPerc==1?0:contentYLoc, sHelperPoint);
				var scrolled:Boolean = false;
				if (_xPerc != 1 && pt.x!=contentXLoc)
				{
					_xPerc = pt.x / (_contentWidth - _maskWidth);
					if(_xPerc>1)
						_xPerc = 1;
					contentXLoc = _xPerc * (_contentWidth - _maskWidth);
					scrolled = true;
				}
				if (_yPerc != 1 && pt.y!=contentYLoc)
				{
					_yPerc = pt.y / (_contentHeight - _maskHeight);
					if(_yPerc>1)
						_yPerc = 1;
					contentYLoc = _yPerc * (_contentHeight - _maskHeight);
					scrolled = true;
				}
				if(scrolled)
					_owner.dispatchEventWith(Event.SCROLL);
			}
			contentXLoc = int(contentXLoc);
			contentYLoc = int(contentYLoc);
			
			if(_aniFlag)
			{
				var toX:Number = _maskContentHolder.x;
				var toY:Number = _maskContentHolder.y;
				if(_vScroll)
				{
					toY = -contentYLoc;
				}
				else
				{
					if(_maskContentHolder.y!=0)
						_maskContentHolder.y = 0;
				}
				if(_hScroll)
				{
					toX = -contentXLoc;
				}
				else
				{
					if(_maskContentHolder.x!=0)
						_maskContentHolder.x = 0;
				}
				
				if(toX!=_maskContentHolder.x || toY!=_maskContentHolder.y)
				{
					killTweens();
					
					_maskHolder.touchable = false;
					_tweening = 1;
					
					TweenLite.to(_maskContentHolder, 0.5, { x:toX, y:toY,
						onUpdate:__tweenUpdate, onComplete:__tweenComplete, 
						ease:_easeTypeFunc } );
				}
			}
			else
			{
				killTweens();
				
				if(_vScroll)
					_maskContentHolder.y = -contentYLoc;
				else
					_maskContentHolder.y = 0;
				if(_hScroll)
					_maskContentHolder.x = -contentXLoc;
				else
					_maskContentHolder.x = 0;
				if(_vtScrollBar)
					_vtScrollBar.scrollPerc = _yPerc;
				if(_hzScrollBar)
					_hzScrollBar.scrollPerc = _xPerc;
			}
			
			_aniFlag = true;
		}
		
		private function killTweens():void
		{
			if(_tweening==1)
			{
				TweenLite.killTweensOf(_maskContentHolder);
				__tweenComplete();
			}
			else if(_tweening==2)
			{
				TweenLite.killTweensOf(_throwTween);
				_throwTween.value = 1;
				__tweenUpdate2();
				__tweenComplete2();
			}
			_tweening = 0;
		}
		
		private function calcYPerc():Number
		{
			if(!_vScroll)
				return 0;
			
			var diff:Number = _contentHeight - _maskHeight;
			var my:Number = _maskContentHolder.y;
			var currY: Number;
			if (my > 0) 
				currY = 0;
			else if ( -my > diff)
				currY = diff;
			else
				currY = -my;
			
			return currY / diff;
		}
		
		private function calcXPerc():Number
		{
			if (!_hScroll)
				return 0;
			
			var diff:Number = _contentWidth - _maskWidth;
			var mx:Number = _maskContentHolder.x;
			var currX: Number;
			if (mx > 0)
				currX = 0;
			else if ( -mx > diff)
				currX = diff;
			else
				currX = -mx;

			return currX / diff;
		}
		
		private function onScrolling():void
		{
			if(_vtScrollBar)
			{
				_vtScrollBar.scrollPerc = calcYPerc();
				if(_scrollBarDisplayAuto)
					showScrollBar(true);
			}
			if(_hzScrollBar)
			{
				_hzScrollBar.scrollPerc = calcXPerc();
				if(_scrollBarDisplayAuto)
					showScrollBar(true);
			}
		}
		
		private function onScrollEnd():void
		{
			if(_vtScrollBar)
			{
				if(_scrollBarDisplayAuto)
					showScrollBar(false);
			}
			if(_hzScrollBar)
			{
				if(_scrollBarDisplayAuto)
					showScrollBar(false);
			}
			_tweening = 0;
		}

		private function __mouseDown(evt:GTouchEvent):void
		{
			if(!_touchEffect)
				return;
			
			killTweens();
			
			sHelperPoint.x = evt.stageX;
			sHelperPoint.y = evt.stageY;
			_container.globalToLocal(sHelperPoint, sHelperPoint);
			
			_x1 = _x2 = _maskContentHolder.x;
			_y1 = _y2 = _maskContentHolder.y;
			_xOffset = sHelperPoint.x - _maskContentHolder.x;	
			_yOffset = sHelperPoint.y - _maskContentHolder.y;		
			
			_time1 = _time2 = getTimer();
			_holdAreaPoint.x = sHelperPoint.x;
			_holdAreaPoint.y = sHelperPoint.y;
			_isHoldAreaDone = false;
			_isMouseMoved = false;
			
			_owner.addEventListener(GTouchEvent.DRAG, __mouseMove);
		}
		
		private function __mouseMove(evt:GTouchEvent):void
		{
			var sensitivity:int;
			if (GRoot.touchScreen)
				sensitivity = UIConfig.touchScrollSensitivity;
			else
				sensitivity = 5;
			
			var diff:Number;
			var sv:Boolean, sh:Boolean, st:Boolean;

			sHelperPoint.x = evt.stageX;
			sHelperPoint.y = evt.stageY;
			_container.globalToLocal(sHelperPoint, sHelperPoint);
			
			if (_scrollType == ScrollType.Vertical) 
			{
				if (!_isHoldAreaDone)
				{
					diff = Math.abs(_holdAreaPoint.y - sHelperPoint.y);
					if (diff < sensitivity)
						return;
				}
				
				sv = true;
			}
			else if (_scrollType == ScrollType.Horizontal) 
			{
				if (!_isHoldAreaDone)
				{
					diff = Math.abs(_holdAreaPoint.x - sHelperPoint.x);
					if (diff < sensitivity)
						return;
				}
				
				sh = true;
			}
			else
			{
				if (!_isHoldAreaDone)
				{
					diff = Math.abs(_holdAreaPoint.y - sHelperPoint.y);
					if (diff < sensitivity)
					{
						diff = Math.abs(_holdAreaPoint.x - sHelperPoint.x);
						if (diff < sensitivity)
							return;
					}
				}
				
				sv = sh = true;
			}
			
			var t:uint = getTimer();
			if (t - _time2 > 50)
			{
				_time2 = _time1;
				_time1 = t;
				st = true;
			}

			if(sv)
			{
				var y:int = sHelperPoint.y - _yOffset;
				if (y > 0) 
				{
					if (!_bouncebackEffect)
						_maskContentHolder.y = 0;
					else
						_maskContentHolder.y = int(y * 0.5);
				}
				else if (y < -_yOverlap) 
				{
					if (!_bouncebackEffect)
						_maskContentHolder.y = -int(_yOverlap);
					else
						_maskContentHolder.y = int((y- _yOverlap) * 0.5);
				}
				else 
				{
					_maskContentHolder.y = y;
				}
				
				if (st)
				{
					_y2 = _y1;
					_y1 = _maskContentHolder.y;
				}
				
				_yPerc = calcYPerc(); 
			}
			
			if(sh)
			{
				var x:int = sHelperPoint.x - _xOffset;
				if (x > 0) 
				{
					if (!_bouncebackEffect)
						_maskContentHolder.x = 0;
					else
						_maskContentHolder.x = int(x * 0.5);
				}
				else if (x < 0 - _xOverlap) 
				{
					if (!_bouncebackEffect)
						_maskContentHolder.x = -int(_xOverlap);
					else
						_maskContentHolder.x = int( (x - _xOverlap) * 0.5);
				}
				else 
				{
					_maskContentHolder.x = x;
				}

				if (st)
				{
					_x2 = _x1;
					_x1 = _maskContentHolder.x;
				}
				
				_xPerc = calcXPerc();
			}
			
			_maskHolder.touchable = false;
			_isHoldAreaDone = true;
			if(!_isMouseMoved)
			{
				_isMouseMoved = true;
				//cancel children's click
				_owner.cancelChildrenClickEvent();
			}
			onScrolling();
			_owner.dispatchEventWith(Event.SCROLL);
		}
		
		private function __mouseUp(evt:GTouchEvent):void
		{
			if(!_touchEffect)
			{
				_isMouseMoved = false;
				return;
			}
			
			_owner.removeEventListener(GTouchEvent.DRAG, __mouseMove);
			
			if (!_isMouseMoved)
				return;

			_isMouseMoved = false;
			
			var time:Number = (getTimer() - _time2) / 1000;
			if(time==0)
				time = 0.001;
			var yVelocity:Number = (_maskContentHolder.y - _y2) / time;
			var xVelocity:Number = (_maskContentHolder.x - _x2) / time;
			var duration:Number = 0.3;
			var xMin:Number = -_xOverlap;
			var yMin:Number = -_yOverlap;
			var xMax:Number = 0;
			var yMax:Number = 0;	

			_throwTween.start.x = _maskContentHolder.x;
			_throwTween.start.y = _maskContentHolder.y;
			
			var change1:Point = _throwTween.change1;
			var change2:Point = _throwTween.change2;
			var endX:Number = 0;
			var endY:Number = 0;
			
			if(_scrollType==ScrollType.Both || _scrollType==ScrollType.Horizontal)
			{
				change1.x = ThrowTween.calculateChange(xVelocity, duration);
				change2.x = 0;
				endX = _maskContentHolder.x + change1.x;
			}
			else
				change1.x = change2.x = 0;
			
			if(_scrollType==ScrollType.Both || _scrollType==ScrollType.Vertical)
			{
				change1.y = ThrowTween.calculateChange(yVelocity, duration);
				change2.y = 0;
				endY = _maskContentHolder.y + change1.y;
			}
			else
				change1.y = change2.y = 0;
			
			if (_snapToItem)
			{
				endX = -endX;
				endY = -endY;
				var pt:Point = _owner.findObjectNear(endX, endY, sHelperPoint);
				endX = -pt.x;
				endY = -pt.y;
				change1.x = endX - _maskContentHolder.x;
				change1.y = endY - _maskContentHolder.y;
			}
			
			if(_bouncebackEffect)
			{			
				if (xMax < endX)
					change2.x = xMax - _maskContentHolder.x - change1.x;
				else if (xMin > endX)
					change2.x = xMin - _maskContentHolder.x - change1.x;
				
				if (yMax < endY)
					change2.y = yMax - _maskContentHolder.y - change1.y;
				else if (yMin > endY)
					change2.y = yMin - _maskContentHolder.y - change1.y;
			}
			else
			{
				if (xMax < endX)
					change1.x = xMax - _maskContentHolder.x;
				else if (xMin > endX)
					change1.x = xMin - _maskContentHolder.x;
				
				if (yMax < endY)
					change1.y = yMax - _maskContentHolder.y;
				else if (yMin > endY)
					change1.y = yMin - _maskContentHolder.y;
			}
			
			_throwTween.value = 0;
			_throwTween.change1 = change1;
			_throwTween.change2 = change2;
			
			killTweens();
			_tweening = 2;
			
			TweenLite.to(_throwTween, duration, { value:1, 
				onUpdate:__tweenUpdate2, onComplete:__tweenComplete2, 
				ease:_easeTypeFunc } );
		}
		
		private function __mouseWheel(evt:MouseEvent):void
		{
			if(!_mouseWheelEnabled)
				return;
			
			sHelperPoint.x = evt.stageX;
			sHelperPoint.y = evt.stageY;
			_container.globalToLocal(sHelperPoint, sHelperPoint);
			
			if(!_container.hitTest(sHelperPoint, true))
				return;
			
			var delta:Number = evt.delta;
			if(_hScroll && !_vScroll)
			{
				if(delta<0)
					this.setPercX(_xPerc + getDeltaX(_mouseWheelSpeed), false);
				else
					this.setPercX(_xPerc - getDeltaX(_mouseWheelSpeed), false);
			}
			else
			{
				if(delta<0)
					this.setPercY(_yPerc + getDeltaY(_mouseWheelSpeed), false);
				else
					this.setPercY(_yPerc - getDeltaY(_mouseWheelSpeed), false);
			}
		}
		
		private function __rollOver(evt:GTouchEvent):void
		{
			showScrollBar(true);
		}
		
		private function __rollOut(evt:GTouchEvent):void
		{
			showScrollBar(false);
		}
		
		private function showScrollBar(val:Boolean):void
		{
			if(val)
			{
				__showScrollBar(true);
				GTimers.inst.remove(__showScrollBar);
			}
			else
				GTimers.inst.add(500, 1, __showScrollBar, val);
		}
		
		private function __showScrollBar(val:Boolean):void
		{
			_scrollBarVisible = val && _maskWidth>0 && _maskHeight>0;
			if(_vtScrollBar)
				_vtScrollBar.displayObject.visible = _scrollBarVisible &&　!_vScrollNone;
			if(_hzScrollBar)
				_hzScrollBar.displayObject.visible = _scrollBarVisible &&　!_hScrollNone;
		}
		
		private function __tweenUpdate():void
		{
			onScrolling();
		}
		
		private function __tweenComplete():void
		{
			_maskHolder.touchable = true;
			onScrollEnd();
		}

		private function __tweenUpdate2():void
		{
			_throwTween.update(_maskContentHolder);
			
			if (_scrollType == ScrollType.Vertical)
				_yPerc = calcYPerc();
			else if (_scrollType == ScrollType.Horizontal)
				_xPerc = calcXPerc();
			else
			{
				_yPerc = calcYPerc();
				_xPerc = calcXPerc();
			}
			
			onScrolling();
			_owner.dispatchEventWith(Event.SCROLL);
		}
		
		private function __tweenComplete2():void
		{
			if (_scrollType == ScrollType.Vertical)
				_yPerc = calcYPerc();
			else if (_scrollType == ScrollType.Horizontal)
				_xPerc = calcXPerc();
			else
			{
				_yPerc = calcYPerc();
				_xPerc = calcXPerc();
			}

			_maskHolder.touchable = true;
			onScrollEnd();
			_owner.dispatchEventWith(Event.SCROLL);
		}
	}
}

import flash.geom.Point;

import starling.display.DisplayObject;

class ThrowTween
{
	public var value:Number;
	public var start:Point;
	public var change1:Point;
	public var change2:Point;
	
	private static var checkpoint:Number = 0.05;
	
	public function ThrowTween()
	{
		start = new Point();
		change1 = new Point();
		change2 = new Point();
	}
	
	public function update(obj:DisplayObject):void
	{
		obj.x = int(start.x + change1.x * value + change2.x * value * value);
		obj.y = int(start.y + change1.y * value + change2.y * value * value);
	}
	
	static public function calculateChange(velocity:Number, duration:Number):Number
	{
		return (duration * checkpoint * velocity) / easeOutCubic(checkpoint, 0, 1, 1);
	}
	
	static public function easeOutCubic(t:Number, b:Number, c:Number, d:Number):Number
	{
		return c * ((t = t / d - 1) * t * t + 1) + b;
	}
}

