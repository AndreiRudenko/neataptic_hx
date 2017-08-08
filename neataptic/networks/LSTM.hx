package neataptic.networks;


import neataptic.Connection;
import neataptic.methods.ConnectionType;
import neataptic.methods.MutationType;
import neataptic.methods.GatingType;
import neataptic.Group;
import neataptic.Objects;
import neataptic.Layer;
import neataptic.Network;
import neataptic.NodeType;


/**
 * Creates a long short-term memory network
 */
	
class LSTM extends Network {


	public function new(_args:Array<Int>, ?_options:LSTMNetworkOptions) {

		if (_args.length < 3) {
			throw('You have to specify at least 3 layers');
		}

		var _output_layer = new Group(_args.pop());
		_output_layer.set(null, null, NodeType.output);


		if(_options == null) {
			_options = {};
		}

		if(_options.memory_to_memory == null) {
			_options.memory_to_memory = false;
		}

		if(_options.output_to_memory == null) {
			_options.output_to_memory = false;
		}

		if(_options.output_to_gates == null) {
			_options.output_to_gates = false;
		}

		if(_options.input_to_output == null) {
			_options.input_to_output = true;
		}

		if(_options.input_to_deep == null) {
			_options.input_to_deep = true;
		}

		var _input_layer = new Group(_args.shift()); // first argument
		_input_layer.set(null, null, NodeType.input);

		var _blocks = _args; // all the arguments in the middle

		var _nodes:Array<Group> = [];
		_nodes.push(_input_layer);
		var _previous = _input_layer;
		for (i in 0..._blocks.length) {
			var _block = _blocks[i];

			// Init required nodes (in activation order)
			var _input_gate = new Group(_block);
			var _forget_gate = new Group(_block);
			var _memory_cell = new Group(_block);
			var _output_gate = new Group(_block);
			var _output_block = i == _blocks.length - 1 ? _output_layer : new Group(_block);

			_input_gate.set(1);
			_forget_gate.set(1);
			_forget_gate.set(1);

			// Connect the input with all the nodes
			var _input = _previous.connect(_memory_cell, ConnectionType.all_to_all);
			_previous.connect(_input_gate, ConnectionType.all_to_all);
			_previous.connect(_output_gate, ConnectionType.all_to_all);
			_previous.connect(_forget_gate, ConnectionType.all_to_all);

			// Set up internal connections
			_memory_cell.connect(_input_gate, ConnectionType.all_to_all);
			_memory_cell.connect(_forget_gate, ConnectionType.all_to_all);
			_memory_cell.connect(_output_gate, ConnectionType.all_to_all);
			var _forget = _memory_cell.connect(_memory_cell, ConnectionType.one_to_one);
			var _output = _memory_cell.connect(_output_block, ConnectionType.all_to_all);

			// Set up gates
			_input_gate.gate(_input, GatingType.input);
			_forget_gate.gate(_forget, GatingType.self);
			_output_gate.gate(_output, GatingType.output);

			// Input to all memory cells
			if (_options.input_to_deep && i > 0) {
				var _in = _input_layer.connect(_memory_cell, ConnectionType.all_to_all);
				_input_gate.gate(_in, GatingType.input);
			}

			// Optional connections
			if (_options.memory_to_memory) {
				var _in = _memory_cell.connect(_memory_cell, ConnectionType.all_to_else);
				_input_gate.gate(_in, GatingType.input);
			}

			if (_options.output_to_memory) {
				var _in = _output_layer.connect(_memory_cell, ConnectionType.all_to_all);
				_input_gate.gate(_in, GatingType.input);
			}

			if (_options.output_to_gates) {
				_output_layer.connect(_input_gate, ConnectionType.all_to_all);
				_output_layer.connect(_forget_gate, ConnectionType.all_to_all);
				_output_layer.connect(_output_gate, ConnectionType.all_to_all);
			}

			// Add to array
			_nodes.push(_input_gate);
			_nodes.push(_forget_gate);
			_nodes.push(_memory_cell);
			_nodes.push(_output_gate);
			if (i != _blocks.length - 1) {
				_nodes.push(_output_block);
			}

			_previous = _output_block;

		}

		// input to output direct connection
		if (_options.input_to_output) {
			_input_layer.connect(_output_layer, ConnectionType.all_to_all);
		}

		_nodes.push(_output_layer);

		super(0,0);

		setup(cast _nodes);

	}

	
}


typedef LSTMNetworkOptions = {

	@:optional var memory_to_memory:Bool;
	@:optional var output_to_memory:Bool;
	@:optional var output_to_gates:Bool;
	@:optional var input_to_output:Bool;
	@:optional var input_to_deep:Bool;

}