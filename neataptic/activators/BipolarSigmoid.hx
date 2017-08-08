package neataptic.activators;

import neataptic.IActivator;


class BipolarSigmoid implements IActivator {


	public var name:String = 'BipolarSigmoid';
	

	public function new() {
		
	}

	public function activation(x:Float):Float {
		
		return 2 / (1 + Math.exp(-x)) - 1;

	}
	
	public function derivative(x:Float):Float {

		var d:Float = 2 / (1 + Math.exp(-x)) - 1;
		return 1 / 2 * (1 + d) * (1 - d);

	}


}