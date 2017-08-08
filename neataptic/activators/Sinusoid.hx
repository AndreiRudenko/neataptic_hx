package neataptic.activators;

import neataptic.IActivator;

/**
 * Output range is [-1, 1]
 * 
 * I don't think anyone really uses this for neural networks,
 * but I added some of this for my own experimentations.
 * 
 */

class Sinusoid implements IActivator {


	public var name:String = 'Sinusoid';


	public function new() {
		
	}
	
	public function activation(x:Float):Float {

		return Math.sin(x);

	}
	
	public function derivative(x:Float):Float {

		return Math.cos(x);

	}
	

}