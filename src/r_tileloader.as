package
{
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	
	public class r_tileloader extends Loader
	{
		private var m_loadedAssets:Dictionary;
		private var m_assetPath:String;
		private var m_callback:Function;
		private var m_loadState:String;
		private var m_loadQue:Vector.<Object>;
		private var m_currentAssetName:String;
		private var m_assetsLoaded:int;
		private var m_loadAmount:int;
		
		private static var _instance:r_tileloader;
		
		public function r_tileloader( pvt:privateclass ) {
			m_loadedAssets = new Dictionary();
			m_loadQue = new Vector.<Object>();
			m_assetPath = File.applicationDirectory.nativePath.replace( "bin-debug", "assets/" );
			m_loadState = "ready";
			this.contentLoaderInfo.addEventListener( Event.COMPLETE, OnComplete );
			this.contentLoaderInfo.addEventListener( IOErrorEvent.IO_ERROR, OnError );
		}
		
		private function OnError( e:Event ):void {
			trace( e );
		}
		
		private function LoadAsset( path:String ):void {
			m_loadState = "loading";
			load( new URLRequest( path ) );
		}
		
		/**	Asset finished loading, store asset into loaded array and do callback
		 *	Continue through loadQue while it contains assets to be loaded*/
		private function OnComplete( e:Event ):void {
			var bitmap:Bitmap = new Bitmap( (content as Bitmap).bitmapData );
			bitmap.smoothing = true;
			bitmap.name = m_currentAssetName;
			m_loadedAssets[bitmap.name] = bitmap;
			m_loadState = "ready";
			
			++m_assetsLoaded;
			m_callback( bitmap, m_assetsLoaded == m_loadAmount );
			
			m_loadQue.splice( 0, 1 );
			if ( m_loadQue.length > 0 ) {
				GetAsset( m_loadQue[ 0 ].name, m_loadQue[0].callback );
			}
		}
		
		private function GetAsset( name:String, callback:Function=null ):* {
			if ( m_loadState != "loading" ) { 
				m_callback = callback;
				m_currentAssetName = name;
				LoadAsset( m_assetPath+name );
			}
		}
		
		/** Add assets to be loaded */
		public function AddAssetToLoad( name:String, callback:Function=null ):void { m_loadQue.push( { name:name, callback:callback } ); }
		/** Load all the assets in the queue */
		public function LoadAll():void { GetAsset( m_loadQue[ 0 ].name, m_loadQue[ 0 ].callback ); }
		
		
		/*=============================================================================
		Accessors and Mutators
		=============================================================================*/
		/**	Set path to load asset from, default is /assets/ folder */
		public function set assetPath( path:String ):void { m_assetPath = path; }
		public function get assetPath():String { return m_assetPath; }
		public function get remaining():int { return m_loadQue.length; }
		public function set loadAmount(val:int):void { m_loadAmount = val; }
		
		//singleton instance
		public static function get instance():r_tileloader { return _instance ? _instance : _instance = new r_tileloader( new privateclass() ); }
	}
}

class privateclass{}