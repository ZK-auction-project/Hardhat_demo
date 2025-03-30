import { proof_range } from "./scripts/generate_proof_range.mjs"
import { proof_compare } from "./scripts/generate_proof_compare.mjs"
import crypto from 'crypto';
import dotenv from 'dotenv';
import { createInterface } from 'readline';
import { ethers } from 'ethers';
import AuctionArtifact from './artifacts/contracts/Auction.sol/Auction.json' with { type: 'json' };
import VerifierRangeArtifact from './artifacts/contracts/Verifier.sol/VerifierRange.json' with { type: 'json' };
import VerifierCompareArtifact from './artifacts/contracts/Verifier.sol/VerifierCompare.json' with { type: 'json' };
import { fileURLToPath } from 'url';
import path from "path";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const envPath = path.join(__dirname, 'contractInfo.env');
dotenv.config({path : envPath});
const AUCTION_CONTRACT_ADDRESS = process.env.AUCTION_CONTRACT_ADDRESS;
const HARDHAT_NODE_URL = 'http://127.0.0.1:8545';

console.log("Starting readlineCLI.js...");

let currentSignerIndex = 0;

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

function base64ToArrayBuffer(base64) {
    var binaryString = atob(base64);
    var bytes = new Uint8Array(binaryString.length);
    for (var i = 0; i < binaryString.length; i++) {
        bytes[i] = binaryString.charCodeAt(i);
    }
    return bytes.buffer;
}

const hexToByte = (input) => {
    const hex = input.toString('hex').padStart(128, '0')
    const key = '0123456789abcdef'
    let newBytes = []
    let currentChar = 0
    let currentByte = 0
    for (let i = 0; i < hex.length; i++) {   // Go over two 4-bit hex chars to convert into one 8-bit byte
        currentChar = key.indexOf(hex[i])
        if (i % 2 === 0) { // First hex char
            currentByte = (currentChar << 4) // Get 4-bits from first hex char
        }
        if (i % 2 === 1) { // Second hex char
            currentByte += (currentChar)     // Concat 4-bits from second hex char
            newBytes.push(currentByte)       // Add byte
        }
    }
    return new Uint8Array(newBytes)
}

const makeHash = (input) => {
    const byte = hexToByte(input);
    const hash = crypto.createHash('sha256').update(byte).digest('hex');
    const part1 = BigInt("0x" + hash.slice(0, 32)).toString();  
    const part2 = BigInt("0x" + hash.slice(32)).toString();
    const result = new Array(part1, part2);
    return result;
}

const readline = createInterface({
    input: process.stdin,
    output: process.stdout,
});

async function getContract(contractName, contractAddress) {
    const provider = new ethers.JsonRpcProvider(HARDHAT_NODE_URL);

    let artifact;
    if (contractName === 'Auction') {
        artifact = AuctionArtifact;
    } else if (contractName === 'VerifierRange') {
        artifact = VerifierRangeArtifact;
    } else if (contractName === 'VerifierCompare') {
        artifact = VerifierCompareArtifact;
    } else {
        throw new Error(`Unknown contract name: ${contractName}`);
    }
    const signer = await provider.getSigner(currentSignerIndex)
    // console.log(signer)
    return new ethers.Contract(contractAddress, artifact.abi, signer);
}

async function startAuctionCLI() {
    readline.question('ป้อนราคาเริ่มต้นขั้นต่ำ: ', async (minBid) => {
        try {
            const auctionContract = await getContract('Auction', AUCTION_CONTRACT_ADDRESS);
            const tx = await auctionContract.startAuction(publicKey, ethers.parseUnits(minBid, 0));
            
            console.log("Address ผู้เปิดประมูล:", tx.from);
            console.log('กำลังเริ่มการประมูล...');
            await tx.wait();
            console.log('เริ่มการประมูลเรียบร้อยแล้ว');
            console.log('Transaction Hash:', tx.hash);
            mainMenu();
        } catch (error) {
            console.error('เกิดข้อผิดพลาดในการเริ่มการประมูล:', error);
            mainMenu();
        }
    });

}

async function bidCLI() {
    readline.question('ป้อนราคา Bid ที่ต้องการ: ', async (bid) => {
        try {
            const auctionContract = await getContract('Auction', AUCTION_CONTRACT_ADDRESS);
            const encryptBid = crypto.publicEncrypt(publicKey, Buffer.from(bid)).toString('base64');
            const hashBid = makeHash(bid);
            const minBid = await auctionContract.min_bid();
            var proof;
            await proof_range(bid , minBid.toString()).then(range => {
                console.log("🔍 Proof Generated:", range);
                proof = range;
            });
            const proofFormatted = proof.proof;
            const inputFormatted = proof.inputs;
            const tx = await auctionContract.bidding(encryptBid, hashBid, proofFormatted, inputFormatted);
            console.log('กำลังส่ง Bid...');
            await tx.wait();
            console.log('ส่ง Bid เรียบร้อยแล้ว');
            console.log('Transaction Hash:', tx.hash);
            console.log("Address ผู้ส่ง Bid:", tx.from);
            mainMenu();
        } catch (error) {
            console.error('เกิดข้อผิดพลาดในการส่ง Bid:', error);
            mainMenu();
        };
    });
}

async function changeSigner(){
    return new Promise((resolve)=>{
        readline.question('ป้อนเลขกระเป๋าของคุณ: ', async (signerIndexInput) =>{
            console.log("เปลี่ยนกระเป๋าเเล้ว");
            const signerInt = parseInt(signerIndexInput)
            currentSignerIndex = signerInt;
            const provider = new ethers.JsonRpcProvider(HARDHAT_NODE_URL);
            const signer = await provider.getSigner(currentSignerIndex)
            console.log("เลขกระเป๋าปัจจุบัน:", signer.address)
        resolve();
        })
    })
}

async function endAuctionCLI() {
    try {
        const auctionContract = await getContract('Auction', AUCTION_CONTRACT_ADDRESS);

        const bidder1 = await auctionContract.bidders(0);
        var bids = await auctionContract.bids(bidder1);
        const enc_bid1 = bids.encrypt_bid;
        const hash_bid1 = [bids.hash_bid1.toString(), bids.hash_bid2.toString()];
        var buffer = base64ToArrayBuffer(enc_bid1)
        const dec_bid1 = crypto.privateDecrypt(privateKey, buffer).toString();

        const bidder2 = await auctionContract.bidders(1);
        var bids = await auctionContract.bids(bidder2);
        const enc_bid2 = bids.encrypt_bid;
        const hash_bid2 = [bids.hash_bid1.toString(), bids.hash_bid2.toString()];
        var buffer = base64ToArrayBuffer(enc_bid2)
        const dec_bid2 = crypto.privateDecrypt(privateKey, buffer).toString();

        const bidder3 = await auctionContract.bidders(2);
        var bids = await auctionContract.bids(bidder3);
        const enc_bid3 = bids.encrypt_bid;
        const hash_bid3 = [bids.hash_bid1.toString(), bids.hash_bid2.toString()];
        var buffer = base64ToArrayBuffer(enc_bid3)
        const dec_bid3 = crypto.privateDecrypt(privateKey, buffer).toString();

        console.log("Address ผู้เข้าร่วมคนที่ 1:", bidder1);
        console.log("Address ผู้เข้าร่วมคนที่ 2:", bidder2);
        console.log("Address ผู้เข้าร่วมคนที่ 3:", bidder3);

        var proof;
        await proof_compare(dec_bid1, dec_bid2, dec_bid3, hash_bid1, hash_bid2, hash_bid3).then(compare => {
            console.log("🔍 Proof Generated:", compare);
            proof = compare;
        });

        const proofFormatted = proof.proof;
        const inputFormatted = proof.inputs;

        const tx = await auctionContract.endAuction(proofFormatted, inputFormatted);
        console.log('กำลังสิ้นสุดการประมูล...');
        await tx.wait();
        console.log('สิ้นสุดการประมูลเรียบร้อยแล้ว');
        console.log('Transaction Hash:', tx.hash);

        const highestBid = await auctionContract.highestBid();
        const winner = await auctionContract.winner();
        // const highestHash = await auctionContract.highestHash();

        console.log('ผู้ชนะการประมูล:', winner);
        console.log('ราคาประมูลสูงสุด:', ethers.formatUnits(highestBid, 0));
        // console.log('Hash ของ Bid สูงสุด:', highestHash);
        mainMenu();
    } catch (error) {
        console.error('เกิดข้อผิดพลาดในการสิ้นสุดการประมูล:', error);
        mainMenu();
    }
}

function mainMenu() {
    console.log('\n===== เมนูหลัก =====');
    console.log('1. เริ่มการประมูล');
    console.log('2. ส่ง Bid');
    console.log('3. เปลี่ยนกระเป๋า')
    console.log('4. สิ้นสุดการประมูล');
    console.log('0. ออก');
    readline.question('เลือกคำสั่ง: ', async (choice) => {
        switch (choice) {
            case '1':
                startAuctionCLI();
                break;
            case '2':
                bidCLI();
                break;
            case '3':
                await changeSigner();
                mainMenu();
                break;
            case '4':
                endAuctionCLI();
                break;
            case '0':
                console.log('กำลังออกจากโปรแกรม...');
                readline.close();
                break;
            default:
                console.log('คำสั่งไม่ถูกต้อง');
                mainMenu();
        }
    });
}

console.log('ยินดีต้อนรับสู่ CLI จำลองระบบประมูล');
mainMenu();