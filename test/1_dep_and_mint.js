/* global artifacts, web3, contract */
require('chai').use(require('bn-chai')(web3.utils.BN)).use(require('chai-as-promised')).should()
const ENSNFT = artifacts.require('EmojiNFT')
const Verifier = artifacts.require('EthmojiVerifier')
const StorageContract = artifacts.require('Storage')
const { readFileSync } = require('fs')

let verifier, nft, storage;
let pirate = "0x149fD340cA0DF54228aACdAD7755B05d0E2b23d9";

contract('Emoji NFT', (accounts) => {

    before(async () => {
        nft = await ENSNFT.deployed()
        verifier = await Verifier.deployed()
        storage = await StorageContract.deployed()
        // Make sure we're using the right payload
        //await verifier.uploadEmoji(readFileSync('./deps/payload/payload-20221004.txt').toString());
    })

    describe('#mint', () => {
        it('should work', async () => {
            const domains = [
                '🏴‍☠.eth',
                //'🐶🐶🐶.eth',
                //'🐶🐶🏴‍☠🐶🐶.eth',
                //'😊😊😊.eth',
                //'🇦🇺🇦🇺.eth',
                //// not pure
                //'🐶🐶🐶🐶.eth',
            ]; // normalized

            const user = accounts[0];

            for (let d in domains) {
                const domain = domains[d];
                const fee = await nft.getFee(domain);
                const label = await nft.test(domain, user);
                console.log("TokenId: " + label.tokenId);
                const { logs, receipt } = await nft.mint(domain, { value: fee, from: user })
                let thisToken = await nft.tokenURI(label.tokenId);
                console.log(thisToken);
            }
        })

        

        //it('should fail', async () => {
        //
        //    const invalidDomains = [
        //        // invalid
        //        'justtext.eth',
        //        'mi🐶xed.eth',
        //        '😊.eth', // too short
        //    ];
        //
        //    const user = accounts[0];
        //
        //    for (let d in invalidDomains) {
        //        const domain = invalidDomains[d];
        //        const fee = await nft.getFee(domain);
        //        const label = await nft.test(domain, user).should.be.rejected;
        //        console.log("TokenId: " + label.tokenId);
        //        const { logs, receipt } = await nft.mint(domain, { value: fee, from: user }).should.be.rejected;
        //        //let thisToken = await nft.tokenURI(label.tokenId);
        //        //console.log(thisToken);
        //    }
        //
        //});
    })

})