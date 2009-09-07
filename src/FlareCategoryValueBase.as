package  {
  import flare.animate.Transitioner;
  import flare.display.TextSprite;
  import flare.scale.ScaleType;
  import flare.util.Maths;
  import flare.vis.controls.DragControl;
  import flare.vis.data.Data;
  import flare.vis.data.NodeSprite;
  import flare.vis.operator.OperatorList;
  import flare.vis.operator.OperatorSwitch;
  import flare.vis.operator.encoder.ColorEncoder;
  import flare.vis.operator.encoder.PropertyEncoder;
  import flare.vis.operator.layout.AxisLayout;
  import flare.vis.operator.layout.ForceDirectedLayout;
  
  import flash.text.TextFormat;
  
  import mx.events.PropertyChangeEvent;
  import mx.styles.StyleManager;
  
  import org.juicekit.flare.util.Colors;
  import org.juicekit.flare.util.palette.ColorPalette;
  

  [Bindable]
  public class FlareCategoryValueBase extends FlareVisBase {
    public function FlareCategoryValueBase() {
      super();
      this.registerActions(actionMap);
      baseOperators.push(axisLayout);
      baseOperators.push(lineColorEncoder);
      baseOperators.push(markerColorEncoder);
      baseOperators.push(nodePropertyEncoder);
      baseOperators.push(edgePropertyEncoder);
    }
    

    private function createTextFormat():TextFormat {
      var c:uint = StyleManager.getColorName(fontColor);
      if (c != StyleManager.NOT_A_COLOR) {
        if (Colors.a(c) == 0) c = Colors.setAlpha(c, 255);
      }
      return new TextFormat(fontFamily, fontSize, c, fontWeight == 'bold', fontStyle == 'italic');
    }
    
    private function textFormatChanged(e:PropertyChangeEvent):void {
      const tf:TextFormat = createTextFormat();
      if (vis != null) {
        vis.xyAxes.xAxis.labelTextFormat = tf;
        vis.xyAxes.yAxis.labelTextFormat = tf;
      }
    }
    
    
    /**
    * A proxy for Flare properties. The key is the
    * local property that may change. The value is either
    * a property that the new value should be assigned to,
    * or a function that will receive the PropertyChangeEvent.
    */
    private var actionMap:Object = {
      'fontSize': textFormatChanged,
      'fontColor': textFormatChanged,
      'fontWeight': textFormatChanged,
      'fontFamily': textFormatChanged,
      'fontStyle': textFormatChanged,
      'valueAxisShowLines': 'vis.xyAxes.yAxis.showLines',
      'valueAxisShowLabels': 'vis.xyAxes.yAxis.showLabels',
      'categoryAxisShowLines': 'vis.xyAxes.xAxis.showLines',
      'categoryAxisShowLabels': 'vis.xyAxes.xAxis.showLabels',
      'valueAxisLabelFormat': 'vis.xyAxes.yAxis.labelFormat'      
    }

    //------------------------
    // fonts
    //------------------------

    public var fontSize:Number = 10;
    public var fontFamily:String = 'Arial';
    public var fontColor:String = '#333333';
    public var fontWeight:String = 'normal';
    public var fontStyle:String = 'normal';


    //------------------------
    // axes
    //------------------------
    
    public var valueAxisShowLines:Boolean = true;
    public var valueAxisShowLabels:Boolean = true;
    public var categoryAxisShowLines:Boolean = true;
    public var categoryAxisShowLabels:Boolean = true;
    public var valueAxisLabelFormat:String = '0';


    //------------------------
    // encoders
    //------------------------

    public var axisLayout:AxisLayout = new AxisLayout("data.date", "data.count");
    public var lineColorEncoder:ColorEncoder = new ColorEncoder(lineColorField, Data.EDGES, "lineColor", ScaleType.LINEAR, lineColorPalette);
    public var markerColorEncoder:ColorEncoder = new ColorEncoder(markerColorField, Data.NODES, "fillColor", ScaleType.LINEAR, markerColorPalette);
    public var nodePropertyEncoder:PropertyEncoder = new PropertyEncoder({lineAlpha: 1.0, alpha: markerAlpha, buttonMode: false, scaleX: 1, scaleY: 1, size: markerSize, lineColor: borderColor, lineWidth: borderWidth});
    public var edgePropertyEncoder:PropertyEncoder = new PropertyEncoder({lineWidth: lineWidth, lineAlpha: 1.0}, Data.EDGES);


  }
}