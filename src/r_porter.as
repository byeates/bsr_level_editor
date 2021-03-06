package
{
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.net.FileReference;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;

	public class r_porter
	{
		private var m_loadedLevel:Object;
		private var m_onComplete:Function;
		private var m_layers:Array;
		
		/** singleton */
		static private var sm_instance:r_porter;
		
		public function r_porter( pvt:privateclass ) {}
		
		/** Save file reference as text file of AMF */
		public function ExportLevel( layers:Array, levelWidth:int, levelHeight:int, unitSize:int ):void {
			var byteArray:ByteArray = new ByteArray();
			var bitmap:Bitmap;
			
			var elements:Object = {};
			elements.tiles 		= [];
			elements.collisions = [];
			elements.spawners 	= [];
			elements.items 		= [];
			
			var i:int, j:int, tileIndex:int, collisionIndex:int, spawnerIndex:int, itemIndex:int;
			for ( ; i < layers.length; ++i ) {
				for ( j=0; j < layers[i].numChildren; ++j ) {
					bitmap = layers[i].getChildAt( j ).numChildren > 0 ? layers[i].getChildAt( j ).getChildAt( 0 ) : null;
					var container:* = layers[i].getChildAt( j );
					
					//store tiles
					if ( bitmap ) {
						elements.tiles[tileIndex] = { 
							tile		: bitmap.name, 
							position	: new Point( container.x, container.y ), 
							scale		: new Point( container.scaleX, container.scaleY ),
							rotation	: bitmap.rotation,
							layer		: i, 
							type		: container[ "type" ]
						};
						++tileIndex;
					} 
					//storing collisions
					else if ( container is collisionobject ) {
						elements.collisions[collisionIndex] = {
							box			: container, 
							position	: new Point( container.x, container.y ), 
							layer		: i, 
							type		: container[ "type" ]
						}
						++collisionIndex;
					}
					//store spawner
					else if ( container is spawner ) {
						elements.spawners[spawnerIndex] = {
							position			: new Point( container.x, container.y ), 
							isPlayerSpawn		: container[ "isPlayerSpawn" ],
							enemyTypes			: container[ "enemyTypes" ],
							enemiesPerMinute	: container[ "enemiesPerMinute" ],
							spawnDirection		: container[ "spawnDirection" ],
							name				: container.name
						}
						++spawnerIndex;
					}
					//store items
					else if ( container is items ) {
						elements.items[itemIndex] = {
							position	: new Point( container.x, container.y ), 
							type		: container[ "type" ],
							name		: container.name
						}
					}
				}
			}
			elements.levelWidth = levelWidth;
			elements.levelHeight = levelHeight;
			elements.unitSize = unitSize;
			
			var data:ByteArray = new ByteArray();
			data.writeObject( elements );
			byteArray.writeBytes( data );
			
			var saveFile:FileReference = new FileReference();
			saveFile.save( byteArray, "New Level" + ".rmf" );
		}
		
		/** Import level and parse all elements to layers */
		public function ImportLevel( filePath:String, onCompleteCallback:Function ):void {
			m_loadedLevel = {};
			m_loadedLevel.tiles = [];
			m_onComplete = onCompleteCallback;
			
			var levelLoader:URLLoader = new URLLoader();
			levelLoader.dataFormat = URLLoaderDataFormat.BINARY;
			levelLoader.addEventListener( Event.COMPLETE, OnLevelLoaded );
			levelLoader.load( new URLRequest( filePath ) );
		}
		
		/** Once the level file is loaded, save the data object and load all the tiles */
		private function OnLevelLoaded( e:Event ):void {
			var loader:URLLoader = e.target as URLLoader;
			var data:ByteArray = loader.data as ByteArray;
			var levelObject:Object = data.readObject();

			m_loadedLevel.initialLevelObject = levelObject;
			
			//level is loaded call the on complete with the level size
			m_onComplete( levelObject.levelWidth, levelObject.levelHeight, levelObject.unitSize );
			r_tileloader.instance.loadAmount = levelObject.tiles.length;
			
			var i:int;
			for ( ; i < levelObject.tiles.length; ++i ) {
				r_tileloader.instance.AddAssetToLoad( levelObject.tiles[ i ].tile, TilesLoaded );
			}
			r_tileloader.instance.LoadAll();
		}
		
		/** Generate the level after all the tiles are loaded */
		private function TilesLoaded( asset:Bitmap, isComplete:Boolean ):void {
			m_loadedLevel.tiles.push( asset );
			if ( isComplete ) { GenerateLevel(); }
		}
		
		/** Parse through all the tile objects, add them to the correct container, and apply the correct transformations */
		private function GenerateLevel():void {
			var i:int;
			var element:Object
			for ( ; i < m_loadedLevel.tiles.length; ++i ) {
				element = m_loadedLevel.initialLevelObject.tiles[ i ];
				var tileContainer:tileobject = new tileobject();
				var tile:Bitmap = m_loadedLevel.tiles[ i ];
				tileContainer.x = element.position.x;
				tileContainer.y = element.position.y;
				tileContainer.type = element.type;
				tileContainer.addChild( tile );
				
				ApplyTileProperties( tileContainer, tile, element );
				m_layers[ element.layer ].addChild( tileContainer );
				r_tiler.instance.AddPropertiesListener( tileContainer );
			}
			for ( i=0; i < m_loadedLevel.initialLevelObject.collisions.length; ++i ) {
				element = m_loadedLevel.initialLevelObject.collisions[ i ];
				var collision:collisionobject = new collisionobject();
				collision.type = element.type;
				collision.x = element.position.x;
				collision.y = element.position.y;
				collision.graphics.beginFill(0x00FF00, 0.5);
				collision.graphics.drawRect(0,0,element.box.width, element.box.height);
				m_layers[ 3 ].addChild( collision );
				r_tiler.instance.AddPropertiesListener( collision );
			}
			
			for ( i=0; i < m_loadedLevel.initialLevelObject.spawners.length; ++i ) {
				element = m_loadedLevel.initialLevelObject.spawners[ i ];
				var spawn:spawner = new spawner(m_loadedLevel.initialLevelObject.unitSize);
				spawn.x = element.position.x;
				spawn.y = element.position.y;
				spawn.enemyTypes = element.enemyTypes;
				spawn.enemiesPerMinute = element.enemiesPerMinute;
				spawn.spawnDirection = element.spawnDirection;
				spawn.name = element.name;
				m_layers[ 4 ].addChild( spawn );
				r_tiler.instance.AddPropertiesListener( spawn, "AdjustSpawnProperties" );
			}
		}
		
		/** Callback when tile properties are changed */
		public function ApplyTileProperties( container:Sprite, bitmap:Bitmap, properties:Object ):void {
			var prevW:Number 	= container.width;
			var prevH:Number 	= container.height;
			var prevScale:Point = new Point( container.scaleX, container.scaleY );
			container.scaleX 	= properties.scale.x;
			container.scaleY 	= properties.scale.y;
			
			//adjust position based on scaling to keep orientation
			if ( prevScale.x < 0 && container.scaleX > 0 ) 			{ container.x -= container.width*Math.abs(prevScale.x); } 
			else if ( prevScale.x > 0 && container.scaleX < 0 ) 	{ container.x += container.width; }
			else if ( prevScale.x < 0 && container.scaleX < 0 ) 	{ container.x += container.width - prevW; }
			
			//adjust position based on scaling to keep orientation
			if ( prevScale.y < 0 && container.scaleY > 0 ) 			{ container.y -= container.height*Math.abs(prevScale.y); } 
			else if ( prevScale.y > 0 && container.scaleY < 0 ) 	{ container.y += container.height; }
			else if ( prevScale.y < 0 && container.scaleY < 0 ) 	{ container.y += container.height - prevH; }
			
			//rotate the bitmap only
			var matrix:Matrix = new Matrix();
			matrix.translate( -container.width/2, -container.height/2 );
			matrix.rotate( properties.rotation * Math.PI / 180 );
			matrix.translate( container.width/2, container.height/2 );
			bitmap.transform.matrix = matrix;
		}
		
		public function set layers( containers:Array ):void { m_layers = containers; }
		static public function get instance():r_porter { return sm_instance = sm_instance ? sm_instance : new r_porter( new privateclass() ); }
	}
}

class privateclass{}