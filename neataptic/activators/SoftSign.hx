package neataptic.activators;

import neataptic.IActivator;

/**
 * Output range is (-1, 1)
 * 
 */

class SoftSign implements IActivator {


	public var name:String = 'SoftSign';


	public function new() {
		
	}
	
	public function activation(x:Float):Float {

		return x / (1.0 + Math.abs(x));

	}
	
	public function derivative(x:Float):Float {

		return 1.0 / ((1.0 + Math.abs(x)) * (1.0 + Math.abs(x)));
		
	}


}