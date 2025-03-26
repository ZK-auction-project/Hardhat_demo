import { proof_range } from "./generate_proof_range.mjs";
import { proof_compare } from "./generate_proof_compare.mjs";
import crypto from 'crypto';
import promptSync from 'prompt-sync';
const prompt = promptSync();

proof_range("2", "0").then(range => {
    console.log(range);  // Logs after proof_range resolves
});
// const compare = proof_compare("5", "6", "7", ["263561599766550617289250058199814760685", "65303172752238645975888084098459749904"], ["296016139321527823785053958024045515449", "169585634993304848991863197817116667302"], ["62133134181886812829768166950054220896", "160635334427203623512968684759912538624"])

function base64ToArrayBuffer(base64) {
    var binaryString = atob(base64);
    var bytes = new Uint8Array(binaryString.length);
    for (var i = 0; i < binaryString.length; i++) {
        bytes[i] = binaryString.charCodeAt(i);
    }
    return bytes.buffer;
}

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

// //bidder1
// const bidder1 = prompt('bid_1 : ');
// const enc_bid1 = crypto.publicEncrypt(publicKey, Buffer.from(bidder1)).toString('base64');
// console.log(enc_bid1)

// //bidder2
// const bidder2 = prompt('bid_2 : ');
// const enc_bid2 = crypto.publicEncrypt(publicKey, Buffer.from(bidder2)).toString('base64');
// console.log(enc_bid2)

// //bidder3
// const bidder3 = prompt('bid_3 : ');
// const enc_bid3 = crypto.publicEncrypt(publicKey, Buffer.from(bidder3)).toString('base64');
// console.log(enc_bid3)

// //end auction
// var buffer = base64ToArrayBuffer(enc_bid1)
// const dec_bid1 = crypto.privateDecrypt(privateKey, buffer).toString();
// console.log(dec_bid1)

// var buffer = base64ToArrayBuffer(enc_bid2)
// const dec_bid2 = crypto.privateDecrypt(privateKey, buffer).toString();
// console.log(dec_bid2)

// var buffer = base64ToArrayBuffer(enc_bid3)
// const dec_bid3 = crypto.privateDecrypt(privateKey, buffer).toString();
// console.log(dec_bid3)
