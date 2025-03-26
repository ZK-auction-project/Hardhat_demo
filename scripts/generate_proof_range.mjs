import { initialize } from 'zokrates-js';
import chalk from "chalk"
import fs from "fs"
import path from "path"
import fse from 'fs-extra'

export async function proof_range(input_1, input_2) {
    initialize().then(async (zokratesProvider) => {

        let rawdata = fs.readFileSync('./zokrates/range.zok');

        const source = rawdata.toString();

        const artifacts = zokratesProvider.compile(source);

        const { witness, output } = zokratesProvider.computeWitness(artifacts, [input_1, input_2]);

        const keypair = zokratesProvider.setup(artifacts.program);

        const proof = zokratesProvider.generateProof(artifacts.program, witness, keypair.pk);
        const result = new Array(proof.proof.a, proof.proof.b, proof.proof.c);
        fse.outputFile("./proofs/proof_range.json", JSON.stringify(proof));
        console.log(chalk.green("\nProofs generated successfully"));
        return result;
        // const verifier = zokratesProvider.exportSolidityVerifier(keypair.vk, "v1");
        // fse.outputFile("./contracts/verifier_test.sol", verifier);
        // console.log(chalk.green("\nContracts generated successfully"));

    });
    
}

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
