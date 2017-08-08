package neataptic.activators;

import neataptic.IActivator;


class Gaussian implements IActivator {
	

	public var name:String = 'Gaussian';


	public function new() {
		
	}
	
	public function activation(x:Float):Float {

		return Math.exp(-Math.pow(x, 2));

	}
	
	public function derivative(x:Float):Float {

		var d:Float = Math.exp(-Math.pow(x, 2));
		return -2 * x * d;

	}
	

}