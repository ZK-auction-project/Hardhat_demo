import { initialize } from 'zokrates-js';
import chalk from "chalk"
import fs from "fs"
import path from "path"
import fse from 'fs-extra'

export async function proof_range(input_1, input_2) {
    const zokratesProvider = await initialize();

    let rawdata = fs.readFileSync('./zokrates/range.zok');

    const source = rawdata.toString();

    const artifacts = zokratesProvider.compile(source);

    const { witness, output } = zokratesProvider.computeWitness(artifacts, [input_1, input_2]);

    const keypair = zokratesProvider.setup(artifacts.program);
    fse.outputFile("./proofs/proving.key", keypair.pk.toString());

    const proof = zokratesProvider.generateProof(artifacts.program, witness, keypair.pk);
    fse.outputFile("./proofs/proof_range.json", JSON.stringify(proof));
    console.log(chalk.green("\nProofs generated successfully"));

    const isVerified = zokratesProvider.verify(keypair.vk, proof);
    console.log(chalk.green("เป็นควยไร"));
    // const result = await [proof.proof.a, proof.proof.b, proof.proof.c, proof.inputs];
    

    const verifier = zokratesProvider.exportSolidityVerifier(keypair.vk, "v1");
    fse.outputFile("./contracts/verifier_range.sol", verifier);
    console.log(chalk.green("\nContracts generated successfully"));
    return proof;
}
proof_range("2", "0");

// import { initialize } from 'zokrates-js';
// import chalk from 'chalk';
// import fs from 'fs';
// import path from 'path';
// import fse from 'fs-extra';
// import promptSync from 'prompt-sync';

// const prompt = promptSync();

// export async function proof_range(input_1, input_2) {
//     initialize().then(async (zokratesProvider) => {

//         // Read the ZoKrates program from the file system
//         let rawdata = fs.readFileSync(path.resolve('./zokrates/range.zok'));

//         // Convert the raw data to string format
//         const source = rawdata.toString();

//         // Compile the ZoKrates program
//         const artifacts = zokratesProvider.compile(source);

//         // Compute the witness using input values
//         const { witness, output } = zokratesProvider.computeWitness(artifacts, [input_1, input_2]);

//         // Setup the keypair
//         const keypair = zokratesProvider.setup(artifacts.program);

//         // Generate the proof
//         const proof = zokratesProvider.generateProof(artifacts.program, witness, keypair.pk);

//         // Output the proof to a file
//         await fse.outputFile(path.resolve('./proofs/proof_range.json'), JSON.stringify(proof));

//         // Log the success message
//         console.log(chalk.green('\nProofs generated successfully'));

//         // Uncomment the lines below if you want to generate Solidity contracts
//         // const verifier = zokratesProvider.exportSolidityVerifier(keypair.vk, "v1");
//         // await fse.outputFile(path.resolve('./contracts/verifier_test.sol'), verifier);
//         // console.log(chalk.green('\nContracts generated successfully'));

//     }).catch(err => {
//         console.error(chalk.red("Error initializing ZoKrates:", err));
//     });
// }
