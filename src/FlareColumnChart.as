package  {
  import flare.util.Shapes;
  import flare.vis.data.DataSprite;
  import flare.vis.data.NodeSprite;
  
 

  [Bindable]
  public class FlareColumnChart extends FlareCategoryValueBase {
    public function FlareColumnChart() {
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


    override protected function styleNodes():void {
      vis.data.nodes.visit(function(d:DataSprite):void {
        var n:NodeSprite = d as NodeSprite;
        n.shape = Shapes.VERTICAL_BAR;
      });
    }

  }
}