package neataptic.activators;


import neataptic.IActivator;


class HardTanh implements IActivator {

	
	public var name:String = 'HardTanh';
	

	public function new() {
		
	}
	
	public function activation(x:Float):Float {

		return Math.max(-1, Math.min(1, x));

	}
	
	public function derivative(x:Float):Float {

		return x > -1 && x < 1 ? 1 : 0;

	}


}