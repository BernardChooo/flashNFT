const singleFlashNFT = artifacts.require('./singleFlashNFT.sol');

var Web3 = require('web3');

module.exports = async function(deployer, network, accounts) {
	try {
		let lendingPoolAddressesProviderAddress;

		switch (network) {
			case 'mainnet':
			case 'mainnet-fork':
			case 'development': // For Ganache mainnet forks
				lendingPoolAddressesProviderAddress = '0x24a42fD28C976A61Df5D00D0599C34c4f90748c8';
				break;
			case 'ropsten':
				lendingPoolAddressesProviderAddress = '0x1c8756FD2B28e9426CDBDcC7E3c4d64fa9A54728';
				break;
			case 'ropsten-fork':
				lendingPoolAddressesProviderAddress = '0x1c8756FD2B28e9426CDBDcC7E3c4d64fa9A54728';
				break;
			case 'kovan':
			case 'kovan-fork':
				lendingPoolAddressesProviderAddress = '0x506B0B2CF20FAA8f38a4E2B524EE43e1f4458Cc5';
				break;
			default:
				throw Error(`Are you deploying to the correct network? (network selected: ${network})`);
		}

		if (network == 'ropsten') {
			// Change the LeaseNFT_instance.address
			await deployer.deploy(singleFlashNFT, lendingPoolAddressesProviderAddress, LeaseNFT_instance.address, 0, {
				value: Web3.utils.toWei('0.1', 'ether'),
				from: accounts[0]
			});
		} else {
			// Perform a different step otherwise.
		}
	} catch (e) {
		console.log(`Error in migration: ${e.message}`);
	}
};
