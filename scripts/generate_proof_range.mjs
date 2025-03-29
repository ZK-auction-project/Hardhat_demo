import { initialize } from 'zokrates-js';
import chalk from "chalk"
import fs from "fs"
import path from "path"
import fse from 'fs-extra'
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';

export async function proof_range(input_1, input_2) {
    const zokratesProvider = await initialize();

    let rawdata = fs.readFileSync('./zokrates/range.zok');

    const source = rawdata.toString();

    const artifacts = zokratesProvider.compile(source);

    const { witness, output } = zokratesProvider.computeWitness(artifacts, [input_1, input_2]);

    
    // const keypair = zokratesProvider.setup(artifacts.program);

    // //เขียนไฟล์ลง env
    const __filename = fileURLToPath(import.meta.url);
    const __dirname = path.dirname(__filename);
    const envPath = path.join(__dirname, '..', 'provingKey.env');
    // const envContent = `PROVING_KEY="${keypair.pk}"`
    dotenv.config({path : envPath})
    // fs.writeFileSync(envPath, envContent);

    //ดึง Proovingkey จาก env
    const provingKeyRaw = process.env.PROVING_KEY;
    const provingKeySplit = provingKeyRaw.split(',')
    const provingKeyInt = provingKeySplit.map(s => parseInt(s.trim()))
    const provingKeyUint8Array = new Uint8Array(provingKeyInt)
    const proof = zokratesProvider.generateProof(artifacts.program, witness, provingKeyUint8Array);


    fse.outputFile("./proofs/proof_range.json", JSON.stringify(proof));
    console.log(chalk.green("\nProofs generated successfully"));

    // const isVerified = zokratesProvider.verify(keypair.vk, proof);
    // console.log(chalk.green("เป็นควยไร"));
    // const result = await [proof.proof.a, proof.proof.b, proof.proof.c, proof.inputs];
    

    // const verifier = zokratesProvider.exportSolidityVerifier(keypair.vk, "v1");
    // fse.outputFile("./contracts/verifier_range.sol", verifier);
    // console.log(chalk.green("\nContracts generated successfully"));
    return proof;
}
