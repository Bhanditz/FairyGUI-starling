package fairygui
{
	public class UIConfig
	{
		public function UIConfig()
		{
		}
		
		//Default font name
		public static var defaultFont:String = ""; 
		
		//Resource using in Window.ShowModalWait for locking the window.
		public static var windowModalWaiting:String;
		//Resource using in GRoot.ShowModalWait for locking the screen.
		public static var globalModalWaiting:String;//全局锁定时使用的资源, see GStage.showModalWait
		
		//When a modal window is in front, the background becomes dark.
		public static var modalLayerColor:uint = 0x333333;
		public static var modalLayerAlpha:Number = 0.2;
		
		//Default button click sound
		public static var buttonSound:String;
		public static var buttonSoundVolumeScale:Number = 1;
		
		//Resources for scrollbars
		public static var horizontalScrollBar:String;
		public static var verticalScrollBar:String;
		//Scrolling step in pixels
		public static var defaultScrollSpeed:int = 25;
		//Default scrollbar display mode. Recommened visible for Desktop and Auto for mobile.
		public static var defaultScrollBarDisplay:int = ScrollBarDisplayType.Visible;
		//Allow dragging the content to scroll. Recommeded true for mobile.
		public static var defaultScrollTouchEffect:Boolean = false;
		//The "rebound" effect in the scolling container. Recommeded true for mobile.
		public static var defaultScrollBounceEffect:Boolean = false;
		
		//Resources for PopupMenu.
		public static var popupMenu:String;
		//Resources for seperator of PopupMenu.
		public static var popupMenu_seperator:String;
		//In case of failure of loading content for GLoader, use this sign to indicate an error.
		public static var loaderErrorSign:String;
		//Resources for tooltips.
		public static var tooltipsWin:String;
		
		public static var defaultComboBoxVisibleItemCount:int = 10;
	}
}
