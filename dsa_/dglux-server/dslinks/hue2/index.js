var DS = require('dslink'),
	hue = require("node-hue-api"),
	HueApi = hue.HueApi,
	lightState = hue.lightState,
	provider = new DS.NodeProvider(),
	linkName = 'hue-dslink',
	bridge, api;

var setupLights = function (result) {
	var lights = result.lights;
	for (var light in lights) {
		try {
			provider.getNode('/lights/' + light + '/on').value = lights[light].state.on;
			provider.getNode('/lights/' + light + '/brightness').value = Math.round((lights[light].state.bri / 255) * 100);
			provider.getNode('/lights/' + light + '/hue').value = lights[light].state.hue;
			provider.getNode('/lights/' + light + '/saturation').value = Math.round((lights[light].state.sat / 255) * 100);
		} catch (error) {
			provider.addNode('/lights/' + light).load({
				setState: {
					'$is': 'setState',
					'$invokable': 'read',
					'$params': { on: { type: 'bool' }, brightness: { type: 'number' }, hue: { type: 'number' }, saturation: { type: 'number' } }
				},
				on: {
					'$type': 'bool',
					'?value': lights[light].state.on
				},
				brightness: {
					'$type': 'number',
					'?value': Math.round((lights[light].state.bri / 255) * 100)
				},
				hue: {
					'$type': 'number',
					'?value': lights[light].state.hue
				},
				saturation: {
					'$type': 'number',
					'?value': Math.round((lights[light].state.sat / 255) * 100)
				}
			});
		}
	}
};



var setState = DS.Node.createNode({
	onInvoke: function (params) {
		var state;
		state = (params.on) ? lightState.create().on() : lightState.create().off();
		if (params.brightness) state.brightness(params.brightness)
		if (params.saturation) state.saturation(params.saturation)
		if (params.hue) state.hue(params.hue);
		api.setLightState(this.parent.name, state, function (err, lights) {
			console.log("STATE SET");
		});
		
	}
});

provider.is('setState', setState);

provider.load({
	defs:{
		profile:{
			setState: {}
		}
	},
	lights: {}
});

(new DS.Link(linkName, provider)).connect();

var displayBridges = function(bridge) {
	bridge = bridge[0];
	api = new HueApi(bridge.ipaddress, 'newdeveloper');

	api.getFullState().then(setupLights).done();
};

hue.nupnpSearch().then(displayBridges).done();

setInterval(function () {

	if (api) api.getFullState().then(setupLights).done();

}, 2000);
