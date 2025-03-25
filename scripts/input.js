import { proof_range } from "C:\Users\Mon\Desktop\Hardhat_demo\scripts\generate_proof_range.mjs";
const crypto = require('crypto');
var prompt = require('prompt-sync')();

const { publicKey, privateKey } = crypto.generateKeyPairSync('rsa', {
    modulusLength: 512,
    publicKeyEncoding: {
        type: 'spki',
        format: 'pem'
    },
    privateKeyEncoding: {
        type: 'pkcs8',
        format: 'pem'
    }
});

console.log('Public Key:', publicKey);
console.log('Private Key:', privateKey);

//start auction

//bidder1
const bidder1 = prompt('bid_1 : ');

const range = proof_range(2,0)

//bidder2
const bidder2 = prompt('bid_2 : ');

//bidder3
const bidder3 = prompt('bid_3 : ');

//end auction


