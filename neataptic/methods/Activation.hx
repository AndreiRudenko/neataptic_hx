package neataptic.methods;


// https://en.wikipedia.org/wiki/Activation_function
// https://stats.stackexchange.com/questions/115258/comprehensive-list-of-activation-functions-in-neural-networks-with-pros-cons
import neataptic.activators.*;
import neataptic.IActivator;

class Activation {

	public static var LOGISTIC        	(default, null): IActivator = new Logistic();
	public static var TANH            	(default, null): IActivator = new Tanh();
	public static var IDENTITY        	(default, null): IActivator = new Identity();
	public static var STEP            	(default, null): IActivator = new Step();
	public static var RELU            	(default, null): IActivator = new Relu();
	public static var SOFTSIGN        	(default, null): IActivator = new SoftSign();
	public static var SINUSOID        	(default, null): IActivator = new Sinusoid();
	public static var GAUSSIAN        	(default, null): IActivator = new Gaussian();
	public static var BENT_IDENTITY   	(default, null): IActivator = new BentIdentity();
	public static var BIPOLAR         	(default, null): IActivator = new Bipolar();
	public static var BIPOLAR_SIGMOID 	(default, null): IActivator = new BipolarSigmoid();
	public static var HARD_TANH       	(default, null): IActivator = new HardTanh();
	public static var ABSOLUTE        	(default, null): IActivator = new Absolute();
	public static var INVERSE         	(default, null): IActivator = new Inverse();
	public static var SELU            	(default, null): IActivator = new Selu();

	public static var HARD_LIMIT        (default, null): IActivator = new HardLimit();


	public static var list:Array<IActivator> = [
	
		LOGISTIC,
		TANH,
		IDENTITY,
		STEP,
		RELU,
		SOFTSIGN,
		SINUSOID,
		GAUSSIAN,
		BENT_IDENTITY,
		BIPOLAR,
		BIPOLAR_SIGMOID,
		HARD_TANH,
		ABSOLUTE,
		INVERSE,
		SELU,

		HARD_LIMIT

	];
	
}