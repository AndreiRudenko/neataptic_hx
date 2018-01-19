package neataptic.methods;


// https://en.wikipedia.org/wiki/Activation_function
// https://stats.stackexchange.com/questions/115258/comprehensive-list-of-activation-functions-in-neural-networks-with-pros-cons


typedef CostFunc = Array<Float>->Array<Float>->Float;


class Cost {

	public static var CROSS_ENTROPY: CostFunc = 
		function(target:Array<Float>, output:Array<Float>):Float {
			var error:Float = 0;
			for (i in 0...output.length) {
				// Avoid negative and zero numbers, use 1e-15 http://bit.ly/2p5W29A
				error -= target[i] * Math.log(Math.max(output[i], 1e-15)) + (1 - target[i]) * Math.log(1 - Math.max(output[i], 1e-15));
			}
			return error / output.length;
		};

	public static var MSE: CostFunc = 
		function(target:Array<Float>, output:Array<Float>):Float {
			var error:Float = 0;
			for (i in 0...output.length) {
				error += Math.pow(target[i] - output[i], 2);
			}

			return error / output.length;
		};

	public static var BINARY: CostFunc = 
		function(target:Array<Float>, output:Array<Float>):Float {
			var misses:Float = 0;
			for (i in 0...output.length) {
				if(Math.round(target[i] * 2) != Math.round(output[i] * 2)) {
					misses++;
				}
			}

			return misses;
		};

	public static var MAE: CostFunc = 
		function(target:Array<Float>, output:Array<Float>):Float {
			var error:Float = 0;
			for (i in 0...output.length) {
				error += Math.abs(target[i] - output[i]);
			}

			return error / output.length;
		};

	public static var MAPE: CostFunc = 
		function(target:Array<Float>, output:Array<Float>):Float {
			var error:Float = 0;
			for (i in 0...output.length) {
				error += Math.abs((output[i] - target[i]) / Math.max(target[i], 1e-15));
			}

			return error / output.length;
		};

	public static var MSLE: CostFunc = 
		function(target:Array<Float>, output:Array<Float>):Float {
			var error:Float = 0;
			for (i in 0...output.length) {
				error += Math.log(Math.max(target[i], 1e-15)) - Math.log(Math.max(output[i], 1e-15));
			}

			return error;
		};

	public static var HINGE: CostFunc = 
		function(target:Array<Float>, output:Array<Float>):Float {
			var error:Float = 0;
			for (i in 0...output.length) {
				error += Math.max(0, 1 - target[i] * output[i]);
			}

			return error;
		};

	
}