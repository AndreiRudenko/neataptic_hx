package neataptic.activators;

import neataptic.IActivator;

/**
 * Output same as input
 * 
 * Output range is (-Inf, Inf)
 * 
 */

class Identity implements IActivator {


	public var name:String = 'Identity';
	

	public function new() {
		
	}
	
	public function activation(x:Float):Float {
		
		return x;

	}
	
	public function derivative(x:Float):Float {

		return 1.0;

	}


}