package  {

  [Bindable]
  public class FlareBarChart extends FlareCategoryValueBase {
    public function FlareBarChart() {
      super();
      this.registerActions(actionMap);
    }
        
    
    /**
    * A proxy for Flare properties. The key is the
    * local property that may change. The value is either
    * a property that the new value should be assigned to,
    * or a function that will receive the PropertyChangeEvent.
    */
    private var actionMap:Object = {
    }

  }
}