package
{
	import com.assets;
	
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FileListEvent;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	
	[SWF(backgroundColor=0, width=1200, height=800, frameRate=30)]
	public class bsrLevelEdtior extends Sprite
	{
		/** just letting you know what not to do */
		private var debugText		:TextField;
		
		//used with loading up asses
		private var directory		:File;
		private var filePath		:String;
		
		//used for loading up a previous level
		private var loadedLevel		:Boolean;
		
		//asset ui
		private var m_assets		:Array;
		private var assetsBar		:Sprite;
		
		/** filter applied to the selected tile */
		private var glowFilter		:GlowFilter;
		
		//grid
		private var grid			:Sprite;
		private var lines			:Sprite; //grid lines
		private var gridMask		:Sprite;
		
		//settings for tiles and level
		private var settingsPanel	:cl_settings;
		private var tileProperties	:cl_tileproperties;
		private var spawnerProperties:cl_spawnerproperties;
		private var settingsLayer	:Sprite;
		private var	editorLayer		:Sprite;
		
		private var levelWidth		:Number = 960;
		private var levelHeight		:Number = 640;
		
		//used to be constant, but is updated when settings change (after which it is constant for the duration of the level editing)
		private var GRID_TILESIZE:int = 1;

		
		public function bsrLevelEdtior()
		{
			glowFilter 		= new GlowFilter( 0xFFFF00 );
			assetsBar 		= new Sprite();
			settingsLayer	= new Sprite();
			editorLayer		= new Sprite();
			settingsPanel	= new cl_settings();
			m_assets 			= [];
			r_tiler.stage 	= stage;
			gridMask		= new Sprite();
			directory 		= File.documentsDirectory;
			
			addChild( editorLayer );
			addChild( settingsLayer );
			
			tileProperties = new cl_tileproperties( settingsLayer, stage, r_tiler.instance.ApplyTileProperties, r_tiler.instance.DeleteTile );
			spawnerProperties = new cl_spawnerproperties( settingsLayer, stage, r_tiler.instance.ApplySpawnerProperties, r_tiler.instance.DeleteTile );
			new cl_itemproperties( settingsLayer, stage, r_tiler.instance.ApplySpawnerProperties, r_tiler.instance.DeleteTile );
			
			r_tiler.instance.Init();
			AddSelectText();
			stage.addEventListener(MouseEvent.CLICK, OnSearchDirectory);
		}
		
		/** Opens the directory browser */
		private function OnSearchDirectory( e:MouseEvent ):void {
			directory.browseForOpenMultiple( "Select all assets or a level file to be loaded" );
			directory.addEventListener( FileListEvent.SELECT_MULTIPLE, OnFilesSelected );
		}
		
		/** When files have been selected */
		private function OnFilesSelected( e:FileListEvent ):void {
			stage.removeEventListener( MouseEvent.CLICK, OnSearchDirectory );
			directory.removeEventListener( FileListEvent.SELECT_MULTIPLE, OnFilesSelected );
			filePath = e.currentTarget.nativePath + "/";
			
			removeChild( debugText );
			var i:int;
			r_loader.instance.loadAmount = e.files.length;
			for ( ; i < e.files.length; ++i ) {
				var stream:FileStream = new FileStream();
				var file:File = e.files[i] as File;
				stream.open( file, FileMode.READ );
				
				var fileData:ByteArray = new ByteArray();
				stream.readBytes( fileData );
				stream.close();
				
				if ( file.name.indexOf( ".rmf" ) != -1 ) {
					InitSettings();
					r_porter.instance.ImportLevel( file.url, onLevelLoaded );
					stage.addEventListener(MouseEvent.CLICK, OnSearchDirectory);
					
					var tf:TextFormat = new TextFormat();
					tf.color = 0xFF0000;
					debugText.defaultTextFormat = tf;
					debugText.text = "!!!~~~~~CLICK TO LOAD ASSETS~~~~~!!!";
					addChild( debugText );
					loadedLevel = true;
					break;
				} 
				else {
					r_loader.instance.GetAsset( file.name, fileData, OnAssetLoaded );
				}
			}
		}
		
		/** Callback after a .rmf is loaded */
		private function onLevelLoaded( lw:int, lh:int, unitSize:int=1 ):void {
			//add tiles to asset bar
			levelWidth = lw;
			levelHeight = lh;
			GRID_TILESIZE = unitSize;
			settingsPanel.widthInput.text = lw.toString();
			settingsPanel.heightInput.text = lh.toString();
			settingsPanel.gridSizeInput.text = GRID_TILESIZE.toString();
			CreateGrid();
		}
		
		/** Mimic layers for actual game */
		private function CreateLayers():void {
			var background:Sprite 	= new Sprite();
			var midground:Sprite 	= new Sprite();
			var foreground:Sprite 	= new Sprite();
			var collisions:Sprite 	= new Sprite();
			var spawners:Sprite 	= new Sprite();
			background.name 		= "background";
			midground.name 			= "midground";
			foreground.name 		= "foreground";
			collisions.name 		= "collisions";
			spawners.name 			= "spawners";
			
			grid.addChild( background );
			grid.addChild( midground );
			grid.addChild( foreground );
			grid.addChild( collisions );
			grid.addChild( spawners );
			
			grid.mouseEnabled = false;
			
			r_tiler.instance.background = background;
			r_tiler.instance.midground 	= midground;
			r_tiler.instance.foreground = foreground;
			r_tiler.instance.spawners 	= spawners;
			r_tiler.instance.collisions = collisions;
			r_tiler.instance.grid 		= grid;
			r_porter.instance.layers 	= [background, midground, foreground, collisions, spawners];
			
			r_tiler.instance.SetActiveLayer( 0 );
		}
		
		/** Setup the grid for 1px grid snapping ( rows and columns to 1px ) 
		 * This gets called any time the level width and level height is updated
		 * */
		private function CreateGrid():void {
			grid = new Sprite();
			grid.graphics.beginFill(0xFFFFFF);
			grid.graphics.drawRect( 0, 0, levelWidth, levelHeight );
			grid.x = grid.y = 20;
			editorLayer.addChild( grid );
			
			//grab the latest grid size
			GRID_TILESIZE = int(settingsPanel.gridSizeInput.text);
			var rows:Number = levelHeight / GRID_TILESIZE;
			var columns:Number = levelWidth / GRID_TILESIZE;
			
			//clear the previous map if there was one
			r_tiler.instance.unitSize 			= GRID_TILESIZE;
			r_tiler.instance.snapToGrid			= settingsPanel.snapToGrid;
			r_tiler.instance.gridRows.length 	= 0;
			r_tiler.instance.gridColumns.length = 0;
			
			//prep the grid lines
			lines = new Sprite();
			lines.name = "gridLines";
			lines.graphics.lineStyle( 2, 0x333333, 0.8 );
			lines.graphics.moveTo( 0, 0 );
			
			var i:int;
			for ( ; i <= columns; ++i ) { 
				r_tiler.instance.gridColumns.push( i * GRID_TILESIZE ); 
				lines.graphics.moveTo( i * GRID_TILESIZE, 0 );
				lines.graphics.lineTo( i * GRID_TILESIZE, levelHeight );				
			}
			for ( i=0; i <= rows; ++i ) { 
				r_tiler.instance.gridRows.push( i * GRID_TILESIZE ); 
				lines.graphics.moveTo( 0, i * GRID_TILESIZE );
				lines.graphics.lineTo( levelWidth, i * GRID_TILESIZE );
			}
			
			grid.addChild( lines );
			lines.visible = false;
			
			//by default lines are not visible
			if ( settingsPanel.showGrid ) { lines.visible = true; }
			
			if ( !editorLayer.contains( gridMask ) ) {
				gridMask.graphics.beginFill(0xFF0000);
				gridMask.graphics.drawRect( 0, 0, stage.stageWidth - 150, stage.stageHeight - 120 );
				gridMask.x = gridMask.y = 20;
				editorLayer.addChild( gridMask );
				gridMask.mouseEnabled = false;
				gridMask.visible = false;
			}
			
			grid.mask = gridMask;
			
			CreateLayers();
		}
		
		/** Callback after asset is loaded */
		private function OnAssetLoaded( bitmap:Bitmap, isComplete:Boolean ):void {
			m_assets.push( bitmap );
			if ( isComplete ) {
				InitSettings();
				AssetsLoaded();
			}
		}
		
		/** Called when all assets have been loaded */
		private function AssetsLoaded():void {
			if ( !loadedLevel ) { CreateGrid(); } //skip this if a level file was loaded
			
			assetsBar = new Sprite();
			assetsBar.graphics.beginFill( 0xFFFFFF, 0.8 );
			assetsBar.graphics.drawRect( 0, 0,stage.stageWidth, 100 );
			assetsBar.y = stage.stageHeight - assetsBar.height;
			editorLayer.addChild( assetsBar );
			
			var i:int;
			var assetsWidth:Number = assetsBar.width / m_assets.length;
			for ( ; i < m_assets.length; ++i ) {
				var asset:Bitmap = new Bitmap( m_assets[i].bitmapData );
				asset.name = m_assets[i].name;
				
				asset.width = assetsWidth > asset.width ? asset.width : assetsWidth;
				asset.height = asset.height > assetsBar.height - 5 ? assetsBar.height - 5 : asset.height;
				
				var container:Sprite = new Sprite();
				container.addChild( asset );
				
				container.x = i * container.width;
				container.y = 2.5;
				
				assets[i] = container;
				
				assetsBar.addChild( container );
				container.addEventListener(MouseEvent.CLICK, OnTileSelect);
			}
			var spawner:Sprite = new Sprite();
			spawner.addChild( assets.GetAsset( "icon_spawner" ) );
			spawner.x = stage.stageWidth - spawner.width;
			spawner.y = -spawner.height;
			spawner.mouseEnabled = true;
			spawner.useHandCursor = true;
			spawner.buttonMode = true;
			assetsBar.addChild( spawner );
			spawner.addEventListener(MouseEvent.CLICK, OnSpawnerSelect);
			
			var item:Sprite = new Sprite();
			item.addChild( assets.GetAsset( "icon_items" ) );
			item.x = spawner.x - item.width;
			item.y = spawner.y;
			item.mouseEnabled = item.useHandCursor = item.buttonMode = true;
			assetsBar.addChild( item );
			item.addEventListener( MouseEvent.CLICK, OnItemSelect );
			
			AddLevelListeners();
		}
		
		/** Start the settings panel */
		private function InitSettings():void { settingsPanel.InitSettings( settingsLayer, stage, UpdateSettings, SaveLevel ); }
		
		/*========================================================================================
		EVENT HANDLING
		========================================================================================*/
		private function AddLevelListeners():void {
			stage.addEventListener( MouseEvent.MOUSE_WHEEL, OnMouseWheel );
		}
		
		/** Called whenever Submit button is selected from the settings panel */
		private function UpdateSettings( e:Event=null ):void {
			if ( !settingsPanel.resizeWarning.visible ) { settingsPanel.resizeWarning.visible = true; }
			
			var w:Number = Number( settingsPanel.widthInput.text );
			var h:Number = Number( settingsPanel.heightInput.text );
			var update:Boolean;
			if ( !isNaN( w ) && w != levelWidth ) {
				levelWidth = w;
				update = true;
			}
			if ( !isNaN( h ) && h != levelHeight ) {
				levelHeight = h;
				update = true;
			}
			//update the grid lines visibility
			lines.visible = settingsPanel.showGrid;
			
			if ( GRID_TILESIZE != int(settingsPanel.gridSizeInput.text) ) {
				update = true;
			}
			
			if ( update ) {
				ClearGrid();
				CreateGrid();
			}
		}
		
		/** Basically just "zoom" */
		private function OnMouseWheel( e:MouseEvent ):void {
			var matrix:Matrix = new Matrix();
			if ( e.delta > 0 && grid.scaleX < 4 ) {
				grid.scaleX += 0.1;
				grid.scaleY += 0.1;
			}
			else if ( grid.scaleX > 0.2 ) {
				grid.scaleX -= 0.1;
				grid.scaleY -= 0.1;
			}
		}
		
		/** Update the active tile when a new tile is selected from the assets bar */
		private function OnTileSelect( e:MouseEvent ):void {
			ClearTileFilters();
			AddTileFilter( e.target as Sprite );
			r_tiler.instance.UpdateActiveTile( Sprite(e.target).getChildAt(0) as Bitmap );
			cl_tileproperties.instance.HideMenu();
		}
		
		/** Update the active tile when a new tile is selected from the assets bar */
		private function OnSpawnerSelect( e:MouseEvent ):void {
			ClearTileFilters();
			AddTileFilter( e.target as Sprite );
			r_tiler.instance.OnSpawnerSelected();
			cl_tileproperties.instance.HideMenu();
		}
		
		private function OnItemSelect( e:MouseEvent ):void {
			ClearTileFilters();
			AddTileFilter( e.target as Sprite );
			r_tiler.instance.OnItemSelected();
			cl_tileproperties.instance.HideMenu();
		}
		
		/** Export the level assets information */
		private function SaveLevel( e:Event=null ):void {
			r_porter.instance.ExportLevel( [r_tiler.instance.background, r_tiler.instance.midground, r_tiler.instance.foreground, r_tiler.instance.collisions, r_tiler.instance.spawners], levelWidth, levelHeight, GRID_TILESIZE );
		}
		
		/*========================================================================================
		ANCILLARY
		========================================================================================*/
		private function ClearTileFilters():void {
			var i:int;
			for ( ; i < m_assets.length; ++i ) {
				var asset:Sprite = assets[i];
				asset.filters = null;
			}
		}
		
		private function ClearGrid():void {
			editorLayer.removeChild( grid );
		}
		
		private function AddTileFilter( asset:Sprite ):void {
			asset.filters = [glowFilter];
		}
		
		private function AddSelectText():void {
			var tf:TextFormat = new TextFormat();
			tf.size = 20;
			tf.color = 0xFFFFFF;
			
			debugText = new TextField();
			debugText.autoSize = "left";
			debugText.defaultTextFormat = tf;
			debugText.text = 	"READ THIS BEFORE ATTEMPTING FIRST TIME USE: \n" +
								"- The application needs to be in the same directory as your assets folder (if you don't have one make one and add the images to it) \n" +
								"- You can choose to load images or an existing level file, if you choose a level file, select the stage again to load the assets ";
			debugText.x = stage.stageWidth/2 - debugText.textWidth/2;
			addChild( debugText );
		}
	}
}