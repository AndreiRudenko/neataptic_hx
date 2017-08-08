package neataptic.activators;

import neataptic.IActivator;


class BentIdentity implements IActivator {

	
	public var name:String = 'BentIdentity';
	

	public function new() {
		
	}
	
	public function activation(x:Float):Float {

		var d:Float = Math.sqrt(Math.pow(x, 2) + 1);
		return (d - 1) / 2 + x;

	}
	
	public function derivative(x:Float):Float {

		var d:Float = Math.sqrt(Math.pow(x, 2) + 1);
		return x / (2 * d) + 1;

	}


}