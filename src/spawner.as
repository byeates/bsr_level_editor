package
{
	import flash.display.Sprite;
	import flash.events.Event;
	
	public class spawner extends Sprite
	{
		static protected var numSpawners:int;
		
		public var enemiesPerMinute:int;
		public var spawnDirection:String;
		public var isPlayerSpawn:Boolean;
		
		/** types of enemies the spawner will create, in order */
		public var enemyTypes:Array;
		
		public function spawner( size:int ) {
			enemyTypes = [];
			graphics.lineStyle(2, 0x00FFFF);
			graphics.beginFill(0x00FFFF,0.5);
			graphics.drawRect( 0, 0, size, size );
			addEventListener( Event.ADDED_TO_STAGE, OnAdded );
			addEventListener( Event.REMOVED_FROM_STAGE, OnRemoved );
		}
		
		private function OnAdded( e:Event ):void {
			name = "spawner_" + numSpawners;
			++numSpawners;
		}
		
		private function OnRemoved( e:Event ):void {
			--numSpawners;
		}
	}
}