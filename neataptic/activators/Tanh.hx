package neataptic.activators;

import neataptic.IActivator;

/**
 * When x is negative, output is -1 to 0
 * When x is positive, output is 0 to 1
 * 
 * Output range is (-1, 1)
 * 
 */

class Tanh implements IActivator {


	public var name:String = 'Tanh';

	
	public function new() {
		
	}
	
	public function activation(x:Float):Float {

		var ep:Float = Math.exp(x);
		var en:Float = 1.0 / ep;
		return (ep - en) / (ep + en);

	}
	
	public function derivative(x:Float):Float {

		var fx:Float = activation(x);
		return 1.0 - fx * fx;

	}


}