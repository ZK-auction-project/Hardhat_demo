import { proof_range } from "file:///C:/Users/Mon/Desktop/Hardhat_demo/scripts/generate_proof_range.mjs";
import { proof_compare } from "file:///C:/Users/Mon/Desktop/Hardhat_demo/scripts/generate_proof_compare.mjs";
import crypto from 'crypto';
import promptSync from 'prompt-sync';
const prompt = promptSync();

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

const range = proof_range("2","0")
const compare = proof_compare("5", "6", "7", ["263561599766550617289250058199814760685", "65303172752238645975888084098459749904"], ["296016139321527823785053958024045515449", "169585634993304848991863197817116667302"], ["62133134181886812829768166950054220896", "160635334427203623512968684759912538624"])

// console.log(proof_range(2, 0));
//bidder2
const bidder2 = prompt('bid_2 : ');

//bidder3
const bidder3 = prompt('bid_3 : ');

//end auction


