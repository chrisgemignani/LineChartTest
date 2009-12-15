package {
  import flare.util.Property;
  import flare.vis.controls.Control;
  import flare.vis.data.Data;
  import flare.vis.events.DataEvent;
  import flare.vis.operator.Operator;
  
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
      //Our objects in our arrays may not be in the right form for the ChangeWatcher
      ChangeWatcher.watch(this, 'baseOperators', createOperators);
      ChangeWatcher.watch(this, 'extraOperators', createOperators);
      ChangeWatcher.watch(this, 'baseControls', createControls);
      ChangeWatcher.watch(this, 'extraControls', createControls);
    }


    /**
     * <p>Registers an <code>actionMap</code> object. This is a
     * simple object containing a sequence of keys and values.
     * The keys represent bindable public variables, and the values are
     * actions to perform when the variable changes. Values can be
     * strings or functions with signature <code>function(e:PropertyChangeEvent):void</code>
     * or an Array of strings and functions.</p>
     *
     * <p>If the value is a string the property represented by the dotted string
     * is changed to the new value of the key. For instance:<p>
     *
     * <pre>
     * rev: 'vis.xyAxes.xReverse'
     * </pre>
     *
     * <p>If public variable <code>rev</code> changes, the new value is set into
     * <code>vis.xyAxes.xReverse</p>
     *
     * <p>If the value is a function, the function is passed the
     * <code>PropertyChangeEvent</code> when the <code>key</code> changes.</p>
     *
     * <p>If the value is an Array, all of the elements of the Array are evaluated
     * either as Strings or as functions.</p>
     */
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
    private var registeredActionMap:Object = {}


    /**
     * A list of deferred property changes.
     *
     * These will be applied when data is set on the visualization.
     */
    private var propertyChangeQueue:Array = [];


    /**
     * Apply all the property changes in <code>propertyChangeQueue</code>.
     */
    private function clearPropertyChangeQueue():void {
      var _queue:Array = propertyChangeQueue.slice();
      propertyChangeQueue = [];
      for each (var e:PropertyChangeEvent in _queue) {
        watchForChanges(e);
      }
    }




    /**
     * Evaluated if any of the keys in <code>actionMap</code>
     * change.
     *
     * @param e a PropertyChangeEvent, ChangeWatchers are set up
     * by registerActions
     *
     * @private
     */
    private function watchForChanges(e:PropertyChangeEvent):void {
      function handleAction(source:*, a:*, e:PropertyChangeEvent):void {
        if (a is String) {
          try {
            var s:String = a as String;    
            var dataProp:Boolean = false;
                    
            // if the property is preceeded by
            // @, we are setting a reference to one of the 
            // data fields. 
            if (s.charAt(0) == '@') {
              s = s.substr(1);
              dataProp = true;
            } 
            
            var newVal:* = e.newValue;
            if (dataProp) {
              // make sure the new value is preceeded by 'data.'
              if (newVal.toString().substr(0,5) != 'data.') {
                newVal = asFlareProperty(newVal.toString());
              }  
            } 
            Property.$(s).setValue(source, newVal);                    
          } catch (e:Error) {
            var x:int = 0;
          }
        } else if (a is Function) {
          a(e);
        }
      }
      var prop:Object = e.property;
      if (vis == null || vis.data == null) {
        // store the property change to be applied later
        propertyChangeQueue.push(e.clone());
      } else {
        clearPropertyChangeQueue();
        if (registeredActionMap.hasOwnProperty(prop)) {
          var action:* = registeredActionMap[prop];
          if (action is Array) {
            for each (var itm:* in action) {
              handleAction(this, itm, e);
            }        
          } else {            
            handleAction(this, action, e);
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
    * <p>Add operators to <code>vis.operators</code>.</p>
    * 
    * <p>The creation of <code>vis.operators</code> is <i>deferred</i> 
    * until data is assigned to the visualization. This avoids problems
    * with scale bindings in the Flare framework.</p>
    * 
    * <p>Subclasses should place the base operators needed for 
    * the visualization in <code>baseOperators</code>.</p>
    */ 
    protected function createOperators(e:*=null):void {      
      vis.operators.clear();
      var op:Operator;
      for each (op in baseOperators) {
        vis.operators.add(op);
      }
      for each (op in extraOperators) {
        vis.operators.add(op);
      }
      invalidateProperties();
    }

    /** 
    * <p>Add controls to <code>vis.controls</code>.</p>
    * 
    * <p>The creation of <code>vis.controls</code> is <i>deferred</i> 
    * until data is assigned to the visualization.</p>
    * 
    * <p>Subclasses should place all base controls needed for the
    * visualization in <code>baseControls</code>.</p>
    */ 
    protected function createControls(e:*=null):void {
      vis.controls.clear();  
      var ctrl:Control;
      for each (ctrl in baseControls) {
        vis.controls.add(ctrl);
      }
      for each (ctrl in extraControls) {
        vis.controls.add(ctrl);
      }
      invalidateProperties();
    }

    /**
     * Operators that are used in every visualization
     */
    protected var baseOperators:Array = [];

    /**
     * Operators that are added by the user of the visualization.
     */
    public var extraOperators:Array = [];

    /**
     * Controls that are used in every visualization.
     */
    protected var baseControls:Array = [];

    /**
     * Controls that are added by the user of the visualization.
     */
    public var extraControls:Array = [];


    /**
     * Called whenever a source data collection changes.
     *
     * Simply resets the entire data for the visualization to the
     * data in the ArrayCollection.
     *
     * TODO: optimize
     *
     * @private
     */
    private function updateDataFromAC(event:CollectionEvent):void {
      trace('updateDataFromAC');
      performDataMatching = false;
      data = event.target;
      event.stopPropagation();
      performDataMatching = true;
    }

    /**
     * Holds a reference to the previously set data
     *
     * @private
     */
    private var prevData:Object;

    /**
     * Holds an array of fields that could be used for matching elements
     * to previous incarnations of the same element when the data changes.
     *
     */
    public var dataMatchingFields:Array;
    
    
    // update, append, replace
    /**
    * 
    * 
    */ 
    public var dataMode:String;
    public var performDataMatching:Boolean = false;


    private function updateData(event:DataEvent):void {
      invalidateProperties();
    }

    public function set dataProvider(value:Object):void {
      //if (value === prevData) return;
      if (vis.data != null) return;
      trace('setting data', performDataMatching, super.data); 
      if (super.data == null && value is ArrayCollection && (value as ArrayCollection).length == 0) {
        trace('aborting set data');
        return;
      }
      if (value != null) {
        var newValue:Data = null;
        if (value is Array) {
          newValue = Data.fromArray(value as Array);
          trace('\tArray ', newValue.nodes.length);
        } else if (value is DataArrayCollection) {
          trace('assigning from dataArrayCollection');
          newValue = (value as DataArrayCollection).data();
          
        } else if (value is ArrayCollection) {
          trace('value is ArrayCollection', value.length);
//NOTE: this is disabled as updates should be coming thru DataArrayCollection          
//          if (prevData && prevData is ArrayCollection) {
//            (prevData as ArrayCollection).removeEventListener(CollectionEvent.COLLECTION_CHANGE, updateDataFromAC);
//          }
//          (value as ArrayCollection).addEventListener(CollectionEvent.COLLECTION_CHANGE, updateDataFromAC);
          newValue = Data.fromArray(value.source as Array);
          trace('\tArrayCollection ', newValue.nodes.length);
        } else if (value is Data) {
          newValue = value as Data;
          trace('\tData ', newValue.nodes.length);
        }

        // save a reference to allow removing the event listener
        prevData = value;

        if (newValue !== vis.data) {
          newValue.addEventListener(DataEvent.UPDATE, updateData);
          vis.data = newValue;
          styleNodes();
          styleEdges();

          if (this.data == null) {
            createOperators();
            createControls();
          }
          clearPropertyChangeQueue();
          styleVis();
          super.data = vis.data;
//          vis.update(new Transitioner(2)).play();
          invalidateProperties();
        }
      }
    }




    /**
     * A hook to set properties for nodes <b>after</b> new data is assigned.
     * Subclasses should override this.
     */
    protected function styleNodes():void {
    }


    /**
     * A hook to set properties for edges <b>after</b> new data is assigned.
     * Subclasses should override this.
     */
    protected function styleEdges():void {
    }


    /**
     * A hook to set properties for visualization <b>after</b> new data is assigned and
     * operators are created. Subclassess should override this.
     */
    protected function styleVis():void {
    }

  }
}