package neataptic;


import neataptic.methods.ConnectionType;
import neataptic.ObjectsType;
import neataptic.Objects;


class Objects {

	public var _type_(default, null):ObjectsType;

	public function new(_type:ObjectsType) {
		
		_type_ = _type;

	}

	public function connect(_target:Objects, ?_method:ConnectionType, ?_weight:Float):Array<Connection> {

		return null;

	}

	public function disconnect(obj:Objects, twosided:Bool = false) {

	}

	public function clear() {

	}

	public inline function is(_type:ObjectsType):Bool {
		
		return _type_ == _type;

	}
	
}