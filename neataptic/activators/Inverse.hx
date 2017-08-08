package neataptic.activators;


import neataptic.IActivator;


class Inverse implements IActivator {

	
	public var name:String = 'Inverse';
	
	
	public function new() {
		
	}
	
	public function activation(x:Float):Float {

		return 1 - x;

	}
	
	public function derivative(x:Float):Float {

		return -1;

	}


}