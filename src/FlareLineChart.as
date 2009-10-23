package  {
  import flare.scale.ScaleType;
  import flare.util.Maths;
  import flare.vis.data.Data;
  
  import mx.events.PropertyChangeEvent;
  

  [Bindable]
  public class FlareLineChart extends FlareCategoryValueBase {
    public function FlareLineChart() {
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
      seriesField: setSeriesField
    }
    
    private function setSeriesField(e:PropertyChangeEvent):void {
      vis.data.createEdges(asFlareProperty(this.categoryEncodingField), asFlareProperty(seriesField));
    }
    public var seriesField:String;
    override protected function styleVis():void {
      if (seriesField != null) {
        vis.data.createEdges(asFlareProperty(categoryEncodingField), asFlareProperty(seriesField));        
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
      data.createEdges('data.date', 'data.series');
      return data;
    }

  }
}