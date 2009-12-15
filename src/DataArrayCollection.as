package {
  import flare.util.Property;
  import flare.util.Stats;
  import flare.vis.data.Data;
  import flare.vis.data.DataSprite;
  import flare.vis.data.NodeSprite;
  import flare.vis.events.DataEvent;
  
  import flash.utils.ByteArray;
  import flash.utils.Dictionary;
  
  import mx.collections.ArrayCollection;
  import mx.events.CollectionEvent;
  import mx.events.PropertyChangeEvent;

  /**
   *  The ArrayCollection class is a wrapper class that exposes an Array as
   *  a collection that can be accessed and manipulated using the methods
   *  and properties of the <code>ICollectionView</code> or <code>IList</code>
   *  interfaces. Operations on a ArrayCollection instance modify the data source;
   *  for example, if you use the <code>removeItemAt()</code> method on an
   *  ArrayCollection, you remove the item from the underlying Array.
   *
   *  @mxml
   *
   *  <p>The <code>&lt;mx:ArrayCollection&gt;</code> tag inherits all the attributes of its
   *  superclass, and adds the following attributes:</p>
   *
   *  <pre>
   *  &lt;mx:ArrayCollection
   *  <b>Properties</b>
   *  source="null"
   *  /&gt;
   *  </pre>
   *
   *  @example The following code creates a simple ArrayCollection object that
   *  accesses and manipulates an array with a single Object element.
   *  It retrieves the element using the IList interface <code>getItemAt</code>
   *  method and an IViewCursor object that it obtains using the ICollectionView
   *  <code>createCursor</code> method.
   *  <pre>
   *  var myCollection:ArrayCollection = new ArrayCollection([ { first: 'Matt', last: 'Matthews' } ]);
   *  var myCursor:IViewCursor = myCollection.createCursor();
   *  var firstItem:Object = myCollection.getItemAt(0);
   *  var firstItemFromCursor:Object = myCursor.current;
   *  if (firstItem == firstItemFromCursor)
   *        doCelebration();
   *  </pre>
   */
  public class DataArrayCollection extends ArrayCollection {
    public function DataArrayCollection(source:Array = null) {
      super(source);
    }
    

    //-----------------------
    // utilities
    //-----------------------

    /**
    * Utility function to clone an object
    */
    private function cloneObj(source:Object):* {
      var myBA:ByteArray = new ByteArray();
      myBA.writeObject(source);
      myBA.position = 0;
      return (myBA.readObject());
    }


    //-----------------------
    // key generation
    //-----------------------

    /**
    * A class variable to calculate unique keys
    */
    private static var keyID:int = 0;
    
    /**
    * Determines how to find duplicates
    * 
    * <p>If an Array of Strings are passed in
    * the Strings are treated as Flare Property lookups.</p>
    * 
    * <p>If a Function is passed, the function is evaluated
    * on each object in the list returning a String.</p>
    */
    public function set keyVars(v:Array):void {
      _keyVars = v;
      _keyLookup = null;      
      _keyProperties = v.map(function(element:String, index:int, array:Array):Property {
        return Property.$(element);
      });
      createKey = function(o:Object):String {
        var result:Array = _keyProperties.map(function(prop:Property, index:int, array:Array):String {
          return prop.getValue(o).toString();
        })
        trace('created key', result.join('#'));
        return result.join('#');
      }
    }

    public function get keyVars():Array {
      return _keyVars;
    }
    
    private var _keyVars:Array = [];
    private var _keyProperties:Array = [];

    
    
    /**
    * Create a key for an object in this list
    * 
    * <p>The default key creation algorithm generates a unique
    * ID for each element in the list. The key creation algorithm
    * can be replaced by setting <code>keyVars</code> to an
    * Array or a Function.</p>
    */
    private var createKey:Function = defaultCreateKey; 
    
    private static var defaultCreateKey:Function = function(itm:Object):String {
      keyID += 1;
      return keyID.toString();
    }
    
    /**
    * Storage for the keyLookup object
    */
    private var _keyLookup:Object;
    
    /**
    * A mapping of keys to Objects that is used to determine
    * if a new Object should be merged with an existing Object.
    *
    */
    private function get keyLookup():Object {
      // regenerate the keyLookup
      if (_keyLookup == null && this.length > 0) {
        _keyLookup = {};
        const len:int = this.length;        
        for (var i:int=0; i<len; i++) {
          var itm:Object = this.list.getItemAt(i);
          _keyLookup[createKey(itm)] = itm;
          trace('added key for ', createKey(itm));
        }
      }
      return _keyLookup;
    }


    //-----------------------
    // dataMode
    //-----------------------


    /**
     * Replace contents when <code>source</code> is set.
     */
    public static const REPLACE:String = 'replace';

    /**
     * Merge new content using <code>keyLookup</code>.
     * If a key does not exist in the new source, it
     * will be deleted from the list.
     */
    public static const REPLACE_MERGE:String = 'replacemerge';

    /**
     * Merge new content using <code>keyLookup</code>.
     * If a key does not exist in the new source, it
     * will be retained in the list.
     */
    public static const MERGE:String = 'merge';

    public var dataMode:String = DataArrayCollection.REPLACE_MERGE;


    //-----------------------
    // stats
    // Handle stats as in Flare DataList
    //-----------------------
				
		/** Cache of Stats objects for item properties. */
		private var _stats:Object = {};

		/**
		 * Computes and caches statistics for a data field. The resulting
		 * <code>Stats</code> object is cached, so that later access does not
		 * require any re-calculation. The cache of statistics objects may be
		 * cleared, however, if changes to the data set are made.
		 * @param field the property name
		 * @return a <code>Stats</code> object with the computed statistics
		 */
		[Bindable(event='collectionChange')]
		public function stats(field:String):Stats
		{
			// TODO: allow custom comparators?
			
			if (!_addedStatsListener) {
			  this.addEventListener(CollectionEvent.COLLECTION_CHANGE, clearAllStats);
			  _addedStatsListener = true;
			}
			
			// check cache for stats
			if (_stats[field] != undefined) {
				return _stats[field] as Stats;
			} else {
				return _stats[field] = new Stats(list.toArray(), field);
			}
		}
		
		private var _addedStatsListener:Boolean = false;
		
		
		
		/**
		 * Clears any cached stats for the given field. 
		 * @param field the data field to clear the stats for.
		 */
		public function clearStats(field:String):void
		{
			delete _stats[field];
		}
		
		/**
		 * Clears any cached stats for the given field. 
		 * @param field the data field to clear the stats for.
		 */
		public function clearAllStats(e:CollectionEvent):void
		{
		  _stats = {};
		}
		
    
    //-----------------------
    // data
    //-----------------------
				
		/** Internal set of data groups. */
		protected var _data:Object = {
		  'default': new Data()
		};
		
		/** Internal set of mapping from List objects to nodes in each Data */
		protected var _nodeLookup:Object = {
		  'default': new Dictionary(true)
		}
		

    /**
    * Storage for whether or not any of the 
    * Data objects are being used
    */		
		private var _addedSyncListener:Boolean = false;
		

		/**
		 * Adds a new Data object. If a Data object of the same name already exists,
		 * it will be replaced, except for the data object named "default" 
		 * which can not be replaced. 
		 * @param name the name of the data to add
		 * @param group the data list to add, if null a new,
		 *  empty <code>DataList</code> instance will be created.
		 * @return the added data group
		 */
		public function addData(name:String):Data
		{
			if (name == "default") {
				throw new ArgumentError("Illegal data name. \"default\" is a reserved name.");
			}
			var data:Data = new Data(false);
			_data[name] = data;
			_nodeLookup[name] = new Dictionary(false);
			createNodesFromArrayCollection(name);
			return data;
		}
		
		/**
		 * Removes a Data object. An error will be thrown if the caller
		 * attempts to remove the data object "default". 
		 * @param name the name of the data to remove
		 * @return the removed Flare Data object 
		 */
		public function removeData(name:String):Data
		{
			if (name == "default") {
				throw new ArgumentError("Illegal data name. \"default\" is a reserved name.");
			}
			var data:Data = _data[name];
			if (data) { 
			  delete _data[name];
			  delete _nodeLookup[name];
			}
			return data;
		}
		
		/**
		 * Retrieves the data object with the given name.
		 * 
		 * Create the default data object if it doesn't
		 * already exist.
		 *  
		 * @param name the name of the data
		 * @return the Flare Data object
		 */
		public function data(name:String='default'):Data
		{
			if (!_addedSyncListener) {
			  this.addEventListener(CollectionEvent.COLLECTION_CHANGE, syncDataNodes);
			  _addedSyncListener = true;
			}

		  if (!_defaultDataLoaded) {
		    createNodesFromArrayCollection('default');
		  }
			return _data[name] as Data;
		}
		
		/**
		 * @private
		 * 
		 * Load the Data object with the given name with the node
		 * sprites existing in the DataArrayCollection at this
		 * time.
		 */
		private function createNodesFromArrayCollection(name:String='default'):void {
		  var data:Data = _data[name];
		  if (data) {
		    var row:Object;
		    var node:NodeSprite;
		    var idx:int = 0;
		    var len:int = list.length;
		    var lookup:Dictionary = _nodeLookup[name] as Dictionary;
		    for (idx=0; idx<len; idx++) {
		      row = list.getItemAt(idx);
		      node = data.addNode(list.getItemAt(idx));
		      lookup[row] = node; 
		    }
		  }
		}
		

		/**
		 * Create and delete nodes that have been created in the ArrayCollection
		 */
		private function syncDataNodes(e:CollectionEvent):void {
		  trace('syncing data nodes');
		  for each (var evt:PropertyChangeEvent in e.items) {
		    if (evt.kind == 'update') {
		      for (var name:String in _data) {
		        var d:Data = _data[name];
		        var lookup:Dictionary = _nodeLookup[name];
            d.nodes.clearStats('data.' + evt.property);
            var node:NodeSprite = lookup[evt.source];
            d.dispatchEvent(new flare.vis.events.DataEvent(DataEvent.UPDATE, node, d.nodes));
		      }
		    }
		  }
		  //TODO: Add nodes
		  //TODO: Delete nodes
		}
		
		/**
		 * The 'default' data is loaded lazily. In most uses of <code>DataArrayCollection</data>,
		 * no <code>Data</code> object will be needed. 
		 */
    private var _defaultDataLoaded:Boolean = false;

    //-----------------------
    // source
    //-----------------------
				


    /**
     *  The source of data in the ArrayCollection.
     *  The ArrayCollection object does not represent any changes that you make
     *  directly to the source array. Always use
     *  the ICollectionView or IList methods to modify the collection.
     */
    override public function get source():Array {
      return super.source;
    }


    /**
     *  @private
     */
    override public function set source(s:Array):void {
      if (dataMode == DataArrayCollection.REPLACE || length == 0) {
        super.source = s;
      } else if (dataMode == DataArrayCollection.MERGE || dataMode == DataArrayCollection.REPLACE_MERGE) {
        if (dataMode == DataArrayCollection.REPLACE_MERGE) {
          var clonedKeyLookup:Object = cloneObj(keyLookup) as Object;
        }
        for each (var itm:Object in s) {          
          var k:String = createKey(itm);
          if (keyLookup[k] !== undefined) {
            if (dataMode == DataArrayCollection.REPLACE_MERGE) {
              delete clonedKeyLookup[k];
            }
            var existingItm:Object = keyLookup[k];
            // copy the new object into the old object
            // performing ListCollectionView appropriate
            // itemUpdated 
            for (var prop:String in itm) {
              var v:Object = itm[prop];
              var oldv:Object = existingItm[prop]
              if (v != oldv) {
                existingItm[prop] = v;
                list.itemUpdated(existingItm, prop, oldv, v);
              }
            }
          } else {
            trace('key NO match', k);
            list.addItem(itm);
          }
        }

        // if we're doing a replace merge, delete the items
        // that were not found in source    
        if (dataMode == DataArrayCollection.REPLACE_MERGE) {
          for (var idx:int=(list.length-1); idx>=0; idx--) {
            var deleteItm:Object = list.getItemAt(idx);
            if (clonedKeyLookup[createKey(deleteItm)] != undefined) {
              list.removeItemAt(idx);              
            }
          }
        }
      } else if (dataMode == DataArrayCollection.REPLACE_MERGE) {

      }
    }



  }
}