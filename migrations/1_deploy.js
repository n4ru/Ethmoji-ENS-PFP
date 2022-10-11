const ENSNFT = artifacts.require("EmojiNFT");
const Verifier = artifacts.require("EthmojiVerifier");
const StorageContract = artifacts.require("Storage");
const fluidb = require('fluidb');
const config = new fluidb();
const output = new fluidb('contracts');
const { readFileSync } = require('fs');

module.exports = (deployer) => {
  return deployer.then(async () => {

    // Deploy the contracts
    let storage = await deployer.deploy(StorageContract);
    let verifier = await deployer.deploy(Verifier);
    let nft = await deployer.deploy(
      ENSNFT,
      config.nftAddress,
      verifier.address,
      storage.address,
      config.fee,
      config.purefee,
      config.keycapsfee
    );

    // Save the addresses to the config
    output.contracts = [];
    output.contracts.push(storage.address, verifier.address, nft.address);

    // Deploy the payload to our validator
    await verifier.uploadEmoji(readFileSync('./deps/payload/payload-20221004.txt').toString());

    // Link the contracts
    await storage.add(nft.address);

    // List of payees
    const payees = [
      //["0x9c8b7ac505c9f0161bbbd04437fce8c630a0886e1ffea00078e298f063a8a5df", "20"] // raffy.eth, 20%
      ["0x38edc54b35720e509edf445f552cb7db177e2d3b4d97ed6cd6b00a08f7aa196e", "100"] // 😇😇😇.eth, 100% for testing
    ];

    for (let payee in payees) {
      await nft.addPayee(payees[payee][0]); // Add payees to the contract
      await nft.updateShare(payees[payee][0], payees[payee][1]); // Update the share of each payee
    }

    console.log(`Done.`);
  })

};