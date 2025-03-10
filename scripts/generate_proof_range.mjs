import { initialize } from 'zokrates-js';
import chalk from "chalk"
import fs from "fs"
import path from "path"
import fse from 'fs-extra'
import promptSync from 'prompt-sync';

const prompt = promptSync();

initialize().then(async (zokratesProvider) => {

    let rawdata = fs.readFileSync('./zokrates/range.zok');

    const source = rawdata.toString();

    const artifacts = zokratesProvider.compile(source);

    const input_1 = prompt('input1 :');

    const input_2 = prompt('input2 :');

    const { witness, output } = zokratesProvider.computeWitness(artifacts, [input_1, input_2]);

    const keypair = zokratesProvider.setup(artifacts.program);

    const proof = zokratesProvider.generateProof(artifacts.program, witness, keypair.pk);
    fse.outputFile("./proofs/proof_range.json", JSON.stringify(proof));
    console.log(chalk.green("\nProofs generated successfully"));

    // const verifier = zokratesProvider.exportSolidityVerifier(keypair.vk, "v1");
    // fse.outputFile("./contracts/verifier_test.sol", verifier);
    // console.log(chalk.green("\nContracts generated successfully"));

});