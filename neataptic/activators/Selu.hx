package neataptic.activators;


import neataptic.IActivator;


 // https://arxiv.org/pdf/1706.02515.pdf


class Selu implements IActivator {


	public static inline var alpha:Float = 1.6732632423543772848170429916717;
	public static inline var scale:Float = 1.0507009873554804934193349852946;


	public var name:String = 'Selu';
	

	public function new() {
		
	}
	
	public function activation(x:Float):Float {
			
		var fx:Float = x > 0 ? x : alpha * Math.exp(x) - alpha;
		return fx * scale;
		
	}
	
	public function derivative(x:Float):Float {
		
		var fx:Float = x > 0 ? x : alpha * Math.exp(x) - alpha;
		return x > 0 ? scale : (fx + alpha) * scale;
		
	}


}