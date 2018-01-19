package neataptic;


import haxe.ds.IntMap;

import neataptic.IActivator;
import neataptic.Connection;
import neataptic.Node;
import neataptic.Neat;
import neataptic.NodeType;
import neataptic.methods.MutationType;
import neataptic.methods.Cost;
import neataptic.methods.Rate;

import neataptic.utils.Log;


class Network {

	public static var ID:Int = 0;

	public var id:Int;

	public var input:Int;
	public var output:Int;

	// Store all the node and connection genes
	public var nodes:Array<Node>; // Stored in activation order
	public var connections:Array<Connection>;
	public var gates:Array<Connection>;
	public var selfconns:Array<Connection>;

	// Regularization
	public var dropout:Float = 0;

	public var score:Null<Float>;


	public function new(_input:Int, _output:Int) {

		id = ID++;
		
		input = _input;
		output = _output;

		nodes = [];
		connections = [];
		gates = [];
		selfconns = [];

		// Create input and output nodes
		for (i in 0...(input + output)) {
			var type = (i < input) ? NodeType.input : NodeType.output;
			nodes.push(new Node(type));
		}
		// Connect input nodes with output nodes directly
		for (i in 0...input) {
			for (j in input...(output + input)) {
				// https://stats.stackexchange.com/a/248040/147931
				var weight = Math.random() * input * Math.sqrt(2 / input);
				connect(nodes[i], nodes[j], weight);
			}
		}
	}
	
	/**
	 * Activates the network
	 */
	public function activate(_input:Array<Float>, _training:Bool = false):Array<Float> {

		var output:Array<Float> = []; // todo: optimize, pool

		// Activate nodes chronologically
		var n:Node;
		for (i in 0...nodes.length) {
			n = nodes[i];
			if (n.type == NodeType.input) {
				n.activate(_input[i]);
			} else if (n.type == NodeType.output) {
				output.push(n.activate());
			} else {
				if (_training) {
					n.mask = Math.random() < this.dropout ? 0 : 1;
				}
				n.activate();
			}
		}

		return output;

	}

	/**
	 * Backpropagate the network
	 */
	public function propagate(_rate:Float, _momentum:Float, _update:Bool, _target:Array<Float>) {

		if (_target == null || _target.length != output) {
			throw('Output target length should match network output length');
		}

		var _tidx:Int = _target.length;

		// Propagate output nodes
		var i:Int = nodes.length - 1;
		var len:Int = nodes.length - output;
		while(i >= len) {
			nodes[i].propagate(_rate, _momentum, _update, _target[--_tidx]);
			i--;
		}

		// Propagate hidden and input nodes
		i = nodes.length - output - 1;
		while(i >= input) {
			nodes[i].propagate(_rate, _momentum, _update);
			i--;
		}

	}
	
	/**
	 * Clear the context of the network
	 */
	public function clear() {

		for (n in nodes) {
			n.clear();
		}

	}

	/**
	 * Connects the from node to the to node
	 */
	public function connect(_from:Node, _to:Node, ?_weight:Float):Array<Connection> {

		var _connections:Array<Connection> = _from.connect(_to, _weight);

		for (c in  _connections) {
			if (_from != _to) {
				connections.push(c);
			} else {
				selfconns.push(c);
			}
		}

		return _connections;

	}

	/**
	 * Disconnects the from node from the to node
	 */
	public function disconnect(_from:Node, _to:Node) {

		// Delete the connection in the network's connection array
		var _connections:Array<Connection> = _from == _to ? selfconns : connections;

		for (i in 0..._connections.length) {
			var connection = _connections[i];
			if (connection.from == _from && connection.to == _to) {
				if (connection.gater != null) {
					ungate(connection);
				}
				_connections.splice(i, 1);
				break;
			}
		}

		// Delete the connection at the sending and receiving neuron
		_from.disconnect(_to);

	}

	/**
	 * Gate a connection with a node
	 */
	public function gate(_node:Node, _connection:Connection) {

		if (nodes.indexOf(_node) == -1) {
			throw ('This node is not part of the network!');
		} else if (_connection.gater != null) {
			Log._debug('This connection is already gated!');
			return;
		}
		_node.gate([_connection]); // todo, remove array
		gates.push(_connection);

	}

	/**
	 *  Remove the gate of a connection
	 */
	public function ungate(_connection:Connection) {

		var index:Int = gates.indexOf(_connection);
		if (index == -1) {
			throw('This connection is not gated!');
		}

		gates.splice(index, 1);
		_connection.gater.ungate([_connection]); // todo, remove array

	}

	/**
	 *  Removes a node from the network
	 */
	public function remove(_node:Node) {

		var index:Int = this.nodes.indexOf(_node);

		if (index == -1) {
			throw('This node does not exist in the network!');
		}

		// Keep track of gaters
		var gaters:Array<Node> = [];

		// Remove selfconnections from this.selfconns
		disconnect(_node, _node);

		var keep_gates:Bool = neataptic.methods.mutation.SubNode.keep_gates;

		// Get all its inputting nodes
		var inputs:Array<Node> = [];
		var i:Int = _node.connections.input.length - 1;
		while(i >= 0) {
			var connection = _node.connections.input[i];
			if (keep_gates && connection.gater != null && connection.gater != _node) {
				gaters.push(connection.gater);
			}
			inputs.push(connection.from);
			disconnect(connection.from, _node);
			i--;
		}

		// Get all its outputing nodes
		var outputs:Array<Node> = [];
		i = _node.connections.output.length - 1;
		while(i >= 0) {
			var connection = _node.connections.output[i];
			if (keep_gates && connection.gater != null && connection.gater != _node) {
				gaters.push(connection.gater);
			}
			outputs.push(connection.to);
			disconnect(_node, connection.to);
			i--;
		}

		// Connect the input nodes to the output nodes (if not already connected)
		var _connections:Array<Connection> = [];
		for (_input in inputs) {
			for (_output in outputs) {
				if (!_input.is_projecting_to(_output)) {
					var conn = connect(_input, _output);
					_connections.push(conn[0]);
				}
			}
		}

		// Gate random connections with gaters
		for (g in gaters) {
			if (_connections.length == 0) {
				break;
			}
			var cidx:Int = Math.floor(Math.random() * _connections.length);
			gate(g, _connections[cidx]);
			_connections.splice(cidx, 1);
		}

		// Remove gated connections gated by this node
		i = _node.connections.gated.length - 1;
		while(i >= 0) {
			var conn = _node.connections.gated[i];
			ungate(conn);
			i--;
		}

		// Remove selfconnection
		disconnect(_node, _node);

		// Remove the node from this.nodes
		nodes.splice(index, 1);

	}

	/**
	 * Mutates the network with the given method
	 */
	public function mutate(_method:MutationType) {

		// if (_method == null) {
		// 	throw('No mutate method given!');
		// }

		switch (_method) {
			case MutationType.add_node:{
				// Look for an existing connection and place a node in between
				var _connection = connections[Math.floor(Math.random() * connections.length)];
				var _gater = _connection.gater;
				disconnect(_connection.from, _connection.to);

				// Insert the new node right before the old connection.to
				var _toidx:Int = nodes.indexOf(_connection.to);
				var _node = new Node(NodeType.hidden, nodes.length);

				// Random squash function
				_node.mutate(MutationType.mod_activation);

				// Place it in this.nodes
				var _minbound:Int = Std.int(Math.min(_toidx, nodes.length - output));
				// nodes.splice(_minbound, 0, _node);
				nodes.insert(_minbound, _node);

				// Now create two new connections
				var _newconn1 = connect(_connection.from, _node)[0];
				var _newconn2 = connect(_node, _connection.to)[0];

				// Check if the original connection was gated
				if (_gater != null) {
					gate(_gater, Math.random() >= 0.5 ? _newconn1 : _newconn2);
				}
			}
			case MutationType.sub_node:{
				// Check if there are nodes left to remove
				if (nodes.length == input + output) {
					Log._debug('No more nodes left to remove!');
					return;
				}

				// Select a node which isn't an input or output node
				var index = Math.floor(Math.random() * (nodes.length - output - input) + input);
				remove(nodes[index]);
			}
			case MutationType.add_conn:{
				// Create an array of all uncreated (feedforward) connections
				var _available:Array<Array<Node>> = [];
				for (i in 0...(nodes.length - output)) {
					var node1 = nodes[i];

					// for (j = Math.max(i + 1, this.input); j < this.nodes.length; j++) {
					var sl:Int = Std.int(Math.max(i + 1, input));
					for (j in sl...nodes.length) {
						var node2 = nodes[j];
						if (!node1.is_projecting_to(node2)) _available.push([node1, node2]);
					}
				}

				if (_available.length == 0) {
					Log._debug('No more connections to be made!');
					return;
				}

				var pair = _available[Math.floor(Math.random() * _available.length)];
				connect(pair[0], pair[1]);
			}
			case MutationType.sub_conn:{
				// List of possible connections that can be removed
				var _possible:Array<Connection> = [];

				for (c in connections) {
					// Check if it is not disabling a node
					if (c.from.connections.output.length > 1 && c.to.connections.input.length > 1 && nodes.indexOf(c.to) > nodes.indexOf(c.from)) {
						_possible.push(c);
					}
				}

				if (_possible.length == 0) {
					Log._debug('No connections to remove!');
					return;
				}

				var randomconn = _possible[Math.floor(Math.random() * _possible.length)];
				disconnect(randomconn.from, randomconn.to);
			}
			case MutationType.mod_weight:{
				var _min:Float = neataptic.methods.mutation.ModWeight.min;
				var _max:Float = neataptic.methods.mutation.ModWeight.max;
				var _allconnections = connections.concat(selfconns);
				var _connection = _allconnections[Math.floor(Math.random() * _allconnections.length)];
				var _modification = Math.random() * (_max - _min) + _min;
				_connection.weight += _modification;
			}
			case MutationType.mod_bias:{
				// Has no effect on input node, so they are excluded
				var _idx = Math.floor(Math.random() * (nodes.length - input) + input);
				var _node = this.nodes[_idx];
				_node.mutate(_method);
			}
			case MutationType.mod_activation:{
				// Has no effect on input node, so they are excluded
				var _mutate_output:Bool = neataptic.methods.mutation.ModActivation.mutate_output;

				if (!_mutate_output && input + output == nodes.length) {
					Log._debug('No nodes that allow mutation of activation function');
					return;
				}

				var _idx = Math.floor(Math.random() * (nodes.length - (_mutate_output ? 0 : output) - input) + input);
				var _node = nodes[_idx];

				_node.mutate(_method);
			}
			case MutationType.add_self_conn:{
				// Check which nodes aren't selfconnected yet
				var _possible:Array<Node> = [];
				for (i in input...nodes.length) {
					var node = nodes[i];
					if (selfconns.indexOf(node.connections.self) == -1) {
						_possible.push(node);
					}
				}

				if (_possible.length == 0) {
					Log._debug('No more self-connections to add!');
					return;
				}

				// Select a random node
				var _node = _possible[Math.floor(Math.random() * _possible.length)];

				// Connect it to himself
				connect(_node, _node);
			}
			case MutationType.sub_self_conn:{
				if (selfconns.length == 0) {
					Log._debug('No more self-connections to remove!');
					return;
				}
				var _conn = selfconns[Math.floor(Math.random() * selfconns.length)];
				disconnect(_conn.from, _conn.to);
			}
			case MutationType.add_gate:{
				var _allconnections = this.connections.concat(this.selfconns);

				// Create a list of all non-gated connections
				var _possible = [];
				for (c in _allconnections) {
					if (c.gater == null) {
						_possible.push(c);
					}
				}

				if (_possible.length == 0) {
					Log._debug('No more connections to gate!');
					return;
				}
				
				// Select a random gater node and connection, can't be gated by input
				var index = Math.floor(Math.random() * (nodes.length - input) + input);
				var _node = nodes[index];
				var _conn = _possible[Math.floor(Math.random() * _possible.length)];

				// Gate the connection with the node
				gate(_node, _conn);
			}
			case MutationType.sub_gate:{
				// Select a random gated connection
				if (gates.length == 0) {
					Log._debug('No more connections to ungate!');
					return;
				}

				var _idx = Math.floor(Math.random() * gates.length);
				var _gatedconn = gates[_idx];

				ungate(_gatedconn);
			}
			case MutationType.add_back_conn:{
				// Create an array of all uncreated (backfed) connections
				var _available:Array<Array<Node>> = [];
				for (i in input...nodes.length) {
					var node1 = nodes[i];
					for (j in input...i) {
						var node2 = nodes[j];
						if (!node1.is_projecting_to(node2)) _available.push([node1, node2]);
					}
				}

				if (_available.length == 0) {
					Log._debug('No more connections to be made!');
					return;
				}

				var _pair = _available[Math.floor(Math.random() * _available.length)];
				connect(_pair[0], _pair[1]);
			}
			case MutationType.sub_back_conn:{
				// List of possible connections that can be removed
				var _possible:Array<Connection> = [];

				for (c in connections) {
					// Check if it is not disabling a node
					if (c.from.connections.output.length > 1 && c.to.connections.input.length > 1 && nodes.indexOf(c.from) > nodes.indexOf(c.to)) {
						_possible.push(c);
					}
				}

				if (_possible.length == 0) {
					Log._debug('No connections to remove!');
					return;
				}

				var _randomconn = _possible[Math.floor(Math.random() * _possible.length)];
				disconnect(_randomconn.from, _randomconn.to);
			}
			case MutationType.swap_nodes:{
				var _mutate_output:Bool = neataptic.methods.mutation.SwapNodes.mutate_output;

				// Has no effect on input node, so they are excluded
				if ((_mutate_output && nodes.length - input < 2) || (!_mutate_output && nodes.length - input - output < 2)) {
					Log._debug('No nodes that allow swapping of bias and activation function');
					return;
				}

				var _index = Math.floor(Math.random() * (nodes.length - (_mutate_output ? 0 : output) - input) + input);
				var _node1 = nodes[_index];
				_index = Math.floor(Math.random() * (nodes.length - (_mutate_output ? 0 : output) - input) + input);
				var _node2 = nodes[_index];

				var _biastemp = _node1.bias;
				var _squashtemp = _node1.squash;

				_node1.bias = _node2.bias;
				_node1.squash = _node2.squash;
				_node2.bias = _biastemp;
				_node2.squash = _squashtemp;
			}
			default:{

			}

		}
		
	}

	/**
	 * Train the given set to this network
	 */
	
	public function train(_set:TrainingSet, _options:TrainOptions):TrainResult {

		if (_set[0].input.length != input || _set[0].output.length != output) {
			throw('Dataset input/output size should be same as network input/output size!');
		}

		if(_options == null) {
			_options = {};
		}

		// Warning messages
		if (_options.rate == null) {
			Log._debug('Using default learning rate, please define a rate!');
		}
		if (_options.iterations == null) {
			Log._debug('No target iterations given, running until error is reached!');
		}

		// Read the options
		var _target_error:Float = _options.error != null ? _options.error : 0.05;
		var _cost:CostFunc = _options.cost != null ? _options.cost : Cost.MSE;
		var _base_rate:Float = _options.rate != null ? _options.rate : 0.3;
		var _dropout:Float = _options.dropout != null ? _options.dropout : 0;
		var _momentum:Float = _options.momentum != null ? _options.momentum : 0;
		var _batch_size:Int = _options.batch_size != null ? _options.batch_size : 1;
		var _rate_policy:Float->Int->Float = _options.rate_policy != null ? _options.rate_policy : Rate.FIXED();

		var _start = haxe.Timer.stamp();

		if (_batch_size > _set.length) {
			throw('Batch size must be smaller or equal to dataset length!');
		} else if (_options.iterations == null && _options.error == null) {
			throw('At least one of the following options must be specified: error, iterations');
		} else if (_options.error == null) {
			_target_error = -1; // run until iterations
		} else if (_options.iterations == null) {
			_options.iterations = 0; // run until target error
		}

		var _trainset:TrainingSet = null;
		var _testset:TrainingSet = null;
		if (_options.cross_validate != null) {
			var _num_train = Math.ceil((1 - _options.cross_validate.test_size) * _set.length);
			_trainset = _set.slice(0, _num_train);
			_testset = _set.slice(_num_train);
		}

    	// Loops the training process
		var _current_rate:Float = _base_rate;
		var _iteration:Int = 0;
		var _error:Float = 1;

		while (_error > _target_error && (_options.iterations == 0 || _iteration < _options.iterations)) {

			if (_options.cross_validate != null && _error <= _options.cross_validate.test_error){
				break;
			}

			_iteration++;

			// Update the rate
			_current_rate = _rate_policy(_base_rate, _iteration);

			// Checks if cross validation is enabled
			if (_options.cross_validate != null) {
				trainset(_trainset, _batch_size, _current_rate, _momentum, _cost);
				if (_options.clear) {
					clear();
				}

				_error = test(_testset, _cost).error;

				if (_options.clear) {
					clear();
				}

			} else {
				_error = trainset(_set, _batch_size, _current_rate, _momentum, _cost);
				if (_options.clear) {
					clear();
				}

			}

			// Checks for options such as scheduled logs and shuffling
			if (_options.shuffle) {
				// for (j, x, i = _set.length; i; j = Math.floor(Math.random() * i), x = _set[--i], _set[i] = _set[j], _set[j] = x);
				var i:Int = _set.length;
				var j:Int;
				var x:TrainingData;
				while(i > 0) {
					j = Math.floor(Math.random() * i);
					x = _set[--i];
					_set[i] = _set[j];
					_set[j] = x;
				}
			}

			if (_options.log > 0 && _iteration % _options.log == 0) {
				trace('iteration', _iteration, 'error', _error, 'rate', _current_rate);
			}

			if (_options.schedule != null && _iteration % _options.schedule.iterations == 0) {
				_options.schedule.func({ error: _error, iteration: _iteration });
			}
		}

		if (_options.clear) {
			clear();
		}

		if (_dropout > 0) {
			for (n in nodes) {
				if (n.type == NodeType.hidden || n.type == NodeType.constant) {
					n.mask = 1 - _dropout;
				}
			}
		}

		return {
			error: _error,
			iterations: _iteration,
			time : haxe.Timer.stamp() - _start
		};

	}

	/**
	 * Performs one training epoch and returns the error
	 * private function used in this.train
	 */
	function trainset(_set:TrainingSet, _batch_size:Int, _current_rate:Float, _momentum:Float, _cost_function:CostFunc) {

		var errorsum:Float = 0;
		for (i in 0..._set.length) {
			var _input = _set[i].input;
			var _target = _set[i].output;

			// var update = !!((i + 1) % batchSize == 0 || (i + 1) == set.length);
			var _update = ((i + 1) % _batch_size == 0 || (i + 1) == _set.length);
			var _output = activate(_input, true);
			propagate(_current_rate, _momentum, _update, _target);

			errorsum += _cost_function(_target, _output);
		}
		return errorsum / _set.length;

	}

	/**
	 * Tests a set and returns the error and elapsed time
	 */
	function test(_set:TrainingSet, ?_cost:CostFunc):TestResult {

		// Check if dropout is enabled, set correct mask
		if (dropout > 0) {
			for (n in nodes) {
				if (n.type == NodeType.hidden || n.type == NodeType.constant) {
					n.mask = 1 - dropout;
				}
			}
		}
		if(_cost == null) {
			_cost = Cost.MSE;
		}

		var error:Float = 0;
		var start = haxe.Timer.stamp();

		for (s in _set) {
			var input = s.input;
			var target = s.output;
			var output = activate(input);
			error += _cost(target, output);
		}

		error /= _set.length;

		var results = {
			error: error,
			time: haxe.Timer.stamp() - start
		};

		return results;

	}

	/**
	 * Sets the value of a property for every node in this network
	 */
	public function set(?_bias:Float, ?_squash:IActivator):Void {

		for (n in nodes) {
			n.set(_bias, _squash);
		}

	}

	/**
	 * Evolves the network to reach a lower error on a dataset
	 */
	public function evolve(_set:TrainingSet, _options:EvolveOptions):TrainResult { // async ?

		if (_set[0].input.length != input || _set[0].output.length != output) {
			throw('Dataset input/output size should be same as network input/output size!');
		}

		// Read the options
		if(_options == null) {
			_options = {};
		}

		_options.log = _options.log == null ? 0 : _options.log;

		var _target_error:Float = _options.error != null ? _options.error : 0.05;
		var _growth:Float = _options.growth != null ? _options.growth : 0.0001;
		var _cost:CostFunc = _options.cost != null ? _options.cost : Cost.MSE;
		// var threads = _options.threads || (typeof navigator == null ? 1 : navigator.hardwareConcurrency);
		var _amount:Int = _options.amount != null ? _options.amount : 1;

		var _start = haxe.Timer.stamp();

		if (_options.iterations == null && _options.error == null) {
			throw('At least one of the following options must be specified: error, iterations');
		} else if (_options.error == null) {
			_target_error = -1; // run until iterations
		} else if (_options.iterations == null) {
			_options.iterations = 0; // run until target error
		}

		// Create the fitness function
		var _fitness_function = function (genome:Network):Float {

			if (_options.clear) {
				genome.clear();
			}

			var _score:Float = 0;
			for (i in 0..._amount) {
				_score -= genome.test(_set, _cost).error;
			}

			_score -= (genome.nodes.length - genome.input - genome.output + genome.connections.length + genome.gates.length) * _growth;
			_score = Math.isNaN(_score) ? Math.NEGATIVE_INFINITY : _score; // this can cause problems with fitness proportionate selection

			return _score / _amount;

		};

		// var _opt:Dynamic = _options;
		_options.network = this;
		var neat = new Neat(input, output, _fitness_function, _options); // todo

		var _error:Float = Math.NEGATIVE_INFINITY;
		var _best_fitness:Float = Math.NEGATIVE_INFINITY;
		var _best_genome:Network = null;

		while (_error < -_target_error && (_options.iterations == 0 || neat.generation < _options.iterations)) {
			// var fittest = await neat.evolve();
			var fittest:Network = neat.evolve();
			var fitness:Float = fittest.score;
			_error = fitness + (fittest.nodes.length - fittest.input - fittest.output + fittest.connections.length + fittest.gates.length) * _growth;

			if (fitness > _best_fitness) {
				_best_fitness = fitness;
				_best_genome = fittest;
			}

			if (_options.log > 0 && neat.generation % _options.log == 0) {
				trace('iteration: ${neat.generation}, fitness: ${fitness}, error: ${-_error}');
			}

			if (_options.schedule != null && neat.generation % _options.schedule.iterations == 0) {
				_options.schedule.func({ fitness: fitness, error: -_error, iteration: neat.generation });
			}
		}

		if (_best_genome != null) {

			// set vars from _best_genome to this network
			input = _best_genome.input; 
			output = _best_genome.output; 
			nodes = _best_genome.nodes; 
			connections = _best_genome.connections; 
			gates = _best_genome.gates; 
			selfconns = _best_genome.selfconns; 
			dropout = _best_genome.dropout; 
			score = _best_genome.score; 

			// for (i in _best_genome) {
			// 	this[i] = _best_genome[i];
			// }

			if (_options.clear) {
				clear();
			}
		}

		return {
			error : -_error,
			iterations: neat.generation,
			time : haxe.Timer.stamp() - _start
		}

	}

	/**
	 * Serialize to send to workers efficiently
	 */
	public function serialize() {

	}

	public function graph(width:Int, height:Int) {

		var _input = 0;
		var _output = 0;

		var json = {
			nodes: [],
			links: [],
			constraints: [{
				type: 'alignment',
				axis: 'x',
				offsets: []
			}, {
				type: 'alignment',
				axis: 'y',
				offsets: []
			}]
		};

		var i;
		for (i in 0...nodes.length) {
			var node = nodes[i];

			if (node.type == NodeType.input) {
				if (input == 1) {
					json.constraints[0].offsets.push({
						node: i,
						offset: 0.0
					});
				} else {
					json.constraints[0].offsets.push({
						node: i,
						offset: 0.8 * width / (input - 1) * _input++
					});
				}
				json.constraints[1].offsets.push({
					node: i,
					offset: 0.0
				});
			} else if (node.type == NodeType.output) {
				if (output == 1) {
					json.constraints[0].offsets.push({
						node: i,
						offset: 0.0
					});
				} else {
					json.constraints[0].offsets.push({
						node: i,
						offset: 0.8 * width / (output - 1) * _output++
					});
				}
				json.constraints[1].offsets.push({
					node: i,
					offset: -0.8 * height
				});
			}

			json.nodes.push({
				id: i,
				name: node.type == NodeType.hidden ? node.squash.name : NodeType.to_string(node.type).toUpperCase(),
				activation: node.activation,
				bias: node.bias
			});
		}

		var _connections = connections.concat(selfconns);
		for (i in 0..._connections.length) {
			var connection = _connections[i];
			if (connection.gater == null) {
				json.links.push({
					source: nodes.indexOf(connection.from),
					target: nodes.indexOf(connection.to),
					weight: connection.weight,
					gate : false
				});
			} else {
				// Add a gater 'node'
				var index = json.nodes.length;
				json.nodes.push({
					id: index,
					activation: connection.gater.activation,
					name: 'GATE',
					bias: 0
				});
				json.links.push({
					source: nodes.indexOf(connection.from),
					target: index,
					weight: 1 / 2 * connection.weight,
					gate : false
				});
				json.links.push({
					source: index,
					target: nodes.indexOf(connection.to),
					weight: 1 / 2 * connection.weight,
					gate : false
				});
				json.links.push({
					source: nodes.indexOf(connection.gater),
					target: index,
					weight: connection.gater.activation,
					gate: true
				});
			}
		}

		return json;
	}


	/**
	 * Convert the network to a json object
	 */
	public function to_json():NetworkData {

		var json:NetworkData = {
			nodes: [],
			connections: [],
			input: input,
			output: output,
			dropout: dropout
		};

		// So we don't have to use expensive .indexOf()
		for (i in 0...nodes.length) {
			nodes[i].index = i;
		}

		for (i in 0...nodes.length) {
			var node = nodes[i];
			var tojson = node.to_json();
			tojson.index = i;
			json.nodes.push(tojson);

			if (node.connections.self.weight != 0) {
				var tojson = node.connections.self.to_json();
				tojson.from = i;
				tojson.to = i;

				tojson.gater = node.connections.self.gater != null ? node.connections.self.gater.index : null;
				json.connections.push(tojson);
			}
		}

		for (c in connections) {
			var tojson = c.to_json();
			tojson.from = c.from.index;
			tojson.to = c.to.index;

			tojson.gater = c.gater != null ? c.gater.index : null;

			json.connections.push(tojson);
		}

		return json;

	}

	/**
	 * Convert a json object to a network
	 */
	public static function from_json(json:NetworkData):Network {

		var network = new Network(json.input, json.output);
		network.dropout = json.dropout;
		network.nodes = [];
		network.connections = [];

		for (i in 0...json.nodes.length) {
			network.nodes.push(Node.from_json(json.nodes[i]));
		}

		for (i in 0...json.connections.length) {
			var conn = json.connections[i];

			var connection = network.connect(network.nodes[conn.from], network.nodes[conn.to])[0];
			connection.weight = conn.weight;

			if (conn.gater != null) {
				network.gate(network.nodes[conn.gater], connection);
			}
		}

		return network;

	}

	/**
	 * Merge two networks into one
	 */
	public static function merge(network1, network2) {
		
	}

	/**
	 * Create an offspring from two parent networks
	 */
	public static function crossover(network1:Network, network2:Network, equal:Bool):Network {

		if (network1.input != network2.input || network1.output != network2.output) {
			throw("Networks don't have the same input/output size!");
		}

		// Initialise offspring
		var offspring = new Network(network1.input, network1.output);
		offspring.connections = [];
		offspring.nodes = [];

		// Save scores and create a copy
		var score1:Float = network1.score != null ? network1.score : 0.0;
		var score2:Float = network2.score != null ? network2.score : 0.0;

		// Determine offspring node size
		var size:Int;
		if (equal || score1 == score2) {
			var max = Math.max(network1.nodes.length, network2.nodes.length);
			var min = Math.min(network1.nodes.length, network2.nodes.length);
			size = Math.floor(Math.random() * (max - min + 1) + min);
		} else if (score1 > score2) {
			size = network1.nodes.length;
		} else {
			size = network2.nodes.length;
		}

		// Rename some variables for easier reading
		var outputSize = network1.output;

		// Set indexes so we don't need indexOf
		for (i in 0...network1.nodes.length) {
			network1.nodes[i].index = i;
		}

		for (i in 0...network2.nodes.length) {
			network2.nodes[i].index = i;
		}

		// Assign nodes from parents to offspring
		for (i in 0...size) {
			// Determine if an output node is needed
			var node:Node;
			if (i < size - outputSize) {
				var random = Math.random();
				node = random >= 0.5 ? network1.nodes[i] : network2.nodes[i];
				var other:Node = random < 0.5 ? network1.nodes[i] : network2.nodes[i];

				if (node == null || node.type == NodeType.output) {
					node = other;
				}
			} else {
				if (Math.random() >= 0.5) {
					node = network1.nodes[network1.nodes.length + i - size];
				} else {
					node = network2.nodes[network2.nodes.length + i - size];
				}
			}

			var newNode = new Node();
			newNode.bias = node.bias;
			newNode.squash = node.squash;
			newNode.type = node.type;

			offspring.nodes.push(newNode);
		}

		// Create arrays of connection genes
		var n1conns:IntMap<ConnectionData> = new IntMap<ConnectionData>();
		var n2conns:IntMap<ConnectionData> = new IntMap<ConnectionData>();

		// Normal connections
		for (c in network1.connections) {
			var data:ConnectionData = {
				weight: c.weight,
				from: c.from.index,
				to: c.to.index,
				gater: c.gater != null ? c.gater.index : -1
			};
			n1conns.set(Connection.innovation_id(data.from, data.to), data);
		}

		// Selfconnections
		for (c in network1.selfconns) {
			var data:ConnectionData = {
				weight: c.weight,
				from: c.from.index,
				to: c.to.index,
				gater: c.gater != null ? c.gater.index : -1
			};
			n1conns.set(Connection.innovation_id(data.from, data.to), data);
		}

		// Normal connections
		for (c in network2.connections) {
			var data:ConnectionData = {
				weight: c.weight,
				from: c.from.index,
				to: c.to.index,
				gater: c.gater != null ? c.gater.index : -1
			};
			n2conns.set(Connection.innovation_id(data.from, data.to), data);
		}
		// Selfconnections
		for (c in network2.selfconns) {
			var data:ConnectionData = {
				weight: c.weight,
				from: c.from.index,
				to: c.to.index,
				gater: c.gater != null ? c.gater.index : -1
			};
			n2conns.set(Connection.innovation_id(data.from, data.to), data);
		}

		// Split common conn genes from disjoint or excess conn genes
		var connections:Array<ConnectionData> = [];
		for (k in n1conns.keys()) {
			// Common gene
			if (n2conns.exists(k)) {
				var conn = Math.random() >= 0.5 ? n1conns.get(k) : n2conns.get(k);
				connections.push(conn);

				// Because deleting is expensive, just set it to some value
				// n2conns[keys1[i]] = undefined;
				n2conns.remove(k);
			} else if (score1 >= score2 || equal) {
				connections.push(n1conns.get(k));
			}
			
		}

		// Excess/disjoint gene
		if (score2 >= score1 || equal) {
			for (c in n2conns) {
				connections.push(c);
			}
		}

		// Add common conn genes uniformly
		for (connData in connections) {
			if (connData.to < size && connData.from < size) {
				var from = offspring.nodes[connData.from];
				var to = offspring.nodes[connData.to];
				var conn = offspring.connect(from, to)[0];

				conn.weight = connData.weight;

				if (connData.gater != -1 && connData.gater < size) {
					offspring.gate(offspring.nodes[connData.gater], conn);
				}
			}
		}

		return offspring;

	}


	/**
	 * Setup a network from a given array of connected nodes
	 */
	public function setup(list:Array<Objects>) {
		
		// Transform all groups into nodes
		var _nodes:Array<Node> = [];

		var _g:Group;
		var _l:Layer;
		var _n:Node;
		for (o in list) {
			switch (o._type_) {
				case ObjectsType.group:{
					_g = cast o;
					for (n in _g.nodes) {
						_nodes.push(n);
					}
				}
				case ObjectsType.layer:{
					_l = cast o;
					for (ln in _l.nodes) {
						if(ln.is(ObjectsType.group)) {
							_g = cast ln;
							for (gn in _g.nodes) {
								_nodes.push(gn);
							}
						}

					}
				}
				case ObjectsType.node:{
					_n = cast o;
					_nodes.push(_n);
				}
			}
		}

		// Determine input and output nodes
		var _inputs:Array<Node> = [];
		var _outputs:Array<Node> = [];
		var i:Int = _nodes.length - 1;
		while(i >= 0) {
			if (_nodes[i].type == NodeType.output || _nodes[i].connections.output.length + _nodes[i].connections.gated.length == 0) {
				_nodes[i].type = NodeType.output;
				output++;
				_outputs.push(_nodes[i]);
				_nodes.splice(i, 1);
			} else if (_nodes[i].type == NodeType.input || _nodes[i].connections.input.length == 0) {
				_nodes[i].type = NodeType.input;
				input++;
				_inputs.push(_nodes[i]);
				_nodes.splice(i, 1);
			}
			i--;
		}

		// Input nodes are always first, output nodes are always last
		_nodes = _inputs.concat(_nodes).concat(_outputs);

		if (input == 0 || output == 0) {
			throw('Given nodes have no clear input/output node!');
		}

		for (n in _nodes) {
			for (c in n.connections.output) {
				connections.push(c);
			}
			for (c in n.connections.gated) {
				gates.push(c);
			}
			if (n.connections.self.weight != 0) {
				selfconns.push(n.connections.self);
			}
		}

		nodes = _nodes;

		update_node_indexes();

	}

	public function update_node_indexes() {

		for (i in 0...nodes.length) {
			nodes[i].index = i;
		}
		
	}

}

typedef TrainingData = {

	input:Array<Float>,
	output:Array<Float>

}

typedef TrainingSet = Array<TrainingData>;

typedef TestResult = {

	var error:Float;
	var time:Float;

}

typedef TrainResult = {

	>TestResult,
	var iterations:Int;

}


typedef EvolveOptions = {

	>NeatOptions,

	@:optional var cost:CostFunc;
	@:optional var amount:Int;
	@:optional var growth:Float;
	@:optional var iterations:Int;
	@:optional var error:Float;
	@:optional var log:Int;
	@:optional var schedule:ScheduleFunc;
	@:optional var clear:Bool;

}

typedef TrainOptions = {

	@:optional var log:Int;
	@:optional var error:Float;
	@:optional var cost:CostFunc;
	@:optional var rate:Float;
	@:optional var dropout:Float;
	@:optional var shuffle:Bool;
	@:optional var iterations:Int;
	@:optional var schedule:ScheduleFunc;
	@:optional var clear:Bool;
	@:optional var momentum:Float;
	@:optional var rate_policy:Float->Int->Float;
	@:optional var batch_size:Int;
	@:optional var cross_validate:CrossValidateOpt;

}

typedef CrossValidateOpt = {

	var test_size:Int;
	var test_error:Float;

}

typedef ScheduleFunc = {

	@:optional var func:Dynamic->Void;
	@:optional var iterations:Int;

}

typedef NetworkData = {

	var nodes:Array<NodeData>;
	var connections:Array<ConnectionData>;
	var input:Int;
	var output:Int;
	var dropout:Float;

}
