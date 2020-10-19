const AWS = require("aws-sdk");
const ssm = new AWS.SSM();

const cacheSsmGetParameter = (params, cacheTime) => {
	let lastRefreshed = undefined;
	let lastResult = undefined;
	let queue = Promise.resolve();
	return () => {
		const res = queue.then(async () => {
			const currentTime = new Date().getTime();
			if (lastResult === undefined || lastRefreshed + cacheTime < currentTime) {
				lastResult = await ssm.getParameter(params).promise();
				lastRefreshed = currentTime;
			}
			return lastResult;
		});
		queue = res.catch(() => {});
		return res;
	};
};

const getParam = cacheSsmGetParameter({Name: process.env.PARAMETER, WithDecryption: true}, 15 * 1000);

module.exports.handler = async (event) => {
	const param = await getParam();
	return param;
};
