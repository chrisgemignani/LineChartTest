package  {
  import flare.scale.ScaleType;
  import flare.util.Shapes;
  import flare.vis.data.Data;
  import flare.vis.operator.encoder.ColorEncoder;
  import flare.vis.operator.encoder.PropertyEncoder;
  import flare.vis.operator.layout.AxisLayout;
  
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
    
    private function colorPaletteChanged(e:PropertyChangeEvent):void {
      if (e.property == 'markerPalette') {
        markerColorPalette = ColorPalette.fromHeuristic(e.newValue);
        markerColorEncoder.palette = markerColorPalette;
      }
      if (e.property == 'linePalette') {
        lineColorPalette = ColorPalette.fromHeuristic(e.newValue);
        lineColorEncoder.palette = lineColorPalette;
      }
    }
    
    //private function valueEncodingFieldChanged(e:
    
    
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
      
      'markerPalette': colorPaletteChanged,
      'linePalette': colorPaletteChanged, 

      'markerColorField': '@markerColorEncoder.source',
      'lineColorField': '@lineColorEncoder.source',
      'valueEncodingField': '@axisLayout.yField',
      'categoryEncodingField': '@axisLayout.xField',

      'markerSize': 'nodePropertyEncoder.values.size',
      'markerAlpha': 'nodePropertyEncoder.values.alpha',
      'markerShape': 'nodePropertyEncoder.values.shape',
      'borderWidth': 'nodePropertyEncoder.values.lineWidth',
      'borderColor': 'nodePropertyEncoder.values.lineColor',
      'lineWidth': 'edgePropertyEncoder.values.lineWidth',
      'stacked': 'axisLayout.yStacked',
      
      'valueMax': 'vis.xyAxes.yAxis.axisScale.preferredMax',
      'valueMin': 'vis.xyAxes.yAxis.axisScale.preferredMin',
      'zeroBased': 'vis.xyAxes.yAxis.axisScale.baseAtZero',
      'valueAxisReverse': 'vis.xyAxes.yReverse',      
      'valueAxisShowLines': 'vis.xyAxes.yAxis.showLines',
      'valueAxisShowLabels': 'vis.xyAxes.yAxis.showLabels',
      'valueAxisLabelFormat': 'vis.xyAxes.yAxis.labelFormat',
      
      'categoryAxisReverse': 'vis.xyAxes.xReverse',      
      'categoryAxisShowLines': 'vis.xyAxes.xAxis.showLines',
      'categoryAxisShowLabels': 'vis.xyAxes.xAxis.showLabels'
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
    
    public var zeroBased:Boolean = false;
    public var valueAxisShowLines:Boolean = true;
    public var valueAxisShowLabels:Boolean = true;
    public var valueAxisLabelFormat:String = '0';
    public var valueAxis:Boolean = true;
    public var valueMax:Number = 100;
    public var valueMin:Number = 100;
    public var valueAxisReverse:Boolean = false;
    public var categoryAxisShowLines:Boolean = true;
    public var categoryAxisShowLabels:Boolean = true;
    public var categoryAxisReverse:Boolean = false;


    public var colorEncodingField:String = 'color';
    
    public var markerPalette:* = 'spectral';
    public var linePalette:* = 'spectral';


    //------------------------
    // markers
    //------------------------

    public var valueEncodingField:String = 'data.count';
    public var categoryEncodingField:String = 'data.date';
    public var markerColorField:String = 'data.series';
    public var markerSize:Number = 1.0;
    public var markerAlpha:Number = 1.0;
    public var lineColorField:String = 'source.data.series';
    public var lineWidth:Number = 2.0;
    public var borderWidth:Number = 1.0;
    public var borderColor:uint = 0x333333;
    public var masterAlpha:Number = 1.0;
    public var markerShape:String = Shapes.CIRCLE;
    public var stacked:Boolean = false;
    
    public var lineColorPalette:ColorPalette = ColorPalette.fromHeuristic('#999999');
    public var markerColorPalette:ColorPalette = ColorPalette.getPaletteByName('spectral');
    
    //------------------------
    // encoders
    //------------------------

    public var axisLayout:AxisLayout = new AxisLayout(categoryEncodingField, valueEncodingField);
    public var lineColorEncoder:ColorEncoder = new ColorEncoder(lineColorField, Data.EDGES, "lineColor", ScaleType.LINEAR, lineColorPalette);
    public var markerColorEncoder:ColorEncoder = new ColorEncoder(markerColorField, Data.NODES, "fillColor", ScaleType.LINEAR, markerColorPalette);
    public var nodePropertyEncoder:PropertyEncoder = new PropertyEncoder(
      {lineAlpha: 1.0, 
       alpha: markerAlpha, 
       //shape: markerShape,
       size: markerSize, 
       lineColor: borderColor, 
       lineWidth: borderWidth
       }, Data.NODES);
    public var edgePropertyEncoder:PropertyEncoder = new PropertyEncoder(
      {lineWidth: lineWidth, 
       lineAlpha: 1.0
       }, Data.EDGES);

  }
}