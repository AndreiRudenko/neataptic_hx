package neataptic.activators;


import neataptic.IActivator;


class Absolute implements IActivator {
	
	
	public var name:String = 'Absolute';
	

	public function new() {
		
	}

	public function activation(x:Float):Float {

		return Math.abs(x);

	}
	
	public function derivative(x:Float):Float {

		return x < 0 ? -1 : 1;

	}


}