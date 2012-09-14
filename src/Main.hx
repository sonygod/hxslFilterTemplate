import flash.display.BitmapData;
import format.agal.Tools;
import flash.media.Video;
typedef K = flash.ui.Keyboard;

/**
 * @Auther kikoqiu
 * kikoqiu@163.com
 */

class Shader extends format.hxsl.Shader {
	static var SRC = {
		var input : {
			pos : Float3
		};
		var tuv : Float2;
		function vertex() {
			var otmp:Float4;
			otmp.xyz = pos;
			otmp.w = 1;
			out = otmp;
			tuv =0.5 + otmp.xy*[0.5,-0.5];
		}
		function fragment( tex : Texture ) {
			/*
			//filter 1
			var vx_offset:Float = 0.5;			
			var hatch_y_offset:Float = 5;
			var lum_threshold_1:Float = 1;
			var lum_threshold_2:Float =0.7 ;
			var lum_threshold_3:Float = 0.5;
			var lum_threshold_4:Float = 0.5;
			
			var tc:Float3 = tex.get(tuv).xyz;
			var lum:Float = length(tc);
			var uv:Float2 = tuv* 256;
			
			var a:Float3=if (
					  ((lum < lum_threshold_1) * (mod(uv.x + uv.y, 10.0) == 0.0))
					+((lum < lum_threshold_2) * (mod(uv.x - uv.y, 10.0) == 0.0))
					+ ((lum < lum_threshold_3 )* (mod(uv.x + uv.y - hatch_y_offset, 10.0) == 0.0))
					+ ((lum < lum_threshold_4)  * (mod(uv.x - uv.y - hatch_y_offset, 10.0) == 0.0))
					> 0
				)
					[0.0, 0.0, 0.0]
				else
					[1.0, 1.0, 1.0];
					
			var o:Float4;
			o.xyz= if (tuv.x < (vx_offset - 0.005))
				a			
			else if (tuv.x >= (vx_offset + 0.005))
				tc
			else
				[1, 0, 0];
			o.w = 1;
			out = o;*/
			
			/*
			//filter 2
			var c:Float3 = tex.get(tuv).xyz;
			var lum:Float = dot([0.30, 0.59, 0.11], c);
			c *= if (lum < 0.2 ) 2 else 1; 

			var t:Float4;
			t.xyz = (c + ( 0.4 * 0.2)) * [0.1, 0.95, 0.2] ;
			t.w = 1;
			out = t;*/
			
			//edge detector
			var c1:Float3 = tex.get(tuv).xyz;
			var lum1:Float = dot([0.30, 0.59, 0.11], c1);
			var c2:Float3 = tex.get(tuv+[1.0/256,0]).xyz;
			var lum2:Float = dot([0.30, 0.59, 0.11], c2);
			
			var t:Float4;
			t.xyz = abs(lum1-lum2)*[1,1,1];
			t.w = 1;
			out = t;
			
		}
	};
}

class CopyShader extends format.hxsl.Shader {
	static var SRC = {
		var input : {
			pos : Float3
		};
		var tuv : Float2;
		function vertex() {
			var otmp:Float4;
			otmp.xyz = pos;
			otmp.w = 1;
			out = otmp;
			tuv = 0.5 + otmp.xy*[0.5,-0.5];
		}
		function fragment( tex : Texture ) {
			out = tex.get(tuv) ;
		}
	};
}
class Filter {
	var texture1 : flash.display3D.textures.Texture;
	var texture2 : flash.display3D.textures.Texture;
	var currentTarget : flash.display3D.textures.Texture;
	
	var width:Int;
	var height:Int;
	var pol : Polygon;
	var c:flash.display3D.Context3D;
	var cs:CopyShader;
	

	
	public function new(w:Int, h:Int, c:flash.display3D.Context3D) {
		this.c = c;
		width = w;
		height = h;
		
		texture1 = c.createTexture(w, h, flash.display3D.Context3DTextureFormat.BGRA, true);
		texture2 = c.createTexture(w, h, flash.display3D.Context3DTextureFormat.BGRA, true);
		
		pol = new Plane();
		pol.alloc(c);
		
		cs = new CopyShader(c);		
	}
	public function setup(bmp:BitmapData) {
		texture1.uploadFromBitmapData(bmp);
		currentTarget = texture2;
		c.setRenderToTexture(currentTarget);		
	}
	
	public function filter(shader:Shader) {		
		c.clear(0, 0, 0, 1);
		c.setDepthTest( true, flash.display3D.Context3DCompareMode.LESS_EQUAL );
		c.setCulling(flash.display3D.Context3DTriangleFace.BACK);
		
		shader.init(
			{},
			{ tex : currentTarget==texture1?texture2:texture1 }
		);

		shader.bind(pol.vbuf);
		c.drawTriangles(pol.ibuf);
		
		currentTarget = currentTarget==texture1?texture2:texture1;
		c.setRenderToTexture(currentTarget);
	}
	
	
	public function renderToBackBuffer() {
		c.setRenderToBackBuffer();
		
		c.clear(0, 0, 0, 1);
		c.setDepthTest( true, flash.display3D.Context3DCompareMode.LESS_EQUAL );
		c.setCulling(flash.display3D.Context3DTriangleFace.BACK);
		
		cs.init(
			{},
			{ tex : currentTarget==texture1?texture2:texture1 }
		);

		cs.bind(pol.vbuf);
		c.drawTriangles(pol.ibuf);	
		c.present();
	}
	
	public function getRenderBuffer():BitmapData {
		var ret:BitmapData = new BitmapData(width, height);
		c.drawToBitmapData(ret);
		return ret;
	}	
	
	public function dispose() {
		texture1.dispose();
		texture2.dispose();
		pol.dispose();
	}
	
}
class Main {
	var stage : flash.display.Stage;
	var s : flash.display.Stage3D;
	var c : flash.display3D.Context3D;
	var shader : Shader;
	var filter:Filter;
	var cam:flash.media.Camera;
	private var video:Video;

	function new() {
		stage = flash.Lib.current.stage;
		s = stage.stage3Ds[0];
		s.addEventListener( flash.events.Event.CONTEXT3D_CREATE, onReady );
		stage.addEventListener( flash.events.KeyboardEvent.KEY_DOWN, callback(onKey,true) );
		stage.addEventListener( flash.events.KeyboardEvent.KEY_UP, callback(onKey,false) );
		flash.Lib.current.addEventListener(flash.events.Event.ENTER_FRAME, update);
		s.requestContext3D();
		
		
		cam = flash.media.Camera.getCamera();
		cam.setMode(256, 256, 30);
		video = new Video(256, 256);
        video.attachCamera(cam);
		video.x = 5000;
        stage.addChild(video);
	}
	
	function onKey( down, e : flash.events.KeyboardEvent ) {
	}

	function onReady( _ ) {
		c = s.context3D;
		c.enableErrorChecking = true;
		c.configureBackBuffer( stage.stageWidth, stage.stageHeight, 0, true );
		
		shader = new Shader(c);
		filter = new Filter(256, 256, c);
	}

	function update(_) {
		if ( filter == null  ) return;
		
		var bmd:BitmapData = new BitmapData(256, 256);
        bmd.draw(video);
				
		filter.setup(bmd);
		filter.filter(shader);
		filter.renderToBackBuffer();
	}

	static function main() {
		haxe.Log.setColor(0xFF0000);
		var inst = new Main();
	}

}