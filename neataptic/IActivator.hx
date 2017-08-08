package neataptic;


// https://en.wikipedia.org/wiki/Activation_function
// https://stats.stackexchange.com/questions/115258/comprehensive-list-of-activation-functions-in-neural-networks-with-pros-cons


interface IActivator {

	public var name:String;
	public function activation(x:Float):Float;
	public function derivative(x:Float):Float;
	
}