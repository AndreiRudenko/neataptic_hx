package neataptic;


import neataptic.IActivator;
import neataptic.NodeType;
import neataptic.Connection;
import neataptic.Group;
import neataptic.methods.ConnectionType;
import neataptic.methods.Activation;
import neataptic.methods.MutationType;
import neataptic.utils.Log;


class Node extends Objects {


	public var bias:Float;
	public var squash:IActivator;
	public var type:NodeType;

	public var activation:Float = 0;
	public var derivative:Float = 0;

	public var state:Float = 0;
	public var old:Float = 0;

	// For dropout
	public var mask:Float = 1;

	// For tracking momentum
	public var previous_delta_bias:Float = 0;

	// Batch training
	public var total_delta_bias:Float = 0;

	public var connections:NodeConnections;

	public var index:Int;

	// Data for backpropagation
	public var error:NodeError;

	#if !js

	public var _tmparr_nodes:Array<Node> = [];
	public var _tmparr_float:Array<Float> = [];

	#end

	public function new(?_type:NodeType, _index:Int = -1) {

		super(ObjectsType.node);

		index = _index;

		bias = _type == NodeType.input ? 0 : Math.random() * 0.2 - 0.1;
		squash = Activation.LOGISTIC;

		type = _type == null ? NodeType.hidden : _type;

		connections = new NodeConnections([], [], [], new Connection(this, this, 0));

		error = {
			responsibility : 0,
			projected : 0,
			gated : 0
		}

	}

	public function activate(?_input:Float):Float {

		if(_input != null) {
			activation = _input;
			return activation;
		}

		old = state;

		// All activation sources coming from the node itself
		state = connections.self.gain * connections.self.weight * state + bias;

		// Activation sources coming from connections
		for (c in connections.input) {
			state += c.from.activation * c.weight * c.gain;
		}
		
		// Squash the values received
		activation = squash.activation(state) * mask;
		derivative = squash.derivative(state);

		// Update traces
		#if js // js is faster by creating new array ?
			var nodes:Array<Node> = [];
			var influences:Array<Float> = [];
		#else
			_tmparr_nodes.splice(0, _tmparr_nodes.length);
			_tmparr_float.splice(0, _tmparr_float.length);
			var nodes:Array<Node> = _tmparr_nodes;
			var influences:Array<Float> = _tmparr_float;
		#end

		for (c in connections.gated) {
			var node:Node = c.to;
			
			var index:Int = nodes.indexOf(node);
			if (index > -1) {
				influences[index] += c.weight * c.from.activation;
			} else {
				nodes.push(node);
				influences.push(c.weight * c.from.activation + (node.connections.self.gater == this ? node.old : 0));
			}

			// Adjust the gain to this nodes' activation
			c.gain = activation;
		}

		for (c in connections.input) {

			// Elegibility trace
			c.elegibility = connections.self.gain * connections.self.weight * c.elegibility + c.from.activation * c.gain;

			// Extended trace
			for (j in 0...nodes.length) {
				var node:Node = nodes[j];
				var influence:Float = influences[j];

				var index:Int = c.xtrace.nodes.indexOf(node);

				if (index > -1) {
					c.xtrace.values[index] = node.connections.self.gain * node.connections.self.weight * c.xtrace.values[index] + derivative * c.elegibility * influence;
				} else {
					// Does not exist there yet, might be through mutation
					c.xtrace.nodes.push(node);
					c.xtrace.values.push(derivative * c.elegibility * influence);
				}
			}
		}

		return activation;

	}

	public function propagate(_rate:Float = 0.3, _momentum:Float = 0, _update:Bool = false, _target:Float = 0) { // target = 0 ?
		
		// Error accumulator
		var _error:Float = 0;

		// Output nodes get their error from the enviroment
		if (type == NodeType.output) {
			error.responsibility = error.projected = _target - activation;
		} else { // the rest of the nodes compute their error responsibilities by backpropagation
			// error responsibilities from all the connections projected from this node

			for (c in connections.output) {
				var node = c.to;
				// Eq. 21
				_error += node.error.responsibility * c.weight * c.gain;
			}

			// Projected error responsibility
			error.projected = derivative * _error;

			// Error responsibilities from all connections gated by this neuron
			_error = 0;

			for (c in connections.gated) {
				var node = c.to;
				var influence = node.connections.self.gater == this ? node.old : 0;

				influence += c.weight * c.from.activation;
				_error += node.error.responsibility * influence;
			}

			// Gated error responsibility
			error.gated = derivative * _error;

			// Error responsibility
			error.responsibility = error.projected + error.gated;
		}

		if (type == NodeType.constant) {
			return;
		}

		// Adjust all the node's incoming connections
		for (c in connections.input) {

			var gradient = error.projected * c.elegibility;

			for (j in 0...c.xtrace.nodes.length) {
				var node = c.xtrace.nodes[j];
				var value = c.xtrace.values[j];
				gradient += node.error.responsibility * value;
			}

			// Adjust weight
			var delta_weight = _rate * gradient * mask;
			c.total_delta_weight += delta_weight;
			if (_update) {
				c.total_delta_weight += _momentum * c.previous_delta_weight;
				c.weight += c.total_delta_weight;
				c.previous_delta_weight = c.total_delta_weight;
				c.total_delta_weight = 0;
			}
		}

		// Adjust bias
		var _delta_bias = _rate * error.responsibility;
		total_delta_bias += _delta_bias;
		if (_update) {
			total_delta_bias += _momentum * previous_delta_bias;
			bias += total_delta_bias;
			previous_delta_bias = total_delta_bias;
			total_delta_bias = 0;
		}


	}

	override function connect(_obj:Objects, ?_method:ConnectionType, ?_weight:Float):Array<Connection> {

		var _connections:Array<Connection> = [];

		switch (_obj._type_) {
			case ObjectsType.node:{
				var _node:Node = cast _obj;
				if (_node == this) {
					// Turn on the self connection by setting the weight
					if (connections.self.weight != 0) {
						Log._debug('This connection already exists!');
					} else {
						connections.self.weight = _weight == null ? 1 : _weight;
					}
					_connections.push(connections.self);
				} else if (is_projecting_to(_node)) {
					throw('Already projecting a connection to this node!');
				} else {
					var connection = new Connection(this, _node, _weight);
					_node.connections.input.push(connection);
					connections.output.push(connection);

					_connections.push(connection);
				}

			}
			case ObjectsType.group:{
				var _group:Group = cast _obj;

				for (n in _group.nodes) {
					var connection = new Connection(this, n, _weight);
					n.connections.input.push(connection);
					connections.output.push(connection);
					_group.connections.input.push(connection);

					_connections.push(connection);
				}

			}
			case ObjectsType.layer:{

			}
		}

		return _connections;

	}

	override function disconnect(target:Objects, twosided:Bool = false):Void {

		if (target == this) {
			connections.self.weight = 0;
			return;
		}

		 // maybe use IntMap instead?
		for (i in 0...connections.output.length) {
			var c = connections.output[i];
			if (c.to == target) {
				connections.output.splice(i, 1);
				var j = c.to.connections.input.indexOf(c);
				c.to.connections.input.splice(j, 1);
				if (c.gater != null) {
					ungate([c]); // todo: this is not right
				}
				break;
			}
		}

		if (twosided) {
			target.disconnect(this);
		}

	}

	public function gate(_connections:Array<Connection>) {

		for (c in _connections) {
			connections.gated.push(c);
			c.gater = this;
		}

	}

	public function ungate(_connections:Array<Connection>) { //todo: i dont like this functions, need optimisation, maybe using IntMap instead

		var i:Int = _connections.length - 1;

		while(i >= 0) {
			var c = _connections[i];

			var index = connections.gated.indexOf(c);
			connections.gated.splice(index, 1);
			c.gater = null;
			c.gain = 1;
			i--;
		}

	}

	public inline function set(?_bias:Float, ?_squash:IActivator, ?_type:NodeType):Void {

		if (_bias != null) {
			bias = _bias;
		}
		if (_squash != null) {
			squash = _squash;
		}
		if (_type != null) {
			type = _type;
		}

	}

	override function clear() {

		activation = 0;

		for (c in connections.input) {

			c.elegibility = 0;
			c.xtrace = {
				nodes: [],
				values: []
			};
		}

		for (c in connections.gated) {
			c.gain = 0;
		}

		error.responsibility = error.projected = error.gated = 0;
		old = state = activation = 0;

	}

	/**
	 * Mutates the node with the given method
	 */
	public inline function mutate(_method:MutationType) {

		// if (method == null) {
		// 	throw('No mutate method given!');
		// }

		if(_method == MutationType.mod_activation) {
			var allowed:Array<IActivator> = neataptic.methods.mutation.ModActivation.allowed;
			var _squash = allowed[(allowed.indexOf(squash) + Math.floor(Math.random() * (allowed.length - 1)) + 1) % allowed.length];
			squash = _squash;

		} else if(_method == MutationType.mod_bias) {
			var min:Float = neataptic.methods.mutation.ModBias.min;
			var max:Float = neataptic.methods.mutation.ModBias.max;
			var modification = Math.random() * (max - min) + min;
			bias += modification;
		}

	}

	public function is_projecting_to(node:Node):Bool {

		for (c in connections.output) {
			if (c.to == node) {
				return true;
			}
		}

		if (node == this && connections.self.weight != 0) {
			return true;
		}

		return false;
		
	}

	public function is_projected_by(node:Node):Bool {

		for (c in connections.output) {
			if (c.from == node) {
				return true;
			}
		}

		if (node == this && connections.self.weight != 0) {
			return true;
		}

		return false;
		
	}

	public function to_json():NodeData {

		var _json = {
			bias: bias,
			type: type,
			squash: squash.name, // squash.id
			mask: mask
		};

		return _json;

	}

	public static function from_json(_json:NodeData) {

	    var node = new Node();
		node.bias = _json.bias;
		node.type = _json.type;
		node.mask = _json.mask;

		for (squash in neataptic.methods.Activation.list) { // todo: optimise, use stringmap, or intmap with macro, or array index (good)
			if (squash.name == _json.squash) {
				node.squash = squash;
				break;
			}
		}

		return node;

	}


}


class NodeConnections {


	public var input:Array<Connection>;
	public var output:Array<Connection>;
	public var gated:Array<Connection>;

	public var self:Connection;


	public function new(_input:Array<Connection>, _output:Array<Connection>, _gated:Array<Connection>, _self:Connection) {

		input = _input;
		output = _output;
		gated = _gated;

		self = _self;

	}


}


typedef NodeData = {

	var bias:Float;
	var type:NodeType;
	var squash:String;
	var mask:Float;
	@:optional var index:Int;
	
}


private typedef NodeError = {

	var responsibility:Float;
	var projected:Float;
	var gated:Float;
	
}

