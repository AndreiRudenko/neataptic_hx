package neataptic;


import neataptic.IActivator;
import neataptic.NodeType;
import neataptic.Node;
import neataptic.methods.ConnectionType;
import neataptic.methods.GatingType;

import neataptic.utils.Log;


class Group extends Objects {


	public var nodes:Array<Node>;
	public var connections:GroupConnections;
	

	public function new(size:Int) {

		super(ObjectsType.group);

		nodes = [];
		connections = new GroupConnections([], [], []);

		for (i in 0...size) {
			nodes.push(new Node());
		}

	}

	/**
	 * Activates all the nodes in the group
	 */
	public function activate(?value:Array<Float>):Array<Dynamic> {

		var values:Array<Dynamic> = [];

		if (value != null && value.length != nodes.length) {
			throw('Array with values should be same as the amount of nodes!');
		}

		var _n:Objects;
		for (i in 0...nodes.length) {
			_n = nodes[i];
			var _activation:Dynamic = null;
			if(_n.is(ObjectsType.node)) {
				var _node:Node = cast _n;
				if (value == null) {
					_activation = _node.activate();
				} else {
					_activation = _node.activate(value[i]);
				}
			} else if(_n.is(ObjectsType.group)) {
				var _group:Group = cast _n;
				_activation = _group.activate(value);
			}

			values.push(_activation);
		}

		return values;

	}

	/**
	 * Propagates all the node in the group
	 */
	public function propagate(?rate:Float, ?momentum:Float, ?target:Array<Float>):Void {

		if (target != null && target.length != nodes.length) {
			throw('Array with values should be same as the amount of nodes!');
		}

		var _n:Objects;
		var i:Int = nodes.length - 1;
		while(i >= 0) {
			_n = nodes[i];
			if(_n.is(ObjectsType.node)) {
				var _node:Node = cast _n;
				if (target == null) {
					_node.propagate(rate, momentum);
				} else {
					_node.propagate(rate, momentum, false, target[i]);
				}
			} else if(_n.is(ObjectsType.group)) {
				var _group:Group = cast _n;
				_group.propagate(rate, momentum, target);
			}
			i--;
		}

	}

	/**
	 * Connects the nodes in this group to nodes in another group or just a node
	 */
	override function connect(_target:Objects, ?_method:ConnectionType, ?_weight:Float):Array<Connection> {

		var _connections:Array<Connection> = [];

		switch (_target._type_) {
			case ObjectsType.group:{
				var _group:Group = cast _target;
				if (_method == null) {
					if (this != _group) {
						Log._debug('No group connection specified, using ALL_TO_ALL');
						_method = ConnectionType.all_to_all;
					} else {
						Log._debug('No group connection specified, using ONE_TO_ONE');
						_method = ConnectionType.one_to_one;
					}
				}
				if (_method == ConnectionType.all_to_all || _method == ConnectionType.all_to_else) {
					for (i in 0...nodes.length) {
						for (j in 0..._group.nodes.length) {
							if (_method == ConnectionType.all_to_else && nodes[i] == _group.nodes[j]) {
								continue;
							}
							var connection = nodes[i].connect(_group.nodes[j], _weight);
							connections.output.push(connection[0]);
							_group.connections.input.push(connection[0]);
							_connections.push(connection[0]);
						}
					}
				} else if (_method == ConnectionType.one_to_one) {
					if (nodes.length != _group.nodes.length) {
						throw('From and To group must be the same size!');
					}

					for (i in 0...nodes.length) {
						var connection = nodes[i].connect(_group.nodes[i], _weight);
						connections.self.push(connection[0]);
						_connections.push(connection[0]);
					}
				}
			}
			case ObjectsType.layer:{
				var _layer:Layer = cast _target;
				_connections = _layer.input(this, _method, _weight);
			}
			case ObjectsType.node:{
				var _node:Node = cast _target;
				for (i in 0...nodes.length) {
					var connection = nodes[i].connect(_node, _weight);
					connections.output.push(connection[0]);
					_connections.push(connection[0]);
				}
			}
		}

		return _connections;

	}

	public function gate(_connections:Array<Connection>, ?_method:GatingType):Void { // todo: optimise this

		if (_method == null) {
			throw('Please specify GatingType.input, GatingType.output');
		}

		var nodes1:Array<Node> = [];
		var nodes2:Array<Node> = [];

		for (i in 0..._connections.length) {
			var connection = _connections[i];
			if (nodes.indexOf(connection.from) == -1) {
				nodes1.push(connection.from);
			}

			if (nodes.indexOf(connection.to) == -1) {
				nodes2.push(connection.to);
			}
		}

		switch (_method) {
			case GatingType.input: {
				for (i in 0...nodes2.length) {
					var node = nodes2[i];
					var gater = nodes[i % nodes.length];

					for (j in 0...node.connections.input.length) {
						var conn = node.connections.input[j];
						if (_connections.indexOf(conn) != -1) {
							gater.gate([conn]); // todo: remove array creation
						}
					}
				}
			}
			case GatingType.output: {
				for (i in 0... nodes1.length) {
					var node = nodes1[i];
					var gater = nodes[i % nodes.length];

					for (j in 0...node.connections.output.length) {
						var conn = node.connections.output[j];
						if (_connections.indexOf(conn) != -1) {
							gater.gate([conn]); // todo: remove array creation
						}
					}
				}
			}
			case GatingType.self: {
				for (i in 0...nodes1.length) {
					var node = nodes1[i];
					var gater = nodes[i % this.nodes.length];

					if (_connections.indexOf(node.connections.self) != -1) {
						gater.gate([node.connections.self]); // todo: remove array creation
					}
				}
			}
		}

	}

	/**
	 * Sets the value of a property for every node
	 */
	public function set(?_bias:Float, ?_squash:IActivator, ?_type:NodeType):Void {

		for (n in nodes) {
			n.set(_bias, _squash, _type);
		}

	}

	override function disconnect(_target:Objects, _twosided:Bool = false):Void {
		
		if(_target.is(ObjectsType.group)) {
			var _group:Group = cast _target;
			for (i in 0...nodes.length) {
				for (j in 0..._group.nodes.length) {
					nodes[i].disconnect(_group.nodes[j], _twosided);

					var k:Int = connections.output.length - 1;
					while(k >= 0) {
						var conn = this.connections.output[k];
						if (conn.from == nodes[i] && conn.to == _group.nodes[j]) {
							connections.output.splice(k, 1);
							break;
						}
						k--;
					}

					if (_twosided) {
						k = connections.input.length - 1;
						while(k >= 0) {
							var conn = connections.input[k];
							if (conn.from == _group.nodes[j] && conn.to == nodes[i]) {
								connections.input.splice(k, 1);
								break;
							}
							k--;
						}
					}
				}
			}
		} else if(_target.is(ObjectsType.node)) {
			var _node:Node = cast _target;
			for (i in 0...nodes.length) {
				nodes[i].disconnect(_node, _twosided);

				var j:Int = connections.output.length - 1;
				while(j >= 0) {
					var conn = connections.output[j];
					if (conn.from == nodes[i] && conn.to == _node) {
						connections.output.splice(j, 1);
						break;
					}
					j--;
				}

				if (_twosided) {
					j = connections.output.length - 1;
					while(j >= 0) {
						var conn = connections.input[j];

						if (conn.from == _node && conn.to == nodes[i]) {
							connections.input.splice(j, 1);
							break;
						}
						j--;
					}
				}
			}
		}

	}

	/**
	 * Clear the context of this group
	 */
	override function clear():Void {
		
		for (n in nodes) {
			n.clear();
		}

	}

}


class GroupConnections {


	public var input:Array<Connection>;
	public var output:Array<Connection>;
	public var self:Array<Connection>;


	public function new(_input:Array<Connection>, _output:Array<Connection>, _self:Array<Connection>) {

		input = _input;
		output = _output;
		self = _self;

	}


}