package neataptic.activators;

import neataptic.IActivator;

/**
 * Logistic/Sigmoid function
 * 
 * When x is negative, output is 0 to 0.5
 * When x is positive, output is 0.5 to 1
 * Output range is (0, 1)
 * 
 */

class Logistic implements IActivator {


	public var name:String = 'Logistic';

	
	public function new() {
		
	}
	
	public function activation(x:Float):Float {

		return 1.0 / (1.0 + Math.exp(-x));

	}
	
	public function derivative(x:Float):Float {

		var fx:Float = activation(x);
		return fx * (1.0 - fx);

	}


}