/* global artifacts, web3, contract */
require('chai').use(require('bn-chai')(web3.utils.BN)).use(require('chai-as-promised')).should()
const ENSNFT = artifacts.require('EmojiNFT')
const Verifier = artifacts.require('EthmojiVerifier')
const StorageContract = artifacts.require('Storage')
const { writeFileSync, readFileSync } = require('fs')

let verifier, nft, storage;

const unlockAccount = async (address) => {
    let provider = web3.currentProvider;
    return new Promise((res, rej) => {
        provider.send({
            method: 'evm_addAccount',
            params: [address, ""]
        }, (d) => {
            provider.send({
                method: 'personal_unlockAccount',
                params: [address, ""]
            }, (d) => {
                res(d);
            });
        });
    });
}

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
                '🐶🐶🐶.eth',
                //'🐶🐶🏴‍☠🐶🐶.eth', // reverts, nobody owns it so ownerOf fails
                '😊😊😊.eth',
                '🇦🇺🇦🇺.eth',
                // not pure
                '🐶🐶🐶🐶.eth',
            ]; // normalized

            const user = accounts[0];

            for (let d in domains) {
                const domain = domains[d];
                const fee = await nft.getFee(domain);
                const label = await nft.test(domain, "0x0000000000000000000000000000000000000000");
                const owner = await nft.findOwner(label.tokenId);
                await unlockAccount(owner);
                console.log(`---\nToken: ${label.tokenId}\nOwner: ${owner}`);
                const { logs, receipt } = await nft.mint(domain, { value: fee, from: owner });
                let thisToken = await nft.tokenURI(label.tokenId);
                console.log(`NFT: ${thisToken}`);
                let token = Buffer.from(thisToken.substring(29), "base64").toString();
                writeFileSync(`./nft/${label.tokenId}.svg`, JSON.parse(token).image_data);
            }
        })

        it('should fail', async () => {

            const invalidDomains = [
                // invalid
                'text.eth',
                'dog🐶.eth',
                //'😊.eth', // too short but valid, won't fail without owner check
            ];

            const user = accounts[0];

            for (let d in invalidDomains) {
                const domain = invalidDomains[d];
                await nft.test(domain, user).should.be.rejected;
            }

        });
    })

})