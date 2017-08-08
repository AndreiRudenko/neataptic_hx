package neataptic.activators;

import neataptic.IActivator;

/**
 * Rectified Linear Unit (ReLU)
 * 
 * When x is negative, output 0
 * When x is positive, output x
 * 
 * Output range is [0, Inf)
 * 
 */

class Relu implements IActivator {


	public var name:String = 'Relu';

	
	public function new() {
		
	}
	
	public function activation(x:Float):Float {
		
		return x > 0.0 ? x : 0.0;
		
	}
	
	public function derivative(x:Float):Float {
		
		return x > 0.0 ? 1.0 : 0.0;
		
	}


}