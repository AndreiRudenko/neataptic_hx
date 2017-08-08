package neataptic.activators;

import neataptic.IActivator;


class Bipolar implements IActivator {
	

	public var name:String = 'Bipolar';


	public function new() {
		
	}

	public function activation(x:Float):Float {
		
		return x > 0.0 ? 1.0 : -1.0;

	}
	
	public function derivative(x:Float):Float {

		return 0;

	}


}