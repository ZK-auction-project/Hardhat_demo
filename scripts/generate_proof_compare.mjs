import { initialize } from 'zokrates-js';
import chalk from "chalk"
import fs from "fs"
import path from "path"
import fse from 'fs-extra'
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';

// export async function proof_compare(bit1, bit2, bit3, hash_bit1, hash_bit2, hash_bit3) {
//     const zokratesProvider = await initialize();

//     let rawdata = fs.readFileSync('./zokrates/compare.zok');

//     const source = rawdata.toString();

//     const artifacts = zokratesProvider.compile(source);

//     const { witness, output } = zokratesProvider.computeWitness(artifacts, [bit1, bit2, bit3, hash_bit1, hash_bit2, hash_bit3]);

//     const keypair = zokratesProvider.setup(artifacts.program);

//     //เขียนไฟล์ลง env
//     const __filename = fileURLToPath(import.meta.url);
//     const __dirname = path.dirname(__filename);
//     const envPath = path.join(__dirname, '..', 'provingKey_compare.bin');
//     const envContent = `PROVING_KEY="${keypair.pk}"`

//     // dotenv.config({ path: envPath })
//     fs.writeFileSync(envPath, provingKey);

//     //ดึง Proovingkey จาก env
//     console.log(process.env.PROVING_KEY)
//     const provingKeyRaw = process.env.PROVING_KEY;
//     const provingKeySplit = provingKeyRaw.split(',')
//     const provingKeyInt = provingKeySplit.map(s => parseInt(s.trim()))
//     const provingKeyUint8Array = new Uint8Array(provingKeyInt)
//     const proof = zokratesProvider.generateProof(artifacts.program, witness, provingKeyUint8Array);

//     // const provingKeyBuffer = fs.readFileSync('provingKey_compare.bin');
//     // const provingKeyUint8Array = new Uint8Array(provingKeyBuffer);

//     // console.log(provingKeyUint8Array)
//     // const chunkSize = 10000; // Write 10,000 elements at a time
//     // const outputPath = "./proofs/proving_key.json";
//     // const writeStream = fse.createWriteStream(outputPath);
    
//     // writeStream.write("["); // Start JSON array
    
//     // for (let i = 0; i < provingKeyUint8Array.length; i += chunkSize) {
//     //     const chunk = provingKeyUint8Array.slice(i, i + chunkSize);
//     //     writeStream.write((i === 0 ? "" : ",") + JSON.stringify(Array.from(chunk))); // Convert to array and write
//     // }
    
//     // writeStream.write("]"); // Close JSON array
//     // writeStream.end();
    
//     // const proof = zokratesProvider.generateProof(artifacts.program, witness, keypair.pk);

//     fse.outputFile("./proofs/proof_compare.json", JSON.stringify(proof));
//     console.log(chalk.green("\nProofs generated successfully"));

    // const verifier = zokratesProvider.exportSolidityVerifier(keypair.vk, "v1");
    // fse.outputFile("./contracts/verifier_compare.sol", verifier);
    // console.log(chalk.green("\nContracts generated successfully"));


// }

export async function proof_compare(bit1, bit2, bit3, hash_bit1, hash_bit2, hash_bit3) {
    const zokratesProvider = await initialize();

    // Load ZoKrates source code
    const __filename = fileURLToPath(import.meta.url);
    const __dirname = path.dirname(__filename);
    const zokFilePath = path.resolve(__dirname, '../zokrates/compare.zok');

    if (!fs.existsSync(zokFilePath)) {
        throw new Error("ZoKrates file not found: " + zokFilePath);
    }

    const source = fs.readFileSync(zokFilePath, 'utf-8');

    // Compile the program
    const artifacts = zokratesProvider.compile(source);

    // Compute witness
    const { witness, output } = zokratesProvider.computeWitness(artifacts, [
        bit1, bit2, bit3, hash_bit1, hash_bit2, hash_bit3
    ]);

    // Setup proving key
    // const keypair = zokratesProvider.setup(artifacts.program);

    // Save proving key as a raw binary file
    const provingKeyPath = path.join(__dirname, '..', 'provingKey_compare.bin');
    // fs.writeFileSync(provingKeyPath, keypair.pk); // Save raw binary data

    // Read proving key from .bin file
    const provingKeyBuffer = fs.readFileSync(provingKeyPath);
    const provingKeyUint8Array = new Uint8Array(provingKeyBuffer);

    // Generate proof
    const proof = zokratesProvider.generateProof(artifacts.program, witness, provingKeyUint8Array);

    // Save proof as JSON
    const proofPath = "./proofs/proof_compare.json";
    fse.outputFileSync(proofPath, JSON.stringify(proof, null, 2));

    console.log(chalk.green("\nProofs generated successfully"));

    return proof;

    // const verifier = zokratesProvider.exportSolidityVerifier(keypair.vk, "v1");
    // fse.outputFile("./contracts/verifier_compare.sol", verifier);
    // console.log(chalk.green("\nContracts generated successfully"));
}

// proof_compare("5", "6", "7", ["263561599766550617289250058199814760685", "65303172752238645975888084098459749904"], ["296016139321527823785053958024045515449", "169585634993304848991863197817116667302"], ["62133134181886812829768166950054220896", "160635334427203623512968684759912538624"])