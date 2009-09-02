package  {
  import flare.scale.ScaleType;
  import flare.util.Shapes;
  import flare.vis.axis.Axis;
  import flare.vis.data.Data;
  import flare.vis.data.EdgeSprite;
  import flare.vis.operator.Operator;
  import flare.vis.operator.encoder.ColorEncoder;
  import flare.vis.operator.layout.AxisLayout;
  
  import mx.styles.StyleManager;
  
  import org.juicekit.charts.FlareCategoryValueChart;
  import org.juicekit.flare.util.Colors;
  import org.juicekit.flare.util.palette.ColorPalette;
  import org.juicekit.util.helper.CSSUtil;
  

  [Bindable]
  public class LLineChart extends FlareCategoryValueChart {
    public function LLineChart() {
      super();
      super.shape = Shapes.CIRCLE;
    }
    
    // Invoke the class constructor to initialize the CSS defaults.
    classConstructor();


    private static function classConstructor():void {      
      CSSUtil.setDefaultsFor("LLineChart",
        { fontColor: 0x333333
        , fontFamily: 'Arial'
        , fontSize: 12
        , fontWeight: 'normal'
        , fontStyle: 'normal'
        , textPosition: "top"
        , strokeAlpha: 1.0
        , strokeColor: 0x000000
        , strokeThickness: 0
        , encodedColorAlpha: 1.0
        }
      );
    }
    


    override protected function get categoryWidth():Number {
      return vis.bounds.width;
    }


    /** The tooltip format string. */
    private var _tipText:String = "<b>Category</b>: {0}<br/>" + "<b>Position</b>: {1}<br/>" + "<b>Value</b>: {2}";

    override public function get xyAxesCategoryReverse():Boolean { return vis.xyAxes.xReverse }
    override public function set xyAxesCategoryReverse(v:Boolean):void { vis.xyAxes.xReverse = v }
    override public function get xyAxesValueReverse():Boolean { return vis.xyAxes.yReverse }
    override public function set xyAxesValueReverse(v:Boolean):void { vis.xyAxes.yReverse = v }
    
    override public function get categoryAxis():Axis { return vis.xyAxes.xAxis; }
    override public function get valueAxis():Axis { return vis.xyAxes.yAxis; }
    
   /**
    * Create the axis layout
    */
    override protected function createAxisLayout():Operator {
      return new AxisLayout(asFlareProperty(categoryEncodingField), 
                            asFlareProperty(valueEncodingField), 
                            false, 
                            false);
    }
    
    //---------- line color palette ----------
    
    /**
    * Sets the color palette to use for the chart lines.
    * 
    * The value passed in can be a String, uint, or ColorPalette.
    * 
    * Some examples:
    * 
    * <ul>
    * <li><code>"0xff0000"</code> - A single color red palette</li> 
    * <li><code>"#ff0000"</code> - A single color red palette (CSS notation)</li> 
    * <li><code>"red"</code> - A single color red palette (CSS literal color notation)</li> 
    * <li><code>"0x88ff0000"</code> - A semi-transparent single color red palette</li> 
    * <li><code>0x88ff0000</code> - A semi-transparent single color red palette</li> 
    * <li><code>"Reds"</code> - The built-in "Reds" ColorPalette</li>
    * <li><code>ColorPalette.getPaletteByName('Reds').darken()</code> - A darker version of the built-in "Reds" ColorPalette</li>
    * <li><code>ColorPalette.getPaletteByName('Reds').darken(0.2).reverse()</code> - A still darker, reversed version of the built-in "Reds" ColorPalette</li>
    * </ul>
    * 
    * @default 'spectral'
    * 
    * @see org.juicekit.flare.util.palette.ColorPalette
    */
    public function set linePalette(v:*):void {
      if (v is ColorPalette) {
        _lineColorPalette = v;
      }
      else if (v is String) {
        // try to determine the color given a string
        var c:uint = StyleManager.getColorName(v);
        if (c != StyleManager.NOT_A_COLOR) {
          if (Colors.a(c) == 0) c = Colors.setAlpha(c, 255);
          _lineColorPalette = ColorPalette.fromColor(c);
        }
        else _lineColorPalette = ColorPalette.getPaletteByName(v);
      }
      else if (v is uint) {
        _lineColorPalette = ColorPalette.fromColor(v);        
      }
      _rawLinePalette = v;
      if (lineColorEncoder != null) lineColorEncoder.palette = colorPalette;
      propertyChanged();
    }
    public function get linePalette():* { return _rawLinePalette; }

    /**
    * The palette entered by the user
    */
    private var _rawLinePalette:* = _lineColorPalette; 

    
    /**
    * Stores the ColorPalette
    */
    protected var _lineColorPalette:ColorPalette = ColorPalette.getPaletteByName('spectral');

    /**
     * Return a color palette for interpolating color values
     * from the <code>colorEncodingField</code>'s data value.
     */
    protected function get lineColorPalette():ColorPalette {
      return _lineColorPalette;
    }
    
    private const OP_IX_LINECOLOR:int = 2; 
    

    //---------- color encoding field ----------
    public function get lineColorEncoder():ColorEncoder {
      if (vis && vis.operators.length >= OP_IX_LINECOLOR) {
        return vis.operators.getOperatorAt(OP_IX_LINECOLOR) as ColorEncoder;        
      } else {
        return null;    
      }
    }


    /**
    * Create the color encoder to encode the _colorEncodingField
    */
    protected function createLineColorEncoder():ColorEncoder {
      return new ColorEncoder('source.data.' + _lineColorEncodingField
                              , Data.EDGES
                              , "lineColor"
                              , ScaleType.LINEAR
                              , lineColorPalette.toFlareColorPalette());
    }

    
    //---------- color encoding field ----------

    /**
     * Specifies a data <code>Object</code> property's name used
     * to encode a treemap rectangle's color.
     *
     * @default "color"
     */
    [Inspectable(category="General")]
    public function set lineColorEncodingField(propertyName:String):void {
      _lineColorEncodingField = propertyName;
      if (lineColorEncoder != null) lineColorEncoder.source = 'source.data.' + _lineColorEncodingField; // asFlareProperty(_lineColorEncodingField);

      propertyChanged();
    }
    
    public function get lineColorEncodingField():String { return _lineColorEncodingField; }
    private var _lineColorEncodingField:String = "lineColor";


    override protected function createOperators():void {
        vis.operators.clear();
        vis.operators.add(createAxisLayout());
        vis.operators.add(createColorEncoder());
        vis.operators.add(createLineColorEncoder());
        for each (var op:Operator in extraOperators) {
          vis.operators.add(op);
        }
        propertyChanged();
        _extraOperatorsChanged = false;
    }

  }
}