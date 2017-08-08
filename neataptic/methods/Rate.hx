package neataptic.methods;


// https://stackoverflow.com/questions/30033096/what-is-lr-policy-in-caffe/30045244


class Rate {

	public static var FIXED = 
		function() {

			var func = function (base_rate:Float, iteration:Int):Float { return base_rate; };
			return func;

		};

	public static var STEP = 
		function (?gamma:Float, ?stepsize:Int) {

			if(gamma == null) {
				gamma = 0.9;
			}
			
			if(stepsize == null) {
				stepsize = 100;
			}

			var func = function (base_rate:Float, iteration:Int):Float {
				return base_rate * Math.pow(gamma, Math.floor(iteration / stepsize));
			};

			return func;

		};

	public static var EXP = 
		function (?gamma:Float) {

			if(gamma == null) {
				gamma = 0.999;
			}

			var func = function (base_rate:Float, iteration:Int):Float {
				return base_rate * Math.pow(gamma, iteration);
			};

			return func;

		};

	public static var INV = 
		function (?gamma:Float, ?power:Float) {

			if(gamma == null) {
				gamma = 0.9;
			}

			if(power == null) {
				power = 2;
			}

			var func = function (base_rate:Float, iteration:Int):Float {
				return base_rate * Math.pow(1 + gamma * iteration, -power);
			};

			return func;

		};

	
}