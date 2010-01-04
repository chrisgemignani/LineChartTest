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
  import mx.utils.UIDUtil;

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
    
    //----------------------------------
    // dataProvider
    //----------------------------------

    public function set dataProvider(v:ArrayCollection):void {
      source = v.source;
      _dataProvider = v;
    }


    public function get dataProvider():ArrayCollection {
      return _dataProvider;
    }

    private var _dataProvider:ArrayCollection = null;

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

    /**
    * Storage for the nodeLookup object
    */
    private var nodeLookup:Dictionary = new Dictionary();
    
    
    /**
    * When creating an additional data list, add respective 
    * node lookups for the datalist in question.
    * 
    * Returns an Array of the added nodes
    */
    private function addNodeLookup(uid:String):Array {  //TODO: Why is this pointing at the data and not the node?
      var result:Array = []
      _data[uid].nodes.visit(function(d:DataSprite):void {
        var key:String = createKey(d.data);
        if (nodeLookup[key] === undefined) {
          nodeLookup[key] = {(uid as String): d};
        }
        else {
          nodeLookup[key][uid] = d;
        }
        result.push(d);
      });
      return result;
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
		};

    /**
    * Storage for whether or not any of the 
    * Data objects are being used
    */		
		private var _addedSyncListener:Boolean = false;
		

		/**
		 * Removes a Data object. 
		 * @param name the name of the data to remove
		 * @return the removed Flare Data object 
		 * 
		 * untested
		 */
		public function removeData(callingObject:Object):Data
		{
		  var uid:String;
		  if (callingObject is String) {
        uid = callingObject as String;
      }
      else {
        uid = UIDUtil.getUID(callingObject);
      }
			var data:Data = _data[uid];
			//Todo: Clearout nodeLookup of the offending uid
			if (data) { 
			  delete _data[uid];
			}
			return data;
		}
		
		/**
		 * Retrieves the data object with the given name.
		 *  
		 * @param name the name of the data
		 * @return the Flare Data object
		 */
    public function data(callingObject:Object):Data
    {
      var uid:String;
      if (callingObject is String) {
        uid = callingObject as String;
      }
      else {
        uid = UIDUtil.getUID(callingObject);
      }
      
      if (_data[uid] === undefined) {
        createNodesFromArrayCollection(uid);
      }
      return _data[uid] as Data;
    }
		
		/**
		 * @private
		 * 
		 * Load the Data object with the given name with the node
		 * sprites existing in the DataArrayCollection at this
		 * time.
		 */
		private function createNodesFromArrayCollection(name:String):void {
		  if (_data[name] === undefined) {
		    _data[name] = new Data(); 
		  }
		  var data:Data = _data[name];
		    var row:Object;
		    var node:NodeSprite;
		    var idx:int = 0;
		    var len:int = list.length;
		    for (idx=0; idx<len; idx++) {
		      row = list.getItemAt(idx);
		      node = data.addNode(list.getItemAt(idx));
		    }
		}
		

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
      var uid:String;
      if (dataMode == DataArrayCollection.REPLACE || length == 0) {
        super.source = s;
        nodeLookup = new Dictionary;
        for (uid in _data) {
          //Delete and recreate all the nodes in the accompanying lists
          (_data[uid] as Data).clear();
          createNodesFromArrayCollection(uid);
          var createdNodeList:Array = addNodeLookup(uid);
          _data[uid].dispatchEvent(new DataEvent(DataEvent.UPDATE, createdNodeList, _data[uid].nodes));
        }
      } else if (dataMode == DataArrayCollection.MERGE || dataMode == DataArrayCollection.REPLACE_MERGE) {
        if (dataMode == DataArrayCollection.REPLACE_MERGE) {
          //clonedKeyLookup keeps track of keys to delete from the
          //final result
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
                //Launch an event for each updated node
                for (uid in _data) {
                  if (nodeLookup[k] !== undefined && nodeLookup[k][uid] !== undefined) {
                    _data[uid].dispatchEvent(new DataEvent(DataEvent.UPDATE, nodeLookup[k][uid], _data[uid].nodes));
                  } 
                }
              }
            }
          } else {
            trace('key NO match', k);
            list.addItem(itm);
            keyLookup[k] = itm;
            //For each Datalist, create a new node and new node lookup
            //TODO: launch node creation event
            for (uid in _data) {
              var n:NodeSprite = (_data[uid] as Data).addNode(itm);
              if (nodeLookup[k] === undefined) {
                nodeLookup[k] = {(uid as String): n};
              }
              else {
                nodeLookup[k][uid] = n;
              }    
              _data[uid].dispatchEvent(new DataEvent(DataEvent.UPDATE, n, _data[uid].nodes));
            }
            
          }
        }

        // if we're doing a replace merge, delete the items
        // that were not found in source    
        if (dataMode == DataArrayCollection.REPLACE_MERGE) {
          for (var idx:int=(list.length-1); idx>=0; idx--) {
            var deleteItm:Object = list.getItemAt(idx);
            var deleteKey:String = createKey(deleteItm);
            if (clonedKeyLookup[deleteKey] !== undefined) {
              list.removeItemAt(idx);
              //Delete the appropriate nodesprites from all related lists
              if (nodeLookup[deleteKey] !== undefined) {
                for(uid in nodeLookup[deleteKey]) {
                  _data[uid].remove(nodeLookup[deleteKey][uid]);
                }
                delete nodeLookup[deleteKey];
                delete keyLookup[deleteKey];
              }
            }
          }
        }
      }
    }



  }
}