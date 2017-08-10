package neataptic.methods.mutation;


// import neataptic.Node;
// import neataptic.Network;
import neataptic.IActivator;
import neataptic.methods.Activation;


class ModActivation {
	

	public static var mutate_output:Bool = true;

	public static var allowed:Array<IActivator> = [
    	Activation.LOGISTIC,
    	Activation.TANH,
    	Activation.RELU,
    	Activation.IDENTITY,
    	Activation.STEP,
    	Activation.SOFTSIGN,
    	Activation.SINUSOID,
    	Activation.GAUSSIAN,
    	Activation.BENT_IDENTITY,
    	Activation.BIPOLAR,
    	Activation.BIPOLAR_SIGMOID,
    	Activation.HARD_TANH,
    	Activation.ABSOLUTE,
    	Activation.INVERSE,
        Activation.SELU,
        
    	Activation.HARD_LIMIT
	];

}