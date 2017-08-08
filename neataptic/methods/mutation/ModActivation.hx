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
    	Activation.SELU
	];


	// public static function mutate_node(node:Node) {

	// 	// Can't be the same squash
	// 	var _squash:IActivator = allowed[(allowed.indexOf(node.squash) + Math.floor(Math.random() * (allowed.length - 1)) + 1) % allowed.length];
	// 	node.squash = _squash;

	// }

	// public static function mutate_network(network:Network) {

 //        // Has no effect on input node, so they are excluded
 //        if (!mutate_output && network.input + network.output == network.nodes.length) {
	// 		Log._debug('No nodes that allow mutation of activation function');
 //       		return;
 //        }

 //        var index = Math.floor(Math.random() * (network.nodes.length - (mutate_output ? 0 : network.output) - network.input) + network.input);
 //        var node = network.nodes[index];

 //        node.mutate(mutate_node);

	// }


}