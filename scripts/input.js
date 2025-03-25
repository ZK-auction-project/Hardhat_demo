const crypto = require('crypto');
var prompt = require('prompt-sync')();

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

//bidder1
const bidder1 = prompt('bid_1 : ');
const enc_bid1 = crypto.publicEncrypt(publicKey, Buffer.from(bidder1)).toString('base64');
console.log(enc_bid1)

//bidder2
const bidder2 = prompt('bid_2 : ');
const enc_bid2 = crypto.publicEncrypt(publicKey, Buffer.from(bidder1)).toString('base64');
console.log(enc_bid2)

//bidder3
const bidder3 = prompt('bid_3 : ');
const enc_bid3 = crypto.publicEncrypt(publicKey, Buffer.from(bidder1)).toString('base64');
console.log(enc_bid3)

//end auction
const winner = base64ToArrayBuffer(enc_bid1)
const dec_bid1 = crypto.privateDecrypt(privateKey, winner).toString();
console.log(dec_bid1)
