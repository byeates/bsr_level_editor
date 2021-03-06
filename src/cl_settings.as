package
{
	import com.bit101.components.CheckBox;
	import com.bit101.components.InputText;
	import com.bit101.components.Label;
	import com.bit101.components.Panel;
	import com.bit101.components.PushButton;
	import com.bit101.components.RadioButton;
	
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.filters.DropShadowFilter;

	public class cl_settings
	{
		private var m_settingsPanel		:Panel;
		private var m_updateCallback	:Function;
		
		public var widthInput			:InputText;
		public var heightInput			:InputText;
		public var resizeWarning		:Label;
		public var gridSizeInput		:InputText;
		public var showGrid				:Boolean;
		public var snapToGrid			:Boolean;

		private var m_backgroundButton	:RadioButton;
		private var m_midgroundButton	:RadioButton;
		private var m_foregroundButton	:RadioButton;
		
		public function cl_settings(){
			snapToGrid = true;
			showGrid = true;
		}
		
		/** Function to call to setup the settings menu */
		public function InitSettings( settingsLayer:Sprite, stage:Stage, updateCallback:Function, saveCallback:Function ):void {
			m_updateCallback = updateCallback;
			//main panel
			m_settingsPanel = new Panel( settingsLayer, stage.stageWidth - 150, 0 );
			m_settingsPanel.setSize( 150, 500 );
			m_settingsPanel.filters = [new DropShadowFilter(10,45,0,0.7,10,10)];
			
			//level width input
			widthInput = new InputText( m_settingsPanel, m_settingsPanel.width/2 - 50, 50 );
			widthInput.text = "960";
			widthInput.setSize( 100, 25 );
			
			var levelwidthLabel:Label = new Label( m_settingsPanel, widthInput.x + widthInput.width/2, widthInput.y, "Level width:" );
			levelwidthLabel.y -= levelwidthLabel.height;
			levelwidthLabel.x -= levelwidthLabel.width/2;
			
			//level height input
			heightInput = new InputText( m_settingsPanel, m_settingsPanel.width/2 - 50, widthInput.y + widthInput.height + levelwidthLabel.height );
			heightInput.text = "640";
			heightInput.setSize( 100, 25 );
			
			var levelheightLabel:Label = new Label( m_settingsPanel, heightInput.x + heightInput.width/2, heightInput.y, "Level height:" );
			levelheightLabel.y -= levelheightLabel.height;
			levelheightLabel.x -= levelheightLabel.width/2;
			
			//close
			var close:PushButton = new PushButton( m_settingsPanel, m_settingsPanel.width/2, heightInput.y + heightInput.height + 2, "[Submit]", updateCallback );
			close.x -= close.width/2;
			
			//save
			var save:PushButton = new PushButton( m_settingsPanel, m_settingsPanel.width/2, close.y + close.height + 2, "[Save]", saveCallback );
			save.x -= save.width/2;
			
			//layer selection
			m_backgroundButton = new RadioButton( m_settingsPanel, widthInput.x, save.y + save.height + 10, "Background Layer", true, onBackgroundSelect );
			m_midgroundButton = new RadioButton( m_settingsPanel, widthInput.x, m_backgroundButton.y + m_backgroundButton.height + 10, "Midground Layer", false, onMidgroundSelect );
			m_foregroundButton = new RadioButton( m_settingsPanel, widthInput.x, m_midgroundButton.y + m_midgroundButton.height + 10, "Foreground Layer", false, onForegroundSelect );
			
			//grid size input
			gridSizeInput = new InputText( m_settingsPanel, m_settingsPanel.width/2 - 50, m_foregroundButton.y + m_foregroundButton.height + 30 );
			gridSizeInput.text = "1";
			gridSizeInput.setSize( 100, 25 );
			
			var gridSizeLabel:Label = new Label( m_settingsPanel, gridSizeInput.x + gridSizeInput.width/2, gridSizeInput.y, "Grid Size: " );
			gridSizeLabel.y -= gridSizeLabel.height;
			gridSizeLabel.x -= gridSizeLabel.width/2;
			
			var showGrid:CheckBox = new CheckBox( m_settingsPanel, gridSizeInput.x + gridSizeInput.width/2, gridSizeInput.y + gridSizeInput.height + 5, "Show Grid", onShowGrid );
			showGrid.x -= showGrid.width/2;
			showGrid.selected = true;
			
			var snapToGrid:CheckBox = new CheckBox( m_settingsPanel, gridSizeInput.x + gridSizeInput.width/2, showGrid.y + showGrid.height + 5, "Snap to Grid", onSnapToGrid );
			snapToGrid.x -= showGrid.width/2;
			snapToGrid.selected = true;
			
			//resize warning
			resizeWarning = new Label( m_settingsPanel, m_settingsPanel.width/2, showGrid.y + showGrid.height + 20, "\tWarning: \n resizing grid/level \n will clear the map.", 0xFF0000, 8 );
			resizeWarning.x -= resizeWarning.width/2;
			resizeWarning.visible = false;
			
			var backgroundVisible:CheckBox = new CheckBox( m_settingsPanel, gridSizeInput.x + gridSizeInput.width/2, resizeWarning.y + resizeWarning.height + 25, "Show Background", ToggleBackground );
			backgroundVisible.x -= backgroundVisible.width/2;
			backgroundVisible.selected = true;
			
			var midgroundVisible:CheckBox = new CheckBox( m_settingsPanel, gridSizeInput.x + gridSizeInput.width/2, backgroundVisible.y + backgroundVisible.height + 5, "Show Midground", ToggleMidground );
			midgroundVisible.x = backgroundVisible.x;
			midgroundVisible.selected = true;
			
			var foregroundVisible:CheckBox = new CheckBox( m_settingsPanel, gridSizeInput.x + gridSizeInput.width/2, midgroundVisible.y + midgroundVisible.height + 5, "Show Foreground", ToggleForeground );
			foregroundVisible.x = backgroundVisible.x;
			foregroundVisible.selected = true;
			
			var collisionsVisible:CheckBox = new CheckBox( m_settingsPanel, gridSizeInput.x + gridSizeInput.width/2, foregroundVisible.y + foregroundVisible.height + 5, "Show Collisions", ToggleCollisions );
			collisionsVisible.x = backgroundVisible.x;
			collisionsVisible.selected = true;
			
			var spawnersVisible:CheckBox = new CheckBox( m_settingsPanel, gridSizeInput.x + gridSizeInput.width/2, collisionsVisible.y + collisionsVisible.height + 5, "Show Spawners", ToggleSpawners );
			spawnersVisible.x = backgroundVisible.x;
			spawnersVisible.selected = true;
			
			//hotkeys info
			var hotKeys:Label = new Label( m_settingsPanel, m_settingsPanel.width/2, m_settingsPanel.height, "CTRL+Z - undo" );
			hotKeys.x -= hotKeys.width/2;
			hotKeys.y -= hotKeys.height*2;
		}
		
		/*========================================================================================
		EVENT HANDLING
		========================================================================================*/
		private function onBackgroundSelect( e:Event ):void {
			m_midgroundButton.selected = false;
			m_foregroundButton.selected = false;
			r_tiler.instance.SetActiveLayer( 0 );
		}
		
		private function onMidgroundSelect( e:Event ):void {
			m_backgroundButton.selected = false;
			m_foregroundButton.selected = false;
			r_tiler.instance.SetActiveLayer( 1 );
		}
		
		private function onForegroundSelect( e:Event ):void {
			m_midgroundButton.selected = false;
			m_backgroundButton.selected = false;
			r_tiler.instance.SetActiveLayer( 2 );
		}
		
		private function onShowGrid( e:Event ):void {
			showGrid = !showGrid;
			m_updateCallback();
		}
		
		private function onSnapToGrid( e:Event ):void {
			snapToGrid = !snapToGrid;
			m_updateCallback();
			r_tiler.instance.snapToGrid = snapToGrid;
		}
		
		//TOGGLE LAYERS
		private function ToggleBackground( e:Event=null ):void 	{ r_tiler.instance.background.visible 	= !r_tiler.instance.background.visible; }
		private function ToggleMidground( e:Event=null ):void 	{ r_tiler.instance.midground.visible 	= !r_tiler.instance.midground.visible; 	}
		private function ToggleForeground( e:Event=null ):void 	{ r_tiler.instance.foreground.visible 	= !r_tiler.instance.foreground.visible; }
		private function ToggleCollisions( e:Event=null ):void 	{ r_tiler.instance.collisions.visible 	= !r_tiler.instance.collisions.visible; }
		private function ToggleSpawners( e:Event=null ):void 	{ r_tiler.instance.spawners.visible 	= !r_tiler.instance.spawners.visible; }
	}
}