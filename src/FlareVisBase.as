package  {
  import flare.util.Property;
  import flare.vis.data.Data;
  
  import mx.binding.utils.ChangeWatcher;
  import mx.collections.ArrayCollection;
  import mx.events.CollectionEvent;
  import mx.events.PropertyChangeEvent;
  
  import org.juicekit.visual.controls.FlareControlBase;
  

  /**
   * The class <code>FlareVisBase</code> provides a common implementation
   * for visual controls based upon the prefure.flare <code>Visualization</code>.
   * The class is only intended to be used as a base implementation
   * for custom controls and is not intended to be directly instantiated.
   *
   * @author Chris Gemignani
   */
  [Bindable]
  public class FlareVisBase extends FlareControlBase {
    
    /**
    * Constructor
    */
    public function FlareVisBase() {
      super();
    }
    
    public function registerActions(actionMap:Object):void {
      for (var k:String in actionMap) {
        ChangeWatcher.watch(this, k, watchForChanges);
        registeredActionMap[k] = actionMap[k];
      }
    }
    
    /**
    * A proxy for Flare properties. The key is the
    * local property that may change. The value is either
    * a property that the new value should be assigned to,
    * or a function that will receive the PropertyChangeEvent.
    */
    private var registeredActionMap:Object = {
    }


    private var queue:Array = [];
    private function clearQueue():void {
      var _queue:Array = queue.slice();
      queue = [];
      for each (var e:PropertyChangeEvent in _queue) {
        watchForChanges(e);
      } 
      
    }
    /**
    * Evaluated if any of the keys in <code>actionMap</code>
    * change.
    */
    private function watchForChanges(e:PropertyChangeEvent):void {
      var prop:Object = e.property;
      if (!vis || !vis.data) {
        queue.push(e.clone());
      } else {
        clearQueue();
        if (registeredActionMap.hasOwnProperty(prop)) {
          var action:* = registeredActionMap[prop];
          if (action == null) {
          } else if (action is String) {
            try {
              Property.$(action).setValue(this, e.newValue);                    
            } catch (e:Error) {
              var x:int = 0;
            }
          } else if (action is Function) {
            action(e);
          } 
        }
        invalidateProperties();
      }      
    }
    

    override protected function commitProperties():void {
      super.commitProperties();
      updateVisualization();
    }



    /**
    * Called whenever a source data collection changes.
    * 
    * Simply resets the entire data for the visualization to the 
    * data in the ArrayCollection. 
    * 
    * TODO: optimize
    */
    private function updateDataFromAC(event:CollectionEvent):void {
      data = event.target;
    }
    
    
    /** 
    * <p>Add operators to <code>vis.operators</code>.</p>
    * 
    * <p>The creation of <code>vis.operators</code> is <i>deferred</i> 
    * until data is assigned to the visualization. This avoids problems
    * with scale bindings in the Flare framework.</p>
    * 
    * <p>Subclasses should override this to perform <code>vis.operators.add</code>
    * for all desired operators</p>
    */ 
    protected function createOperators():void {      
      vis.operators.clear();
      // add operators here
    }

    /** 
    * <p>Add controls to <code>vis.controls</code>.</p>
    * 
    * <p>The creation of <code>vis.controls</code> is <i>deferred</i> 
    * until data is assigned to the visualization.</p>
    * 
    * <p>Subclasses should override this to perform <code>vis.controls.add</code>
    * for all desired controls</p>
    */ 
    protected function createControls():void {
      vis.controls.clear();  
      // add controls here
    }
    
    protected var extraOperators:Array = [];

    /**
     * Sets the data value to a <code>Data</code> data
     * object used for rendering position and color
     * of the chart.
     *
     * @see flare.vis.data.Data
     */
    override public function set data(value:Object):void {
      if (value != null) {
        var newValue:Data = null;
        if (value is Array) 
          newValue = Data.fromArray(value as Array);
        if (value is ArrayCollection) {
          (value as ArrayCollection).addEventListener(CollectionEvent.COLLECTION_CHANGE, updateDataFromAC);
          newValue = Data.fromArray(value.source as Array);
        }
        if (value is Data) 
          newValue = value as Data;
  
        if (newValue !== this.data) {
          vis.data = newValue;
          if (this.data == null) {
            createOperators();
          }
          super.data = newValue;
//          dispatchEvent(new JuiceKitEvent(JuiceKitEvent.DATA_ROOT_CHANGE));
        }
        
      }
    }
    override public function get data():Object { return super.data }

  }
}