package {
  import flare.vis.operator.layout.AxisLayout;

  [Bindable]
  public class FlareCustomScatter extends FlareVisBase {
    public function FlareCustomScatter() {
      super();
      baseOperators.push(axisLayout);
      registerActions(actionMap);
    }

    // actionMap defines how public variables map to properties
    // in the Flare visualization
    private var actionMap:Object = {
      xField: 'axisLayout.xField', 
      yField: 'axisLayout.yField',
      offset: ['vis.xyAxes.xAxis.lineCapY1', 'vis.xyAxes.xAxis.lineCapY2', 'vis.xyAxes.xAxis.labelOffsetY',
               'vis.xyAxes.yAxis.lineCapX1', 'vis.xyAxes.yAxis.lineCapX2', ]
    }

    // set up two public properties
    public var xField:String = 'data.x';
    public var yField:String = 'data.y';
    public var offset:Number = 15;

    override protected function styleVis():void {
      axisLayout.xScale.preferredMax = 10;
      axisLayout.yScale.preferredMax = 10;

      vis.xyAxes.showBorder = false;
      vis.xyAxes.xAxis.showLines = true;
      vis.xyAxes.yAxis.showLines = true;
      vis.xyAxes.xReverse = false;
    }

    public var axisLayout:AxisLayout = new AxisLayout(xField, yField);

  }
}
