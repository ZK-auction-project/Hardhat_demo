import { proof_range } from "./scripts/generate_proof_range.mjs"
import { proof_compare } from "./scripts/generate_proof_compare.mjs"
import crypto from 'crypto';
import dotenv from 'dotenv';
import { createInterface } from 'readline';
import { ethers } from 'ethers';
import AuctionArtifact from './artifacts/contracts/Auction.sol/Auction.json' with { type: 'json' };
import VerifierRangeArtifact from './artifacts/contracts/Verifier.sol/VerifierRange.json' with { type: 'json' };
import VerifierCompareArtifact from './artifacts/contracts/Verifier.sol/VerifierCompare.json' with { type: 'json' };

dotenv.config();

console.log("Starting readlineCLI.js...");

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

const AUCTION_CONTRACT_ADDRESS = process.env.AUCTION_CONTRACT_ADDRESS;
const VERIFIER_RANGE_CONTRACT_ADDRESS = process.env.VERIFIER_RANGE_CONTRACT_ADDRESS;
const VERIFIER_COMPARE_CONTRACT_ADDRESS = process.env.VERIFIER_COMPARE_CONTRACT_ADDRESS;
const HARDHAT_NODE_URL = 'http://127.0.0.1:8545';

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
    const signer = await provider.getSigner();
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
            // const m = await auctionContract.min_bid();
            // console.log(m);
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
            const encryptBid = crypto.publicEncrypt(publicKey, Buffer.from(bid)).toString('base64');
            const hashBid = makeHash(bid);
            var proof;
            await proof_range(bid, "0").then(range => {
                proof = range;
            });
            // const proofFormatted = {a: {X:proof.proof.a[0], Y:proof.proof.a[1]}, b: {X:proof.proof.b[0], Y:proof.proof.b[1]}, c: {X:proof.proof.c[0], Y:proof.proof.c[1]}};
            // 
            const proofFormatted = [proof.proof.a, proof.proof.b, proof.proof.c]
            const inputFormatted = proof.inputs;
            const auctionContract = await getContract('Auction', AUCTION_CONTRACT_ADDRESS);
            console.log(proofFormatted, inputFormatted);
            const tx = await auctionContract.bidding(encryptBid, hashBid, proofFormatted, inputFormatted);
            console.log('กำลังส่ง Bid...');
            await tx.wait();
            console.log('ส่ง Bid เรียบร้อยแล้ว');
            console.log('Transaction Hash:', tx.hash);
            mainMenu();
        } catch (error) {
            console.error('เกิดข้อผิดพลาดในการส่ง Bid:', error);
            mainMenu();
        };
    });
}

async function endAuctionCLI() {
    try {
        const auctionContract = await getContract('Auction', AUCTION_CONTRACT_ADDRESS);

        const tx = await auctionContract.endAuction(proofFormatted, inputFormatted);
        console.log('กำลังสิ้นสุดการประมูล...');
        await tx.wait();
        console.log('สิ้นสุดการประมูลเรียบร้อยแล้ว');
        console.log('Transaction Hash:', tx.hash);

        const highestBid = await auctionContract.highestBid();
        const winner = await auctionContract.winner();
        const highestHash = await auctionContract.highestHash();

        console.log('ผู้ชนะการประมูล:', winner);
        console.log('ราคาประมูลสูงสุด:', ethers.formatUnits(highestBid, 0));
        console.log('Hash ของ Bid สูงสุด:', highestHash);
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
    console.log('3. สิ้นสุดการประมูล');
    console.log('0. ออก');
    readline.question('เลือกคำสั่ง: ', (choice) => {
        switch (choice) {
            case '1':
                startAuctionCLI();
                break;
            case '2':
                bidCLI();
                break;
            case '3':
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