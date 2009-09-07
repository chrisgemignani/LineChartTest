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
  public class FlareLineChart extends FlareVisBase {
    public function FlareLineChart() {
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
      'yMax': 'vis.xyAxes.yAxis.axisScale.max',
      'markerColorField': 'markerColorEncoder.source',
      'lineColorField': 'lineColorEncoder.source',
      'markerSize': 'nodePropertyEncoder.values.size',
      'markerAlpha': 'nodePropertyEncoder.values.alpha',
      'borderWidth': 'nodePropertyEncoder.values.lineWidth',
      'borderColor': 'nodePropertyEncoder.values.lineColor',
      'lineWidth': 'edgePropertyEncoder.values.lineWidth',
      'valueAxisShowLines': 'vis.xyAxes.yAxis.showLines',
      'valueAxisShowLabels': 'vis.xyAxes.yAxis.showLabels',
      'categoryAxisShowLines': 'vis.xyAxes.xAxis.showLines',
      'categoryAxisShowLabels': 'vis.xyAxes.xAxis.showLabels',
      'valueAxisLabelFormat': 'vis.xyAxes.yAxis.labelFormat'      
    }

    /**
    series : data.series
    sortBy : 
    categoryField
    valueField
    categorySort : 'category'|'value'|'sort'

    markererColorField
    markererSize
    markererPalette
    markererAlpha
    
    // markerer border
    markererBorderColorField
    markererBorderWidth
    markererBorderPalette
    markererBorderAlpha
    
    // lines
    lineColorField
    linePalette
    lineAlpha
    lineWidth
    
    // value axis
    valueAxisShowLabels
    valueAxisShowLines
    valueAxisReverse
    valueAxisLabelFormat
    
    // category axis
    categoryAxisShowLabels
    categoryAxisShowLines
    categoryAxisLabelFormat
    categoryAxisReverse
    
    // private
    lineColorPalette
    markerBorderColorPalette    
    markerColorPalette
    
    
    extraOperators
    **/
    
    public var colorEncodingField:String = 'color';
    
    public var markerPalette:* = 'spectral';
    public var linePalette:* = 'spectral';

    //------------------------
    // fonts
    //------------------------

    public var fontSize:Number = 10;
    public var fontFamily:String = 'Arial';
    public var fontColor:String = '#333333';
    public var fontWeight:String = 'normal';
    public var fontStyle:String = 'normal';


    //------------------------
    // markers
    //------------------------

    public var markerColorField:String = 'data.series';
    public var markerSize:Number = 1.0;
    public var markerAlpha:Number = 1.0;
    public var lineColorField:String = 'source.data.series';
    public var lineWidth:Number = 2.0;
    public var borderWidth:Number = 1.0;
    public var borderColor:uint = 0x333333;
    public var masterAlpha:Number = 1.0;
    
    //------------------------
    // axes
    //------------------------
    
    public var valueAxisShowLines:Boolean = true;
    public var valueAxisShowLabels:Boolean = true;
    public var categoryAxisShowLines:Boolean = true;
    public var categoryAxisShowLabels:Boolean = true;
    public var valueAxisLabelFormat:String = '0';

    public var lineColorPalette:ColorPalette = ColorPalette.fromHeuristic('#999999');
    public var markerColorPalette:ColorPalette = ColorPalette.getPaletteByName('spectral');
    
    

    //------------------------
    // encoders
    //------------------------

    public var axisLayout:AxisLayout = new AxisLayout("data.date", "data.count");
    public var lineColorEncoder:ColorEncoder = new ColorEncoder(lineColorField, Data.EDGES, "lineColor", ScaleType.LINEAR, lineColorPalette);
    public var markerColorEncoder:ColorEncoder = new ColorEncoder(markerColorField, Data.NODES, "fillColor", ScaleType.LINEAR, markerColorPalette);
    public var nodePropertyEncoder:PropertyEncoder = new PropertyEncoder({lineAlpha: 1.0, alpha: markerAlpha, buttonMode: false, scaleX: 1, scaleY: 1, size: markerSize, lineColor: borderColor, lineWidth: borderWidth});
    public var edgePropertyEncoder:PropertyEncoder = new PropertyEncoder({lineWidth: lineWidth, lineAlpha: 1.0}, Data.EDGES);

    
    public function bad():void {
      //vis.xyAxes.yAxis.axisScale.max = 400;
      if (vis.operators[0].index == 0) {
        invalidateProperties();
        vis.operators[0].index = 1;
//				vis.bounds = vis.bounds.clone();
        vis.continuousUpdates = true;
        vis.controls.add(new DragControl(NodeSprite));
        vis.data.nodes.setProperties({buttonMode: true, scaleX: 2, scaleY: 2}, 1).play();
      } else {
        vis.continuousUpdates = false;
        vis.operators[0].index = 0;
        vis.controls.clear();

        // update, and delay axis visibility to after the update
        var t:Transitioner = vis.update(1.5);
//					t.$(vis.axes).alpha = 0;
//					t.$(vis.axes).visible = false;
//					t.addEventListener(TransitionEvent.END,
//						function(evt:TransitionEvent):void {
//							forces.showAxes(new Transitioner(0.5)).play();
//						}
//					);
        t.play();
      }
    }

    public static function getTimeline(N:int, M:int):Data {
      var MAX:Number = 60;
      var t0:Date = new Date(1979, 5, 15);
      var t1:Date = new Date(1982, 2, 19);
      var x:Number, f:Number;

      var data:Data = new Data();
      for (var j:uint = 0; j < M; ++j) {
        for (var i:uint = 0; i < N; ++i) {
          f = i / (N - 1);
          x = t0.time + f * (t1.time - t0.time);
          data.addNode({series: int(j), series2: i % 10, date: new Date(x), count: int((j * MAX / M) + MAX / M * (1 + Maths.noise(13 * f, j, Math.random())))});
        }
      }
      // create timeline edges connecting items sorted by date
      // and grouped by series
      data.createEdges("data.date", "data.series");
      return data;
    }



    public var yMax:Number = 50;


  }
}