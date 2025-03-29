import { proof_range } from "./generate_proof_range.mjs";
import { proof_compare } from "./generate_proof_compare.mjs";
import crypto from 'crypto';
import promptSync from 'prompt-sync';
const prompt = promptSync();
// import data from '../proofs/proving_key.json' with { type: 'json' };
// proof_range("3", "0").then(range => {
//     // const kuy =  range.slice(0,3)
//     // console.log(kuy);
//     // console.log(range.slice(3)[0])
//     console.log(range)
// });
// // const compare = proof_compare("5", "6", "7", ["263561599766550617289250058199814760685", "65303172752238645975888084098459749904"], ["296016139321527823785053958024045515449", "169585634993304848991863197817116667302"], ["62133134181886812829768166950054220896", "160635334427203623512968684759912538624"])

function base64ToArrayBuffer(base64) {
    var binaryString = atob(base64);
    var bytes = new Uint8Array(binaryString.length);
    for (var i = 0; i < binaryString.length; i++) {
        bytes[i] = binaryString.charCodeAt(i);
    }
    return bytes.buffer;
}

// // const compare = proof_compare("5", "6", "7", ["263561599766550617289250058199814760685", "65303172752238645975888084098459749904"], ["296016139321527823785053958024045515449", "169585634993304848991863197817116667302"], ["62133134181886812829768166950054220896", "160635334427203623512968684759912538624"])


// // const compare = proof_compare("5", "6", "7", ["263561599766550617289250058199814760685", "65303172752238645975888084098459749904"], ["296016139321527823785053958024045515449", "169585634993304848991863197817116667302"], ["62133134181886812829768166950054220896", "160635334427203623512968684759912538624"])


const hexToByte = (hex) => {
    const key = '0123456789abcdef'
    let newBytes = []
    let currentChar = 0
    let currentByte = 0
    for (let i=0; i<hex.length; i++) {   // Go over two 4-bit hex chars to convert into one 8-bit byte
      currentChar = key.indexOf(hex[i])
      if (i%2===0) { // First hex char
        currentByte = (currentChar << 4) // Get 4-bits from first hex char
      }
      if (i%2===1) { // Second hex char
        currentByte += (currentChar)     // Concat 4-bits from second hex char
        newBytes.push(currentByte)       // Add byte
      }
    }
    return new Uint8Array(newBytes)
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

// console.log('Public Key:', publicKey);
// console.log('Private Key:', privateKey);

// //start auction

// //bidder1
const bidder1 = prompt('bid_1 : ');

// // const compare = proof_compare("5", "6", "7", ["263561599766550617289250058199814760685", "65303172752238645975888084098459749904"], ["296016139321527823785053958024045515449", "169585634993304848991863197817116667302"], ["62133134181886812829768166950054220896", "160635334427203623512968684759912538624"])
// // //bidder1
// // const bidder1 = prompt('bid_1 : ');
const enc_bid1 = crypto.publicEncrypt(publicKey, Buffer.from(bidder1)).toString('base64');
console.log(enc_bid1)

// // //bidder2
const bidder2 = prompt('bid_2 : ');
const enc_bid2 = crypto.publicEncrypt(publicKey, Buffer.from(bidder2)).toString('base64');
console.log(enc_bid2)

// // //bidder3
const bidder3 = prompt('bid_3 : ');
const enc_bid3 = crypto.publicEncrypt(publicKey, Buffer.from(bidder3)).toString('base64');
console.log(enc_bid3)

// //end auction
// var bbb = bidder1.toString('hex').padStart(128, '0');
// console.log(bbb);
// const bidderhash1 = crypto.createHash('sha256').update(hexToByte(bbb)).digest('hex');
// const bidderhash2 = crypto.createHash('sha256').update(bidder2.padStart(128, '0')).digest('hex');
// const bidderhash3 = crypto.createHash('sha256').update(bidder3.padStart(128, '0')).digest('hex');

// console.log("Bidder 1 Hash:", bidderhash1);
// console.log("Bidder 2 Hash:", bidderhash2);
// console.log("Bidder 3 Hash:", bidderhash3);

// function hashHex(digest) {
//     const part1 = BigInt("0x" + digest.slice(0, 32));  
//     const part2 = BigInt("0x" + digest.slice(32));     

//     console.log(part1, part2);
// }

// hashHex(bidderhash1);
// // var p1, p2 = hashHex(bidderhash1);
// // console.log(p1,p2);


// console.log(hexToByte(bbb))
// var buffer = base64ToArrayBuffer(enc_bid1)
// const dec_bid1 = crypto.privateDecrypt(privateKey, buffer).toString();
// console.log(dec_bid1)

// var buffer = base64ToArrayBuffer(enc_bid2)
// const dec_bid2 = crypto.privateDecrypt(privateKey, buffer).toString();
// console.log(dec_bid2)

// var buffer = base64ToArrayBuffer(enc_bid3)
// const dec_bid3 = crypto.privateDecrypt(privateKey, buffer).toString();
// console.log(dec_bid3)
